"""Generateur de personnages style « Rick et Morty » a partir d'une fiche (dict). Utilise par characters/rm_cast.py.

Chaque personnage respecte le contrat du jeu (noms de pieces/pivots de CustomerActor) : Rig > Torso, Leg_0/1, Arm_0/1, Head >
Eye_0/1, Brow_0/1, Mouth > Mouth_seg_0..4, Mouth_open (+ Mouth_teeth, Mouth_tongue), Blush_0/1. Nom de materiau = role de couleur.
Coordonnees Godot (Y haut, visage vers +Z), metres.

Codes graphiques de la serie repris ici : tete ovale/ronde selon le perso, gros yeux globuleux qui se touchent, pupille-point,
paupiere lourde avec son trait, cernes/rides/plis en traits fins, nez en bosse ou long et tombant, bouche fine ou ouverte en D
avec les dents du haut, cou mince, bras longs a coude, mains a 4 doigts, cheveux en masses a pointes, aplats + trait noir.
"""
import math

import bmesh
import bpy
from mathutils import Vector

import bl_common as bc
from bl_common import G, box, lathe, sphere, sweep

NO_OUTLINE = {"no_outline": True}
MOUTH_S = 0.55

DEFAULT = dict(
    height=1.72, head=(0.128, 0.165, 0.135), jaw=0.30, chin=0.012, neck_len=0.1, neck_r=0.034, leg_frac=0.69,
    shoulder=0.135, chest=(0.125, 0.085), waist=(0.1, 0.07), hips=(0.115, 0.08), belly=0.0, leg_r=0.055, arm_r=0.03,
    hunch=0.0,
    skin="#F7DCC4", top="#4FA3C7", top_light="#A9D8EA", bottom="#3D4F7A", shoe="#7A4A36", sole="#3B2620", hair="#B8562F",
    brow_col=None, accent="#F6E3A1", collar="#FFF8EC",
    top_type="tee", sleeves="short", bottom_type="pants", skirt_len=0.42, shoe_type="shoe",
    eye_r=None, eye_sep=None, eye_y=None, pupil=(0.0, -0.006), lids="none", lid_cut=0.25, bags=0, lashes=False,
    brows="thin", nose="bump", nose_s=1.0, mouth_y=None, smile_lines=False, wrinkles=0, mustache=False, beard=False,
    glasses=False, earrings=False, piercing=False, hair_type="bob", apron=False, print_col=None, tie_col=None,
    mood="neutral",
)


class Char:
    def __init__(self, spec):
        s = dict(DEFAULT)
        s.update(spec)
        self.s = s
        self.hx, self.hy, self.hz = s["head"]
        self.head_y = s["height"] - self.hy
        self.chin_y = self.head_y - self.hy * 0.95
        self.sho_y = self.chin_y - s["neck_len"]
        self.hip_y = self.sho_y * s["leg_frac"]

    # ---------------------------------------------------------------- outils tete
    def jaw(self, x, y, z):
        if y < 0:
            t = min(1.0, -y / self.hy)
            x *= 1 - self.s["jaw"] * t ** 1.4
            z *= 1 - 0.10 * t
            if z > 0:
                z += self.s["chin"] * t * t
        return x, y, z

    def surf_z(self, x, y):
        hx, hy, hz = self.hx, self.hy, self.hz
        xs = x
        if y < 0:
            t = min(1.0, -y / hy)
            xs = x / (1 - self.s["jaw"] * t ** 1.4)
        z = hz * math.sqrt(max(0.0, 1 - (xs / hx) ** 2 - (y / hy) ** 2))
        if y < 0:
            t = min(1.0, -y / hy)
            z = z * (1 - 0.10 * t) + self.s["chin"] * t * t
        return z

    def H(self, x, y, z):
        return (x, self.head_y + y, z)

    def line_on_face(self, name, pts2d, r, parent, lift=0.0025, role="ink"):
        """Trait fin pose sur le visage : pts2d en (x, y) relatifs au centre de la tete."""
        pts = [self.H(x, y, self.surf_z(x, y) + lift) for x, y in pts2d]
        rr = []
        n = len(pts)
        for k in range(n):
            u = k / max(1, n - 1)
            rr.append((r * (0.55 + 0.45 * math.sin(math.pi * u)),) * 2)
        sweep(name, pts, rr, role, parent, seg=6, sub=1, extras=NO_OUTLINE)

    # ---------------------------------------------------------------- construction
    def build(self):
        s = self.s
        bc.reset_materials()
        for role, col in [
            ("skin", s["skin"]), ("top", s["top"]), ("top_light", s["top_light"]), ("bottom", s["bottom"]), ("shoe", s["shoe"]),
            ("sole", s["sole"]), ("hair", s["hair"]), ("brow", s["brow_col"] or s["hair"]), ("accent", s["accent"]),
            ("collar", s["collar"]), ("ink", "#14121A"), ("eye_white", "#FFFFFF"), ("iris", "#14121A"), ("mouth", "#2A1620"),
            ("mouth_in", "#5B1E2A"), ("teeth", "#FFFFFF"), ("tongue", "#E8788A"), ("blush", "#F09A8E"), ("apron", "#FAFAF5"),
            ("glasses", "#14121A"), ("lens", "#DDEEF5"), ("gold", "#E8C547"), ("print", s["print_col"] or s["accent"]),
            ("tie", s["tie_col"] or "#C8423B"),
        ]:
            bc.material(role, col, 0.9, spec=0.0)
        self.rig = bc.pivot("Rig", (0, 0, 0))
        self.torso = bc.pivot("Torso", (0, 0, 0), self.rig)
        self._legs()
        self._torso()
        self._arms()
        self._head()
        self._hair()
        return self.rig

    # ---------------------------------------------------------------- jambes
    def _legs(self):
        s = self.s
        hip, lr = self.hip_y, s["leg_r"]
        bt = s["bottom_type"]
        for i, sx in enumerate((-1, 1)):
            x = sx * (s["hips"][0] * 0.55 + s["belly"] * 0.2)
            leg = bc.pivot(f"Leg_{i}", G(x, hip, 0), self.rig)
            ys = [hip - 0.02, hip * 0.8, hip * 0.56, hip * 0.36, 0.085]
            rad = [lr, lr * 0.9, lr * 0.72, lr * 0.76, lr * 0.52]
            pts = [(x, ys[0], 0), (x, ys[1], 0.004), (x * 0.96, ys[2], 0.008), (x * 0.94, ys[3], -0.004), (x * 0.93, ys[4], 0)]
            role = "bottom" if bt in ("pants",) else "skin"
            sweep(f"Leg_{i}_limb", pts, [(r, r * 0.97) for r in rad], role, leg, cap0="round", cap1="round", seg=16)
            if bt == "shorts":
                sweep(f"Leg_{i}_shorts", [(x, hip - 0.0, 0), (x * 1.02, hip * 0.74, 0.004)], [(lr * 1.22, lr * 1.2), (lr * 1.2, lr * 1.16)],
                      "bottom", leg, cap0="round", cap1="open", thick=0.006, seg=16)
            xs = x * 0.93
            fl = 0.17 * s["height"] / 1.72
            st = s["shoe_type"]
            sw_ = 1.15 if st == "sneaker" else 1.0
            sweep(f"Leg_{i}_shoe", [(xs, 0.05, -0.04), (xs, 0.048, fl * 0.12), (xs, 0.042, fl * 0.47), (xs, 0.036, fl * 0.74)],
                  [(0.036 * sw_, 0.042), (0.04 * sw_, 0.04), (0.043 * sw_, 0.032), (0.035 * sw_, 0.026)], "shoe", leg, cap0="round",
                  cap1="round", cap_len=0.9, seg=16)
            sweep(f"Leg_{i}_sole", [(xs, 0.012, -0.042), (xs, 0.012, fl * 0.3), (xs, 0.012, fl * 0.76)],
                  [(0.039 * sw_, 0.013), (0.044 * sw_, 0.013), (0.037 * sw_, 0.012)], "sole", leg, cap0="round", cap1="round",
                  cap_len=0.9, seg=14)
            if st == "boot":
                sweep(f"Leg_{i}_boot", [(xs, 0.05, 0.0), (x * 0.94, 0.3, -0.004)], [(lr * 0.68, lr * 0.68), (lr * 0.86, lr * 0.84)],
                      "shoe", leg, cap0="round", cap1="open", thick=0.006, seg=16)

    # ---------------------------------------------------------------- torse
    def _shape(self, y_top, y_bot, extra=0.0, n_end=None):
        """Points/rayons du buste entre y_top et y_bot (bornes incluses), suivant la morphologie."""
        s = self.s
        sho, hip, b = self.sho_y, self.hip_y, s["belly"]
        prof = [  # (y, a, b, dz)
            (sho + 0.03, 0.058, 0.05, -0.004),
            (sho - 0.012, s["shoulder"] - 0.005, s["chest"][1] * 0.85, s["hunch"] * 0.5),
            (sho - 0.1, s["chest"][0], s["chest"][1], s["hunch"] * 0.3),
            ((sho + hip) / 2, s["waist"][0] + b, s["waist"][1] + b * 1.5, b * 0.8),
            (hip + 0.03, s["hips"][0] + b * 0.6, s["hips"][1] + b * 0.8, b * 0.3),
            (hip - 0.06, s["hips"][0] * 0.98, s["hips"][1] * 0.98, 0.0),
        ]

        def at(y):
            for k in range(len(prof) - 1):
                y0, a0, b0, z0 = prof[k]
                y1, a1, b1, z1 = prof[k + 1]
                if y0 >= y >= y1:
                    t = (y0 - y) / (y0 - y1)
                    return a0 + (a1 - a0) * t, b0 + (b1 - b0) * t, z0 + (z1 - z0) * t
            y0, a0, b0, z0 = prof[-1] if y < prof[-1][0] else prof[0]
            return a0, b0, z0

        ys = [y for y, _, _, _ in prof if y_bot < y < y_top]
        ys = [y_top] + ys + [y_bot]
        pts, rad = [], []
        for y in ys:
            a, bb, dz = at(y)
            pts.append((0, y, dz))
            rad.append((a + extra, bb + extra))
        return pts, rad

    def _torso(self):
        s = self.s
        sho, hip = self.sho_y, self.hip_y
        tt = s["top_type"]
        T = self.torso
        hem = {"labcoat": hip * 0.55, "suit": hip - 0.04, "dress": (sho + hip) / 2 - 0.02}.get(tt, hip + 0.0)
        # pantalon / bas du corps
        if s["bottom_type"] in ("pants", "shorts"):
            p, r = self._shape(hip + 0.06, hip - 0.06, extra=-0.002)
            sweep("Torso_pants", p, r, "bottom", T, cap0="flat", cap1="flat", seg=22, sq=2.3)
        elif s["bottom_type"] == "skirt" or tt == "dress":
            y0 = (sho + hip) / 2 - 0.02 if tt == "dress" else hip + 0.05
            wa = s["waist"][0] + s["belly"]
            y1 = y0 - s["skirt_len"]
            prof = [(0.0, y0), (wa, y0), (wa * 1.12, y0 - 0.06), (wa * 1.45, y0 - s["skirt_len"] * 0.5), (wa * 1.85, y1)]
            lathe("Torso_skirt", prof, "top" if tt == "dress" else "bottom", T, seg=32, smooth=1, subsurf=0, thick=0.008,
                  mod=lambda th, t: (1.0 - 0.2 * (1 - math.cos(2 * th)) / 2 * (1 - t * 0.3), 0.0), closed_top=True)
        # haut
        flare = 0.05 if tt == "labcoat" else 0.0
        p, r = self._shape(sho + 0.03, max(hem, hip - 0.06), extra=0.004)
        if tt == "labcoat":
            p.append((0, hem, 0.0))
            r.append((s["hips"][0] + 0.06 + s["belly"] * 0.6, s["hips"][1] + 0.05 + s["belly"] * 0.8))
            p = [pt for pt in p if pt[1] >= hem - 1e-6]
            r = r[-len(p):] if len(r) > len(p) else r
        sweep("Torso_top", p, r, "top", T, cap0="flat", cap1="open" if tt == "labcoat" else "flat", thick=0.008 if tt == "labcoat" else 0.0,
              seg=24, sq=2.3)
        ny = sho + 0.03
        if tt in ("tee", "sweater", "tank", "dress"):
            rr = 0.068 if tt != "tank" else 0.085
            sweep("Detail_neck", [(0, ny + 0.004, -0.004), (0, ny - 0.012, 0.0)], [(rr - 0.01, rr - 0.018), (rr, rr - 0.01)],
                  "top_light", T, cap0="open", cap1="open", thick=0.006, seg=22)
        if tt in ("polo", "shirt", "blouse", "suit"):
            col = "collar" if tt == "suit" else "top_light"
            for sx in (-1, 1):
                sweep(f"Detail_collar_{sx}", [(sx * 0.035, ny + 0.012, -0.03), (sx * 0.055, ny, 0.025), (sx * 0.022, ny - 0.035, 0.066)],
                      [(0.006, 0.022), (0.007, 0.028), (0.005, 0.012)], col, T, ref=(0, 0, 1), seg=10, cap_len=0.5)
        if tt in ("suit", "labcoat"):
            for sx in (-1, 1):
                z0 = s["chest"][1] + 0.006
                sweep(f"Detail_lapel_{sx}", [(sx * 0.03, ny - 0.01, z0 - 0.02), (sx * 0.075, sho - 0.1, z0 + 0.004),
                                             (sx * 0.05, sho - 0.2, z0 + 0.006 + s["belly"])],
                      [(0.006, 0.026), (0.007, 0.034), (0.005, 0.016)], "top_light" if tt == "labcoat" else "top", T, ref=(0, 0, 1), seg=10,
                      cap_len=0.6)
        if tt in ("suit", "shirt") and s["tie_col"]:
            z0 = s["chest"][1] + 0.008
            sweep("Detail_tie", [(0, ny - 0.03, z0 - 0.006), (0, sho - 0.12, z0 + 0.006), (0, sho - 0.22, z0 + 0.008 + s["belly"] * 0.9)],
                  [(0.004, 0.014), (0.005, 0.02), (0.004, 0.012)], "tie", T, ref=(0, 0, 1), seg=8, cap_len=0.5)
        if tt == "sweater":
            p2, r2 = self._shape(hip + 0.04, hip + 0.0, extra=0.008)
            sweep("Detail_hem", p2, r2, "top_light", T, cap0="open", cap1="open", thick=0.006, seg=22, sq=2.3)
        if tt == "cardigan":
            for k in range(4):
                y = sho - 0.06 - k * (sho - hip) / 4.5
                z = self._shape(y + 0.001, y - 0.001)[1][0][1] + 0.006
                sphere(f"Detail_button_{k}", 0.008, (0, y, z + s["belly"] * (0.5 if k > 1 else 0.2)), "accent", T, seg=10)
        if tt == "labcoat":
            for sx in (-1, 1):
                box(f"Detail_pocket_{sx}", (0.06, 0.05, 0.008), (sx * 0.085, hip - 0.02, s["hips"][1] + 0.05), "top_light", T, bevel=0.004)
        if s["print_col"]:
            z = s["chest"][1] + 0.006
            sphere("Detail_print", 0.04, (0, sho - 0.1, z), "print", T, scale=(1, 1, 0.15), seg=16)
        if s["apron"]:
            zc = s["chest"][1] + 0.01 + s["belly"] * 0.6
            sweep("Detail_apron", [(0, sho - 0.07, s["chest"][1] + 0.006), (0, (sho + hip) / 2, zc + s["belly"] * 0.9), (0, hip * 0.62, zc)],
                  [(0.004, 0.09), (0.004, s["waist"][0] + s["belly"] + 0.01), (0.004, s["hips"][0] + 0.03)], "apron", T, ref=(0, 0, 1), seg=8,
                  cap_len=0.2, cap_rings=1)
        sweep("Neck", [(0, sho - 0.02, 0), (0, (sho + self.chin_y) / 2 + 0.03, 0.004), (0, self.chin_y + 0.06, 0.008)],
              [(s["neck_r"] * 1.05,) * 2, (s["neck_r"],) * 2, (s["neck_r"],) * 2], "skin", self.rig, cap0="round", cap1="round", seg=14)

    # ---------------------------------------------------------------- bras
    def _arms(self):
        s = self.s
        sho, hip, ar = self.sho_y, self.hip_y, s["arm_r"]
        sl = s["sleeves"]
        if s["top_type"] in ("suit", "labcoat", "shirt", "sweater", "cardigan"):
            sl = "long"
        if s["top_type"] == "tank":
            sl = "none"
        out = s["belly"] * 0.8
        for i, sx in enumerate((-1, 1)):
            x = sx * s["shoulder"]
            arm = bc.pivot(f"Arm_{i}", G(x, sho - 0.01, 0), self.rig)
            pts = [(x - sx * 0.005, sho - 0.005, 0), (x + sx * (0.015 + out * 0.5), (sho + hip) / 2 + 0.03, -0.006 + s["hunch"] * 0.3),
                   (x + sx * (0.045 + out), hip - 0.07, 0.02)]
            rad = [(ar * 1.05, ar), (ar * 0.86, ar * 0.84), (ar * 0.7, ar * 0.68)]
            sweep(f"Arm_{i}_limb", pts, rad, "skin", arm, cap0="round", cap1="round", seg=14)
            if sl in ("long", "short"):
                if sl == "long":
                    sp = pts[:2] + [(pts[2][0] - sx * 0.002, pts[2][1] + 0.03, pts[2][2] - 0.002)]
                    srad = [(ar * 1.6, ar * 1.55), (ar * 1.2, ar * 1.18), (ar * 1.05, ar * 1.03)]
                else:
                    sp = [pts[0], (x + sx * 0.006, sho - 0.07, 0.0), (x + sx * 0.012, sho - 0.13, 0.0)]
                    srad = [(ar * 1.6, ar * 1.55), (ar * 1.5, ar * 1.45), (ar * 1.42, ar * 1.38)]
                sweep(f"Arm_{i}_sleeve", sp, srad, "top", arm, cap0="round", cap1="open", thick=0.005, seg=16)
            # main 4 doigts
            hs = ar / 0.03
            hx, hy, hz = pts[2]
            hy -= 0.005
            sweep(f"Arm_{i}_hand", [(hx, hy, hz), (hx + sx * 0.002, hy - 0.035 * hs, hz + 0.004), (hx + sx * 0.003, hy - 0.065 * hs, hz + 0.006)],
                  [(0.026 * hs, 0.014 * hs), (0.03 * hs, 0.016 * hs), (0.028 * hs, 0.015 * hs)], "skin", arm, ref=(0, 0, 1), seg=12)
            fy = hy - 0.06 * hs
            for fi, fx in enumerate((-0.017, 0.0, 0.017)):
                fx *= hs
                sweep(f"Arm_{i}_finger_{fi}", [(hx + fx, fy, hz + 0.007), (hx + fx * 1.15, fy - 0.035 * hs, hz + 0.01),
                                               (hx + fx * 1.2, fy - 0.065 * hs, hz + 0.014)],
                      [(0.0082 * hs,) * 2, (0.0076 * hs,) * 2, (0.0068 * hs,) * 2], "skin", arm, seg=8)
            sweep(f"Arm_{i}_thumb", [(hx - sx * 0.022 * hs, hy - 0.025 * hs, hz + 0.008), (hx - sx * 0.036 * hs, hy - 0.05 * hs, hz + 0.016),
                                     (hx - sx * 0.04 * hs, hy - 0.075 * hs, hz + 0.022)],
                  [(0.0095 * hs,) * 2, (0.0085 * hs,) * 2, (0.0074 * hs,) * 2], "skin", arm, seg=8)

    # ---------------------------------------------------------------- tete
    def _head(self):
        s = self.s
        hx, hy, hz = self.hx, self.hy, self.hz
        H, sz = self.H, self.surf_z
        head = bc.pivot("Head", G(0, self.head_y, 0), self.rig)
        self.head = head
        bc.blob("Head_skull", 1.0, (0, self.head_y, 0), "skin", head, scale=(hx, hy, hz), deform=self.jaw, seg=40, subsurf=0)
        for sx in (-1, 1):
            ex_ = hx * 0.97
            sphere(f"Head_ear_{sx}", 0.032 * hy / 0.165, H(sx * ex_, -hy * 0.07, -0.01), "skin", head, scale=(0.36, 1.0, 0.72), seg=14)
            if s["earrings"]:
                sphere(f"Head_earring_{sx}", 0.009, H(sx * ex_, -hy * 0.07 - 0.04, 0.0), "gold", head, seg=10)

        er = s["eye_r"] or hx * 0.4
        esep = s["eye_sep"] or er * 0.84
        ey = s["eye_y"] if s["eye_y"] is not None else hy * 0.17
        rx, ry, rz = er, er * 1.2, 0.04
        mood = s["mood"]
        for i, sx in enumerate((-1, 1)):
            ex = sx * esep
            ez = sz(ex, ey) - 0.004
            eye = bc.pivot(f"Eye_{i}", G(*H(ex, ey, ez)), head)
            sphere(f"Eye_{i}_white", 1.0, H(ex, ey, ez), "eye_white", eye, scale=(rx, ry, rz), seg=28, exact=True)
            pdx, pdy = s["pupil"]
            px, py = ex - sx * 0.006 + pdx, ey + pdy
            pz = ez + rz * math.sqrt(max(0.0, 1 - ((px - ex) / rx) ** 2 - ((py - ey) / ry) ** 2)) + 0.0005
            sphere(f"Eye_{i}_pupil", 0.0072, H(px, py, pz), "iris", eye, scale=(1, 1, 0.4), seg=12, exact=True, extras=NO_OUTLINE)
            if s["lids"] != "none":
                # paupiere superieure : calotte de peau + son trait (regard blase, typique de la serie)
                cut = ry * (s["lid_cut"] if s["lids"] == "half" else 0.0)
                cap = sphere(f"Eye_{i}_lid", 1.0, H(ex, ey, ez), "skin", eye, scale=(rx * 1.05, ry * 1.05, rz * 1.18), seg=28, exact=True)
                me = cap.data
                bm = bmesh.new()
                bm.from_mesh(me)
                dead = [v for v in bm.verts if v.co.z < cut]
                bmesh.ops.delete(bm, geom=dead, context="VERTS")
                bm.to_mesh(me)
                bm.free()
                w = rx * 1.05 * math.sqrt(max(0.0, 1 - (cut / (ry * 1.05)) ** 2))
                lp = []
                for k in range(9):
                    xx = (-w + 2 * w * k / 8) * 0.9
                    zz = rz * 1.18 * math.sqrt(max(0.0, 1 - (xx / (rx * 1.05)) ** 2 - (cut / (ry * 1.05)) ** 2))
                    u = xx / w
                    lp.append(H(ex + xx, ey + cut + 0.008 * (1 - u * u) - 0.004 * (sx * u), ez + zz + 0.0015))
                sweep(f"Eye_{i}_lidline", lp, [(0.0032, 0.0032)] * len(lp), "ink", eye, seg=6, sub=0, extras=NO_OUTLINE)
            if s["lashes"]:
                for k, ang in enumerate((25, 45, 65)):
                    a = math.radians(ang)
                    bx0, by0 = ex + sx * rx * math.cos(a) * 0.98, ey + ry * math.sin(a) * 0.98
                    bz0 = ez + rz * 0.35
                    d = Vector((sx * math.cos(a), math.sin(a), 0.0)).normalized()
                    sweep(f"Eye_{i}_lash_{k}", [H(bx0, by0, bz0), H(bx0 + d.x * 0.012, by0 + d.y * 0.012 + 0.002, bz0 + 0.002),
                                                H(bx0 + d.x * 0.02, by0 + d.y * 0.02 + 0.006, bz0)],
                          [(0.0032,) * 2, (0.0024,) * 2, (0.0012,) * 2], "ink", eye, seg=6, sub=0, extras=NO_OUTLINE)
            for k in range(s["bags"]):  # cernes : arcs sous l'oeil
                off = 0.007 + k * 0.009
                arc = [(ex + sx * rx * (0.85 - k * 0.1) * math.cos(t), ey - ry * math.sin(t) - off)
                       for t in [math.radians(a) for a in (200, 230, 260, 290, 320)]]
                arc = [(ex + (ax - ex) * sx * sx, ay) for ax, ay in arc]
                self.line_on_face(f"Eye_{i}_bag_{k}", arc, 0.0026, eye)
            # sourcils
            bx, by = sx * esep * 1.05, ey + ry + 0.016
            brow = bc.pivot(f"Brow_{i}", G(*H(bx, by, sz(bx, by) + 0.004)), head)
            if s["brows"] in ("thin", "thick"):
                th = 0.0045 if s["brows"] == "thin" else 0.008
                bp = [(bx + sx * u * er * 0.62, by + 0.008 * (1 - u * u) + 0.003 * u) for u in (-1.0, -0.5, 0.0, 0.5, 1.0)]
                pts = [H(x, y, sz(x, y) + 0.004) for x, y in bp]
                sweep(f"Brow_{i}_bar", pts, [(th, th * 0.85), (th * 1.15, th), (th * 1.15, th), (th, th * 0.85), (th * 0.55, th * 0.5)], "brow",
                      brow, ref=(0, 1, 0), seg=8, extras=NO_OUTLINE)
            elif s["brows"] == "unibrow" and i == 0:
                bp = []
                for k in range(9):
                    u = -1 + 2 * k / 8
                    x = u * (esep + er * 0.9)
                    y = by + 0.006 * math.cos(u * math.pi * 1.5) - 0.004 * abs(u)
                    bp.append(H(x, y, sz(x, y) + 0.005))
                sweep("Brow_0_bar", bp, [(0.009, 0.007)] * len(bp), "brow", brow, ref=(0, 1, 0), seg=8, extras=NO_OUTLINE)
            bxx, byy = sx * hx * 0.66, -hy * 0.27
            sphere(f"Blush_{i}", 0.028, H(bxx, byy, sz(bxx, byy) - 0.004), "blush", head, scale=(1.3, 0.9, 0.35), seg=12, extras=NO_OUTLINE)

        # nez
        n = s["nose_s"]
        z0 = sz(0, -0.01)
        if s["nose"] == "long":
            sweep("Head_nose", [H(0, ey - ry * 0.4, z0 - 0.01), H(0, -0.03 * n, z0 + 0.018 * n), H(0, -0.07 * n, z0 + 0.03 * n),
                                H(0, -0.088 * n, z0 + 0.022 * n)],
                  [(0.011 * n,) * 2, (0.014 * n,) * 2, (0.017 * n,) * 2, (0.015 * n,) * 2], "skin", head, seg=14)
        elif s["nose"] == "button":
            sphere("Head_nose", 0.018 * n, H(0, -0.03, z0 + 0.008), "skin", head, scale=(1.1, 0.9, 0.9), seg=14)
        else:
            sweep("Head_nose", [H(0, 0.0, z0 - 0.012), H(0, -0.022 * n, z0 + 0.012 * n), H(0, -0.038 * n, z0 + 0.018 * n)],
                  [(0.012 * n,) * 2, (0.0155 * n, 0.015 * n), (0.0165 * n, 0.016 * n)], "skin", head, seg=14)

        # bouche
        my = s["mouth_y"] if s["mouth_y"] is not None else -hy * 0.56
        mz = sz(0, my) + 0.003
        mouth = bc.pivot("Mouth", G(*H(0, my, mz)), head)
        for i in range(5):
            lx = (i - 2) * 0.027
            seg = bc.pivot(f"Mouth_seg_{i}", G(*H(lx, my, mz)), mouth)
            sweep(f"Mouth_seg_{i}_bar", [H(lx - 0.02, my, mz), H(lx + 0.02, my, mz)], [(0.0062, 0.0055)] * 2, "mouth", seg, ref=(0, 1, 0),
                  seg=8, extras=NO_OUTLINE)

        def dshape(x, y, z):  # ouverture en D : haut plat, bas arrondi
            return x, (y * 0.25 if y > 0 else y), z

        mo = bc.blob("Mouth_open", 1.0, H(0, my + 0.008, mz - 0.006), "mouth_in", mouth, scale=(0.065, 0.06, 0.02), deform=dshape, seg=20,
                     extras=NO_OUTLINE)
        teeth = box("Mouth_teeth", (0.11, 0.022, 0.012), H(0, my - 0.004, mz + 0.012), "teeth", mouth, bevel=0.003, extras=NO_OUTLINE)
        tongue = sphere("Mouth_tongue", 0.03, H(0, my - 0.04, mz + 0.002), "tongue", mouth, scale=(1.4, 0.55, 0.3), seg=12, extras=NO_OUTLINE)
        for o in (teeth, tongue):
            bpy.context.view_layer.update()
            mw = o.matrix_world.copy()
            o.parent = mo
            o.matrix_world = mw
        bpy.context.view_layer.update()
        mouth.scale = (MOUTH_S,) * 3
        mw2 = 0.027 * 2 * MOUTH_S + 0.02 * MOUTH_S
        if s["smile_lines"]:
            for sx in (-1, 1):
                self.line_on_face(f"Head_smileline_{sx}", [(sx * (mw2 + 0.012), my + 0.035), (sx * (mw2 + 0.02), my + 0.012),
                                                           (sx * (mw2 + 0.016), my - 0.012)], 0.0026, head)
        for k in range(s["wrinkles"]):
            yy = ey + ry + 0.04 + k * 0.014
            self.line_on_face(f"Head_wrinkle_{k}", [(-0.045 + k * 0.004, yy), (0.0, yy + 0.004), (0.045 - k * 0.004, yy)], 0.0022, head)
        if s["mustache"]:
            yy = my + 0.022
            pts = [H(x, yy + 0.008 * (1 - abs(x) / 0.05) - (0.01 if abs(x) > 0.04 else 0), sz(x, yy) + 0.008) for x in (-0.055, -0.03, 0.0, 0.03, 0.055)]
            sweep("Head_mustache", pts, [(0.006, 0.006), (0.012, 0.009), (0.014, 0.01), (0.012, 0.009), (0.006, 0.006)], "hair", head,
                  ref=(0, 1, 0), seg=10)
        if s["beard"]:
            bc.blob("Head_beard", 1.0, H(0, -hy * 0.78, sz(0, -hy * 0.75) * 0.55), "hair", head,
                    scale=(hx * 0.8, hy * 0.42, hz * 0.62), seg=24,
                    deform=lambda x, y, z: (x, y - 0.03 * (1 - min(1, abs(x) / (hx * 0.8))) if y < 0 else y, z))
        if s["glasses"]:
            for sx in (-1, 1):
                ex = sx * esep
                ez = sz(ex, ey) - 0.004 + rz + 0.008
                ring = [H(ex + rx * 1.12 * math.cos(2 * math.pi * k / 20), ey + ry * 1.05 * math.sin(2 * math.pi * k / 20), ez)
                        for k in range(22)]
                sweep(f"Head_glasses_{sx}", ring, [(0.0042, 0.0042)] * len(ring), "glasses", head, seg=6, sub=0, extras=NO_OUTLINE)
                sweep(f"Head_glasses_arm_{sx}", [H(sx * (esep + rx * 1.1), ey, ez), H(sx * hx * 1.0, ey + 0.01, -0.01)],
                      [(0.0035, 0.0035)] * 2, "glasses", head, seg=6, extras=NO_OUTLINE)
        if s["piercing"]:
            sphere("Head_piercing", 0.006, H(0.012, -0.045, z0 + 0.02), "gold", head, seg=8)

    # ---------------------------------------------------------------- cheveux
    def _dome(self, name, ymin, flare=0.0, grow=0.014, thick=0.012):
        hx, hy, hz = self.hx, self.hy, self.hz

        def fl(x, y, z):
            if y < 0 and flare:
                t = min(1.0, -y / hy)
                x *= 1 + flare * t
                z *= 1 + flare * 0.8 * t
            return x, y, z

        bc.dome(name, 1.0, ymin, self.H(0, 0.006, -0.008), "hair", self.head, scale=(hx + grow, hy + grow * 0.85, hz + grow * 1.15),
                deform=fl, rings=12, seg=44, subsurf=0, thick=thick)

    def _spike(self, name, base, direction, length, r0, bend=(0, 0, 0)):
        b = Vector(base)
        d = Vector(direction).normalized()
        m = b + d * length * 0.5 + Vector(bend) * 0.5
        t = b + d * length + Vector(bend)
        sweep(name, [self.H(*b), self.H(*m), self.H(*t)], [(r0, r0), (r0 * 0.7, r0 * 0.7), (0.003, 0.003)], "hair", self.head, seg=10,
              cap_len=1.5)

    def _on_head(self, psi, y, grow=0.006):
        """Point de la surface de la tete (azimut psi depuis l'avant, hauteur y relative au centre)."""
        hx, hy, hz = self.hx + grow, self.hy + grow, self.hz + grow
        r = math.sqrt(max(0.0, 1 - (y / hy) ** 2))
        return (hx * r * math.sin(psi), y, hz * r * math.cos(psi))

    def _hair(self):
        s = self.s
        hx, hy, hz = self.hx, self.hy, self.hz
        t = s["hair_type"]
        sm = lambda a, b, x: (lambda u: u * u * (3 - 2 * u))(max(0.0, min(1.0, (x - a) / (b - a))))  # noqa: E731

        if t == "helmet":  # casque a frange en dents de scie
            def ym(psi):
                a = abs(psi)
                y = hy * 0.42 + 0.018 * (abs(((psi * 7.0) % 1.0) - 0.5) * 2 - 0.5) * (1 - sm(0.9, 1.2, a))
                y += (hy * 0.02 - hy * 0.42) * sm(0.9, 1.35, a)
                y += (-hy * 0.42 - hy * 0.02) * sm(1.6, 2.4, a)
                return y
            self._dome("Hair_cap", ym, grow=0.02, thick=0.014)
        elif t in ("spiky", "spiky_long"):
            def ym(psi):
                a = abs(psi)
                return hy * 0.5 + (hy * 0.05 - hy * 0.5) * sm(0.6, 1.3, a) + (-hy * 0.35 - hy * 0.05) * sm(1.7, 2.6, a)
            self._dome("Hair_cap", ym, grow=0.016)
            k = 0
            L = 0.15 if t == "spiky_long" else 0.1
            for psi, y, up, out in ((0.0, hy * 0.85, 1.0, 0.25), (0.45, hy * 0.8, 0.9, 0.5), (-0.45, hy * 0.8, 0.9, 0.5),
                                    (1.0, hy * 0.6, 0.6, 0.9), (-1.0, hy * 0.6, 0.6, 0.9), (1.7, hy * 0.35, 0.3, 1.0),
                                    (-1.7, hy * 0.35, 0.3, 1.0), (2.4, hy * 0.5, 0.4, 0.9), (-2.4, hy * 0.5, 0.4, 0.9),
                                    (math.pi, hy * 0.55, 0.5, 0.9), (1.3, -hy * 0.05, 0.0, 1.0), (-1.3, -hy * 0.05, 0.0, 1.0)):
                b = self._on_head(psi, y, 0.0)
                d = (math.sin(psi) * out, up, math.cos(psi) * out * (0.6 if abs(psi) < 1.2 else 1.0))
                self._spike(f"Hair_spike_{k}", b, d, L * (1.0 if up > 0.5 else 0.8), 0.03)
                k += 1
        elif t == "bald_tufts":
            k = 0
            for sxn in (-1, 1):
                for psi, y in ((1.45, hy * 0.18), (1.75, hy * 0.25), (2.1, hy * 0.2), (2.5, hy * 0.1)):
                    b = self._on_head(sxn * psi, y, -0.004)
                    d = (math.sin(sxn * psi) * 0.6, -0.15, math.cos(sxn * psi) * 0.9 - 0.4)
                    self._spike(f"Hair_tuft_{k}", b, d, 0.05, 0.024, bend=(0, -0.012, 0))
                    k += 1
        elif t == "bob":
            def ym(psi):
                a = abs(psi)
                return 0.105 * hy / 0.165 + (0.035 - 0.105) * sm(0.3, 1.0, a) + (-0.125 - 0.035) * sm(1.0, 1.45, a) + (-0.015) * sm(1.6, 2.6, a)
            self._dome("Hair_cap", ym, flare=0.38)
            self._sidebang()
        elif t == "ponytail":
            def ym(psi):
                a = abs(psi)
                return hy * 0.55 + (hy * 0.0 - hy * 0.55) * sm(0.5, 1.3, a) + (-hy * 0.3 - 0.0) * sm(1.7, 2.6, a)
            self._dome("Hair_cap", ym, grow=0.012)
            self._sidebang(small=True)
            b = self._on_head(math.pi, hy * 0.45, 0.01)
            sweep("Hair_tail", [self.H(*b), self.H(0, hy * 0.5, -hz * 1.35), self.H(0, hy * 0.05, -hz * 1.55),
                                self.H(0.02, -hy * 0.6, -hz * 1.45)],
                  [(0.035, 0.035), (0.05, 0.045), (0.042, 0.04), (0.006, 0.006)], "hair", self.head, seg=14, cap_len=1.4)
            sphere("Hair_tie", 0.024, self.H(*b), "accent", self.head, seg=12)
        elif t == "afro":
            def ym(psi):
                return hy * 0.25 + (-hy * 0.25 - hy * 0.25) * sm(0.8, 1.5, abs(psi))
            self._dome("Hair_cap", ym, grow=0.03, thick=0.02)
            k = 0
            for el in (0.15, 0.55, 0.9):
                n = 6 if el < 0.8 else 3
                for j in range(n):
                    psi = -2.4 + 4.8 * j / max(1, n - 1) if el < 0.8 else -0.8 + 1.6 * j / 2
                    if abs(psi) < 0.75 and el < 0.5:
                        continue
                    y = hy * (0.2 + el * 0.75)
                    b = self._on_head(psi, y, 0.045)
                    sphere(f"Hair_puff_{k}", 0.075, self.H(*b), "hair", self.head, seg=16)
                    k += 1
        elif t == "bun":
            def ym(psi):
                a = abs(psi)
                return hy * 0.5 + (hy * 0.0 - hy * 0.5) * sm(0.5, 1.3, a) + (-hy * 0.35) * sm(1.7, 2.6, a)
            self._dome("Hair_cap", ym, grow=0.012)
            b = self._on_head(math.pi * 0.85, hy * 0.85, 0.03)
            sphere("Hair_bun", 0.06, self.H(*b), "hair", self.head, seg=18)
            sweep("Hair_bun_pin", [self.H(b[0] - 0.07, b[1] + 0.02, b[2]), self.H(b[0] + 0.07, b[1] + 0.04, b[2])], [(0.005,) * 2] * 2,
                  "accent", self.head, seg=8)
        elif t == "mohawk":
            for k in range(7):
                psi = 0.15 + k * 0.45
                y = hy * (0.75 + 0.2 * math.sin(k / 6 * math.pi)) - (0.0 if k < 4 else hy * 0.15 * (k - 3))
                b = self._on_head(math.pi - (math.pi - psi), y, -0.004)
                b = (0.0, b[1], b[2])
                d = (0, 1.0, 0.25 if k < 3 else -0.4)
                self._spike(f"Hair_spike_{k}", b, d, 0.13 - abs(k - 3) * 0.015, 0.032)
        elif t == "slick":
            def ym(psi):
                a = abs(psi)
                y = hy * 0.58 - 0.03 * max(0.0, 1 - a / 0.35)
                return y + (hy * 0.05 - hy * 0.58) * sm(0.6, 1.3, a) + (-hy * 0.38 - hy * 0.05) * sm(1.7, 2.6, a)
            self._dome("Hair_cap", ym, grow=0.01)
        elif t == "receding":
            def ym(psi):
                a = abs(psi)
                y = hy * 0.82 + (hy * 0.4 - hy * 0.82) * sm(0.35, 0.8, a)
                return y + (-hy * 0.05 - hy * 0.4) * sm(0.9, 1.4, a) + (-hy * 0.35 + hy * 0.05) * sm(1.7, 2.6, a)
            self._dome("Hair_cap", ym, grow=0.012)
            self._spike("Hair_spike_0", self._on_head(0.15, hy * 0.86, 0.0), (0.1, 0.5, 1.0), 0.05, 0.02, bend=(0, -0.01, 0))

    def _sidebang(self, small=False):
        hy, H = self.hy, self.H
        k = 0.8 if small else 1.0
        sweep("Hair_bang_0", [H(0.035, hy * 1.07, 0.045), H(-0.005, hy * 0.98, 0.108 * k), H(-0.06, hy * 0.82, 0.125 * k + 0.003),
                              H(-0.112, hy * 0.55, 0.102), H(-0.13, hy * 0.25, 0.075)],
              [(0.012, 0.045 * k), (0.014, 0.05 * k), (0.013, 0.04 * k), (0.01, 0.022), (0.004, 0.006)], "hair", self.head, ref=(0, 0, 1),
              seg=12, cap_len=0.6)


def apply_mood(prefix_lookup, mood):
    """Expression d'apercu, comme CustomerActor._apply_mood (+ 'grin' : bouche ouverte en D, dents visibles)."""
    smile, brow_tilt, brow_up, opened = {"neutral": (0.35, 0, 0, False), "happy": (0.85, 0, 0.012, False),
                                         "bored": (-0.1, 0, -0.008, False), "angry": (-0.9, 0.55, -0.012, False),
                                         "shock": (0.0, 0, 0.02, True), "grin": (0.85, 0, 0.012, True)}[mood]
    o = prefix_lookup
    for i in range(5):
        u = (i - 2) / 2.0
        c = smile * 0.06
        seg_o = o(f"Mouth_seg_{i}")
        seg_o.location.z += c * u * u - c * 0.35
        seg_o.rotation_euler = (0, -math.atan(2.0 * c * u / 0.054), 0)
    for i in range(2):
        bo = o(f"Brow_{i}")
        bo.rotation_euler = (0, (brow_tilt if i == 0 else -brow_tilt), 0)
        bo.location.z += brow_up * 0.6
    for n in ("Mouth_open", "Mouth_tongue", "Mouth_teeth"):
        o(n).hide_render = not opened
    if opened:
        for i in range(5):
            o(f"Mouth_seg_{i}_bar").hide_render = True
    for i in range(2):
        o(f"Blush_{i}").hide_render = mood != "angry"
    if mood == "shock":
        o("Mouth_teeth").hide_render = True
