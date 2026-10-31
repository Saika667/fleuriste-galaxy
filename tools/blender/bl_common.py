"""Helpers Blender partages par les scripts de personnages (lancer via tools/blender/run.ps1).

Conventions (voir docs/blender.md) :
- On ecrit toutes les positions en coordonnees Godot (Y haut, visage vers +Z) ; G() les convertit en Blender.
- Un pivot = un Empty nomme (Leg_0, Arm_1, Head...) dont l'origine est l'articulation ; les meshes sont ses enfants.
- Le NOM DU MATERIAU est le role de couleur (skin, top, bottom, hair, shoe, ink...) : Godot le recolore par role.
- Propriete perso "no_outline" = vrai -> exportee en extras glTF -> meta Godot (meme contrat que MeshKit).

Outils de modelisation :
- sweep()  : tube a section elliptique le long d'une courbe, rayon variable, bouts arrondis/plats/ouverts, modulation angulaire.
- lathe()  : surface de revolution autour de Y a partir d'un profil (rayon, hauteur) : chapeaux, jupes, boutons.
- blob()   : ellipsoide deformable (tete, joues...) avec filtre de sommets (cuir chevelu).
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Euler, Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

_MATS = {}
SEG_SCALE = 1.0  # facteur global sur le nombre de segments des sections (budget triangles)


def G(x, y, z):
    """Coordonnees Godot (x, y haut, z devant) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _MATS.clear()
    bpy.context.scene.unit_settings.system = "METRIC"


def reset_materials():
    """Oublie le cache des roles (plusieurs personnages dans une meme scene : chacun ses couleurs)."""
    _MATS.clear()


def hex_color(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))

    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return (lin(r), lin(g), lin(b), 1.0)


def material(role, color=None, rough=0.8, alpha=1.0, spec=0.25, sheen=0.0):
    """Un materiau par role ; le premier appel fixe la couleur par defaut."""
    if role in _MATS:
        return _MATS[role]
    m = bpy.data.materials.new(role)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = hex_color(color or "#FF00FF")
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Specular IOR Level"].default_value = spec
    if sheen > 0 and "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = sheen
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
    m.diffuse_color = hex_color(color or "#FF00FF")
    _MATS[role] = m
    return m


def pivot(name, loc, parent=None):
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "PLAIN_AXES"
    e.empty_display_size = 0.05
    bpy.context.scene.collection.objects.link(e)
    e.location = loc
    if parent is not None:
        _parent(e, parent)
    return e


def _parent(obj, parent):
    bpy.context.view_layer.update()
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()


def _finish(name, bm, loc, role, parent, rot=None, smooth=True, bevel=0.0, subsurf=0, thick=0.0, extras=None):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = loc
    if rot is not None:
        obj.rotation_euler = Euler(rot, "XYZ")
    obj.data.materials.append(_MATS[role])
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    if thick > 0:
        md = obj.modifiers.new("Solid", "SOLIDIFY")
        md.thickness = thick
        md.offset = -1
    if bevel > 0:
        md = obj.modifiers.new("Bevel", "BEVEL")
        md.width = bevel
        md.segments = 3
        md.limit_method = "ANGLE"
        md.angle_limit = math.radians(35)
    if subsurf:
        md = obj.modifiers.new("Subsurf", "SUBSURF")
        md.levels = subsurf
        md.render_levels = subsurf
    for k, v in (extras or {}).items():
        obj[k] = v
    if parent is not None:
        _parent(obj, parent)
    return obj


# ---------------------------------------------------------------- primitives simples

def sphere(name, r, loc, role, parent=None, scale=(1, 1, 1), seg=28, extras=None, subsurf=0, rot=None, exact=False):
    """Ellipsoide ; `scale` est donne en axes Godot (x, y, z). Les segments sont plafonnes selon la taille (budget triangles)."""
    if not exact:
        seg = max(10, min(seg, int(10 + r * 140)))
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=max(6, seg // 2), radius=r)
    sx, sy, sz = scale
    for v in bm.verts:
        v.co = Vector((v.co.x * sx, v.co.y * sz, v.co.z * sy))
    return _finish(name, bm, G(*loc), role, parent, extras=extras, subsurf=subsurf, rot=rot)


def capsule(name, r, h, loc, role, parent=None, seg=24):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=16, radius=r)
    half = max(0.0, h / 2.0 - r)
    for v in bm.verts:
        v.co.z += half if v.co.z > 0 else -half if v.co.z < 0 else 0.0
    return _finish(name, bm, G(*loc), role, parent)


def cylinder(name, r_top, r_bot, h, loc, role, parent=None, seg=32, bevel=0.012, rot=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r_bot, radius2=r_top, depth=h)
    return _finish(name, bm, G(*loc), role, parent, rot=rot, bevel=bevel)


def box(name, size, loc, role, parent=None, bevel=0.01, rot=None, extras=None, subsurf=0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    sx, sy, sz = size
    for v in bm.verts:
        v.co = Vector((v.co.x * sx, v.co.y * sz, v.co.z * sy))
    return _finish(name, bm, G(*loc), role, parent, rot=rot, bevel=bevel, extras=extras, subsurf=subsurf)


# ---------------------------------------------------------------- modelisation avancee

def _superellipse(c, s, sq):
    if sq == 2.0:
        return c, s
    e = 2.0 / sq
    return math.copysign(abs(c) ** e, c), math.copysign(abs(s) ** e, s)


def _build_rings(name, rings, role, parent, seg, sq, mod, cap0, cap1, subsurf, thick, extras, smooth=True,
                 apex0=None, apex1=None):
    """rings : liste de dict(c=Vector godot, N, B, a, b, t). Les caps 'round' ajoutent des anneaux, 'flat' un eventail."""
    bm = bmesh.new()
    rows = []
    for rg in rings:
        row = []
        for j in range(seg):
            th = 2 * math.pi * j / seg
            c, s = _superellipse(math.cos(th), math.sin(th), sq)
            f, dy = 1.0, 0.0
            if mod is not None:
                m = mod(th, rg["t"])
                if isinstance(m, tuple):
                    f, dy = m
                else:
                    f = m
            p = rg["c"] + rg["N"] * (rg["a"] * c * f) + rg["B"] * (rg["b"] * s * f) + Vector((0, dy, 0))
            row.append(bm.verts.new(G(p.x, p.y, p.z)))
        rows.append(row)

    def apex(pt):
        return bm.verts.new(G(pt.x, pt.y, pt.z))

    for i in range(len(rows) - 1):
        for j in range(seg):
            k = (j + 1) % seg
            bm.faces.new((rows[i][j], rows[i][k], rows[i + 1][k], rows[i + 1][j]))
    if cap0 == "flat" or apex0 is not None:
        ap = apex(apex0 if apex0 is not None else rings[0]["c"])
        for j in range(seg):
            bm.faces.new((rows[0][(j + 1) % seg], rows[0][j], ap))
    if cap1 == "flat" or apex1 is not None:
        ap = apex(apex1 if apex1 is not None else rings[-1]["c"])
        for j in range(seg):
            bm.faces.new((rows[-1][j], rows[-1][(j + 1) % seg], ap))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # l'origine de l'objet = pivot du parent (noeuds propres dans le glb, le chargeur peut deplacer/mettre a l'echelle)
    shift = Vector((0, 0, 0))
    if parent is not None:
        bpy.context.view_layer.update()
        shift = parent.matrix_world.translation.copy()
        bmesh.ops.translate(bm, vec=-shift, verts=bm.verts)
    return _finish(name, bm, shift, role, parent, smooth=smooth, subsurf=subsurf, thick=thick, extras=extras)


def _frames(P, ref):
    n = len(P)
    T = []
    for i in range(n):
        a = P[max(0, i - 1)]
        b = P[min(n - 1, i + 1)]
        d = (b - a)
        T.append(d.normalized() if d.length > 1e-9 else Vector((0, 1, 0)))
    ref = Vector(ref).normalized()
    N = ref - ref.dot(T[0]) * T[0]
    if N.length < 1e-4:
        N = Vector((0, 0, 1)) - Vector((0, 0, 1)).dot(T[0]) * T[0]
    N.normalize()
    out = []
    for i in range(n):
        if i > 0:
            N = N - N.dot(T[i]) * T[i]
            N.normalize()
        out.append((T[i], N.copy(), T[i].cross(N)))
    return out


def _catmull(vals, sub):
    """Catmull-Rom uniforme : insere `sub` points entre chaque paire de valeurs (liste de Vector)."""
    n = len(vals)
    if n < 3 or sub <= 0:
        return list(vals)
    out = []
    for i in range(n - 1):
        p1, p2 = vals[i], vals[i + 1]
        p0 = vals[i - 1] if i > 0 else 2 * p1 - p2
        p3 = vals[i + 2] if i + 2 < n else 2 * p2 - p1
        for k in range(sub + 1):
            t = k / (sub + 1)
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(vals[-1])
    return out


def sweep(name, pts, radii, role, parent=None, seg=24, ref=(1, 0, 0), cap0="round", cap1="round", cap_len=1.0,
          sq=2.0, mod=None, subsurf=0, thick=0.0, extras=None, cap_rings=2, sub=1):
    """Tube le long de `pts` (coordonnees Godot). radii : float ou (a, b) par point ; a suit `ref`, b est perpendiculaire.
    cap0/cap1 : 'round' (bout arrondi), 'flat' (bouche), 'open' (ouvert, ajouter thick pour l'epaisseur).
    sub : points inseres par spline Catmull-Rom entre deux points de controle (lisse sans subdivision)."""
    P = [Vector(p) for p in pts]
    R = [(r, r) if isinstance(r, (int, float)) else r for r in radii]
    if sub > 0 and len(P) >= 3:
        P = _catmull(P, sub)
        R = [(v.x, v.y) for v in _catmull([Vector((a, b, 0)) for a, b in R], sub)]
    seg = max(8, int(round(seg * SEG_SCALE)))
    fr = _frames(P, ref)
    n = len(P)
    rings = []
    apex0 = apex1 = None
    angles = [math.radians(a) for a in (30, 58, 78)][:cap_rings] if cap_rings == 3 else \
        [math.radians(90.0 * (k + 1) / (cap_rings + 1)) for k in range(cap_rings)]
    if cap0 == "round":
        T, N, B = fr[0]
        a0, b0 = R[0]
        rm = (a0 + b0) / 2 * cap_len
        apex0 = P[0] - T * rm
        for ang in reversed(angles):
            rings.append(dict(c=P[0] - T * (rm * math.sin(ang)), N=N, B=B, a=a0 * math.cos(ang), b=b0 * math.cos(ang), t=0.0))
    for i in range(n):
        T, N, B = fr[i]
        rings.append(dict(c=P[i], N=N, B=B, a=R[i][0], b=R[i][1], t=i / max(1, n - 1)))
    if cap1 == "round":
        T, N, B = fr[-1]
        a1, b1 = R[-1]
        rm = (a1 + b1) / 2 * cap_len
        apex1 = P[-1] + T * rm
        for ang in angles:
            rings.append(dict(c=P[-1] + T * (rm * math.sin(ang)), N=N, B=B, a=a1 * math.cos(ang), b=b1 * math.cos(ang), t=1.0))
    return _build_rings(name, rings, role, parent, seg, sq, mod, cap0, cap1, subsurf, thick, extras,
                        apex0=apex0, apex1=apex1)


def lathe(name, profile, role, parent=None, loc=(0, 0, 0), seg=40, mod=None, subsurf=1, thick=0.0, extras=None,
          closed_top=True, closed_bottom=False, smooth=0):
    """Revolution autour de Y. profile : liste de (rayon, hauteur) ; un rayon 0 ferme proprement le sommet.
    smooth : points inseres par spline entre deux points du profil (pour les formes sans arete vive : jupes)."""
    rings = []
    apex0 = apex1 = None
    profile = list(profile)
    if smooth > 0 and len(profile) >= 3:
        profile = [(v.x, v.y) for v in _catmull([Vector((r, y, 0)) for r, y in profile], smooth)]
    if profile[0][0] == 0:
        apex0 = Vector((loc[0], loc[1] + profile[0][1], loc[2]))
        profile = profile[1:]
    if profile[-1][0] == 0:
        apex1 = Vector((loc[0], loc[1] + profile[-1][1], loc[2]))
        profile = profile[:-1]
    for i, (r, y) in enumerate(profile):
        rings.append(dict(c=Vector((loc[0], loc[1] + y, loc[2])), N=Vector((1, 0, 0)), B=Vector((0, 0, 1)), a=r, b=r,
                          t=i / max(1, len(profile) - 1)))
    return _build_rings(name, rings, role, parent, seg, 2.0, mod,
                        "flat" if (closed_top and apex0 is None) else "open",
                        "flat" if (closed_bottom and apex1 is None) else "open", subsurf, thick, extras,
                        apex0=apex0, apex1=apex1)


def blob(name, r, loc, role, parent=None, scale=(1, 1, 1), seg=40, deform=None, keep=None, subsurf=0, thick=0.0,
         extras=None):
    """Ellipsoide (poles sur Y godot). deform(x,y,z)->(x,y,z) et keep(x,y,z)->bool travaillent en coordonnees godot locales."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=max(8, seg // 2), radius=r)
    sx, sy, sz = scale
    for v in bm.verts:
        gx, gy, gz = v.co.x * sx, v.co.z * sy, -v.co.y * sz
        if deform is not None:
            gx, gy, gz = deform(gx, gy, gz)
        v.co = Vector((gx, -gz, gy))
    if keep is not None:
        dead = [v for v in bm.verts if not keep(v.co.x, v.co.z, -v.co.y)]
        bmesh.ops.delete(bm, geom=dead, context="VERTS")
    return _finish(name, bm, G(*loc), role, parent, subsurf=subsurf, thick=thick, extras=extras)


def dome(name, R, ymin_fn, loc, role, parent=None, scale=(1, 1, 1), rings=16, seg=72, deform=None, subsurf=1, thick=0.0,
         extras=None):
    """Calotte spherique (coiffe) dont le bord inferieur suit ymin_fn(psi) : psi = azimut depuis +Z (-pi..pi).
    Bord lisse (pas d'escalier) ; deform(x,y,z) comme pour blob()."""
    sx, sy, sz = scale
    top = R * sy
    bm = bmesh.new()

    def pt(psi, s):
        ymin = ymin_fn(psi)
        y = top - s * (top - ymin)
        yy = y / sy
        rho = math.sqrt(max(0.0, R * R - yy * yy))
        x, z = rho * math.sin(psi) * sx, rho * math.cos(psi) * sz
        if deform is not None:
            x, y, z = deform(x, y, z)
        return bm.verts.new(G(x, y, z))

    rows = []
    for i in range(rings):
        s = (i + 1) / rings
        s = 0.05 + 0.95 * s
        rows.append([pt(-math.pi + 2 * math.pi * j / seg, s) for j in range(seg)])
    ap_xyz = deform(0.0, top, 0.0) if deform is not None else (0.0, top, 0.0)
    ap = bm.verts.new(G(*ap_xyz))
    for i in range(rings - 1):
        for j in range(seg):
            k = (j + 1) % seg
            bm.faces.new((rows[i][j], rows[i][k], rows[i + 1][k], rows[i + 1][j]))
    for j in range(seg):
        bm.faces.new((rows[0][(j + 1) % seg], rows[0][j], ap))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _finish(name, bm, G(*loc), role, parent, subsurf=subsurf, thick=thick, extras=extras)


def mirror_x(pt):
    return (-pt[0], pt[1], pt[2])


# ---------------------------------------------------------------- AO sommet (stylise, cuit dans COLOR_0)

def bake_vertex_ao(objs, occluders=None, samples=20, dist=0.12, strength=0.55, floor=0.45):
    """Cuit un AO sommet (gris) dans la couche de couleur 'Col' de chaque objet (modificateurs appliques).
    glTF multiplie COLOR_0 par la couleur de base : le jeu garde la recoloration par role et gagne du volume."""
    deps = bpy.context.evaluated_depsgraph_get()
    deps.update()
    occ_objs = occluders if occluders is not None else objs
    bm_all = bmesh.new()
    for o in occ_objs:
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        bm_all_tmp = bmesh.new()
        bm_all_tmp.from_mesh(me)
        bm_all_tmp.transform(o.matrix_world)
        me2 = bpy.data.meshes.new("tmp")
        bm_all_tmp.to_mesh(me2)
        bm_all_tmp.free()
        bm_all.from_mesh(me2)
        bpy.data.meshes.remove(me2)
        ev.to_mesh_clear()
    tree = BVHTree.FromBMesh(bm_all)
    bm_all.free()
    rng = __import__("random").Random(7)
    dirs = []
    for _ in range(samples):  # hemisphere cos-ponderee (z+)
        u, v = rng.random(), rng.random()
        r = math.sqrt(u)
        ph = 2 * math.pi * v
        dirs.append(Vector((r * math.cos(ph), r * math.sin(ph), math.sqrt(max(0.0, 1 - u)))))
    for o in objs:
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        mw = o.matrix_world
        nm = mw.to_3x3().inverted().transposed()
        cols = []
        for v in me.vertices:
            p = mw @ v.co
            n = (nm @ v.normal).normalized()
            t1 = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))).normalized()
            t2 = n.cross(t1)
            hit = 0.0
            for d in dirs:
                w = t1 * d.x + t2 * d.y + n * d.z
                loc, nor, idx, dd = tree.ray_cast(p + n * 0.004, w, dist)
                if loc is not None:
                    hit += 1.0 - dd / dist
            ao = 1.0 - strength * hit / samples
            cols.append(max(floor, ao))
        ev.to_mesh_clear()
        base = o.data
        if "Col" in base.color_attributes:
            base.color_attributes.remove(base.color_attributes["Col"])
        # les couleurs vivent sur le maillage de base : on echantillonne sur les sommets evalues -> on applique les modificateurs
        _bake_into_base(o, cols, deps)


def _bake_into_base(o, cols, deps):
    """Applique les modificateurs a l'objet pour que les sommets correspondent aux couleurs calculees."""
    ev = o.evaluated_get(deps)
    me_new = bpy.data.meshes.new_from_object(ev)
    old = o.data
    o.modifiers.clear()
    o.data = me_new
    me_new.materials.clear()
    for m in old.materials:
        me_new.materials.append(m)
    bpy.data.meshes.remove(old)
    attr = me_new.color_attributes.new("Col", "BYTE_COLOR", "POINT")
    for i, v in enumerate(me_new.vertices):
        c = cols[i] if i < len(cols) else 1.0
        attr.data[i].color = (c, c, c, 1.0)
    for p in me_new.polygons:
        p.use_smooth = True


def preview_use_vertex_color(name="Col"):
    """Apercu : multiplie la couleur de base par la couche `name`, comme Godot avec COLOR_0 du glb."""
    for m in bpy.data.materials:
        if not m.use_nodes or "Principled BSDF" not in m.node_tree.nodes:
            continue
        nt = m.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        base = bsdf.inputs["Base Color"].default_value[:]
        att = nt.nodes.new("ShaderNodeVertexColor")
        att.layer_name = name
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        mix.inputs[6].default_value = base
        nt.links.new(att.outputs["Color"], mix.inputs[7])
        nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])


def preview_toon(width=0.0055, color="#0B0B10", min_size=0.035, cel=0.0, shade=(0.80, 0.74, 0.86)):
    """Apercu 'dessin anime' : chaque role devient un aplat (cel > 0 : deux tons, ombre dure teintee `shade`),
    et chaque piece recoit un contour noir uniforme (coque inversee). Le glb reste inchange."""
    flat_cols = {}
    for m in bpy.data.materials:
        if m.use_nodes and "Principled BSDF" in m.node_tree.nodes:
            flat_cols[m.name] = m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value[:]
    for m in list(bpy.data.materials):
        if m.name not in flat_cols:
            continue
        nt = m.node_tree
        nt.nodes.clear()
        base = flat_cols[m.name]
        em = nt.nodes.new("ShaderNodeEmission")
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
        if cel <= 0:
            em.inputs["Color"].default_value = base
            continue
        dif = nt.nodes.new("ShaderNodeBsdfDiffuse")
        s2r = nt.nodes.new("ShaderNodeShaderToRGB")
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.interpolation = "CONSTANT"
        ramp.color_ramp.elements[0].position = 0.0
        ramp.color_ramp.elements[0].color = (0, 0, 0, 1)
        ramp.color_ramp.elements[1].position = cel
        ramp.color_ramp.elements[1].color = (1, 1, 1, 1)
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.inputs[6].default_value = (base[0] * shade[0], base[1] * shade[1], base[2] * shade[2], 1.0)
        mix.inputs[7].default_value = base
        nt.links.new(dif.outputs["BSDF"], s2r.inputs["Shader"])
        nt.links.new(s2r.outputs["Color"], ramp.inputs["Fac"])
        nt.links.new(ramp.outputs["Color"], mix.inputs[0])
        nt.links.new(mix.outputs[2], em.inputs["Color"])
    om = bpy.data.materials.new("OUTLINE")
    om.use_nodes = True
    nt = om.node_tree
    nt.nodes.clear()
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = hex_color(color)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    om.use_backface_culling = True
    for o in list(bpy.data.objects):
        if o.type != "MESH" or o.hide_render or o.name == "PreviewFloor":
            continue
        d = max(o.dimensions)
        if d < min_size or o.get("no_outline"):
            continue
        o.data.materials.append(om)
        md = o.modifiers.new("Outline", "SOLIDIFY")
        md.thickness = width
        md.offset = 1.0
        md.use_flip_normals = True
        md.material_offset = len(o.data.materials) - 1
        md.use_rim = False


def export_glb(path, root_obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    root_obj.select_set(True)
    for o in root_obj.children_recursive:
        o.select_set(True)
    kw = dict(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_extras=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    try:
        bpy.ops.export_scene.gltf(export_vertex_color="ACTIVE", **kw)
    except TypeError:
        bpy.ops.export_scene.gltf(**kw)


def render_preview(path_prefix, views=None, res=(900, 1250), focus=(0, 1.0, 0), dist=7.0, lens=70, floor=True, bg="#F6E6CB",
                   key_only=False):
    """Rend des vues (PNG) de la scene courante. views : nom -> dict(yaw, focus, dist)."""
    sc = bpy.context.scene
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "BLENDER_WORKBENCH"):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            continue
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    try:
        sc.eevee.use_shadows = True
        sc.eevee.taa_render_samples = 64
    except Exception:
        pass
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = hex_color(bg)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.95
    sc.world = world
    try:
        sc.eevee.use_raytracing = True
    except Exception:
        pass

    def sun(name, energy, rx, rz, col, size=0.35):
        L = bpy.data.lights.new(name, "SUN")
        L.energy = energy
        L.angle = size
        L.color = col
        o = bpy.data.objects.new(name, L)
        o.rotation_euler = Euler((math.radians(rx), 0, math.radians(rz)), "XYZ")
        sc.collection.objects.link(o)

    sun("Key", 4.6, 50, -40, (1.0, 0.92, 0.8))
    if not key_only:
        sun("Fill", 0.7, 70, 140, (0.8, 0.86, 1.0), 0.7)
        sun("Rim", 2.4, 118, 205, (1.0, 0.9, 0.95), 0.2)
    if floor:
        bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
        fl = bpy.context.active_object
        fl.name = "PreviewFloor"
        fm = bpy.data.materials.new("PreviewFloor")
        fm.use_nodes = True
        fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = hex_color("#EBD3AE")
        fm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
        fl.data.materials.append(fm)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = lens
    cam.data.clip_end = 100
    sc.collection.objects.link(cam)
    sc.camera = cam
    views = views or {"front": dict(yaw=0), "three_quarter": dict(yaw=35), "side": dict(yaw=90), "back": dict(yaw=180)}
    for vname, v in views.items():
        f = G(*v.get("focus", focus))
        d = v.get("dist", dist)
        a = math.radians(v.get("yaw", 0))
        el = math.radians(v.get("elev", 4))
        cam.location = f + Vector((math.sin(a) * d * math.cos(el), -math.cos(a) * d * math.cos(el), math.sin(el) * d))
        cam.rotation_euler = (f - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = f"{path_prefix}_{vname}.png"
        bpy.ops.render.render(write_still=True)


def script_args():
    """Arguments apres le `--` de la ligne de commande Blender."""
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
