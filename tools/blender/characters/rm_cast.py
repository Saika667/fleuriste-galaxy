"""Dix clients originaux dans le style « Rick et Morty » (fiches -> rm_kit.Char). Chaque perso est exporte en glb (contrat du jeu),
puis tous sont alignes pour une affiche de groupe + un gros plan de chaque visage.

Lancer (PowerShell) : tools\\blender\\run.ps1 -Script tools\\blender\\characters\\rm_cast.py [-ScriptArgs '--only','theo']
Sorties : assets/models/characters/rm/<id>.glb, out/blender/cast_lineup.png, out/blender/cast_face_<id>.png
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import bl_common as bc  # noqa: E402
import rm_kit  # noqa: E402

CAST = [
    dict(id="papy_bertrand", name="Papy Bertrand, retraite grincheux", height=1.86, head=(0.122, 0.17, 0.13), jaw=0.32,
         neck_len=0.11, neck_r=0.03, shoulder=0.14, chest=(0.12, 0.08), waist=(0.105, 0.075), hips=(0.11, 0.078), hunch=0.02,
         skin="#F2D9C2", top_type="cardigan", top="#8A6A4A", top_light="#B89A7A", accent="#E8D7B0", bottom="#6E6E72",
         shoe="#4A3A30", hair="#E8E8EE", hair_type="bald_tufts", brows="unibrow", brow_col="#C8C8D0", lids="half", lid_cut=0.3,
         bags=2, nose="long", wrinkles=3, smile_lines=True, pupil=(0.0, -0.012), mood="bored"),
    dict(id="theo", name="Theo, ado anxieux", height=1.42, head=(0.15, 0.155, 0.14), jaw=0.16, neck_len=0.07, neck_r=0.03,
         shoulder=0.12, chest=(0.11, 0.075), waist=(0.1, 0.07), hips=(0.105, 0.072), leg_r=0.05, arm_r=0.027, eye_y=0.0,
         top_type="tee", top="#7BC96F", top_light="#B5E3AC", bottom="#2F4E8C", shoe_type="sneaker", shoe="#FFFFFF", sole="#BFBFBF",
         hair="#5A3A22", hair_type="helmet", mood="shock", pupil=(0.0, -0.002)),
    dict(id="lou", name="Lou, ado blasee", height=1.58, head=(0.125, 0.16, 0.13), top_type="tank", top="#F27BB0", top_light="#F9B9D6",
         bottom="#6B4FA0", shoe_type="sneaker", shoe="#EDEDED", sole="#B0B0B8", hair="#E8A33D", hair_type="ponytail", accent="#6B4FA0",
         lashes=True, lids="half", lid_cut=0.42, earrings=True, mood="bored", pupil=(0.008, -0.004)),
    dict(id="nadia", name="Nadia, maman joviale", height=1.68, skin="#9A6446", hair="#1E1612", hair_type="afro", brow_col="#1E1612",
         top_type="blouse", top="#D9433A", top_light="#F08C7E", bottom="#F2EAD8", shoe="#6B2A24", lashes=True, earrings=True,
         mood="grin"),
    dict(id="gerard", name="Gerard, papa maladroit", height=1.78, head=(0.12, 0.19, 0.13), jaw=0.22, chin=0.02, hair="#7A5232",
         hair_type="receding", mustache=True, top_type="polo", top="#E9C64A", top_light="#F6E39A", bottom="#B39A6E", belly=0.03,
         shoe="#5A3A28", mood="grin", smile_lines=True, eye_r=0.048, nose_s=1.2),
    dict(id="odette", name="Mamie Odette", height=1.5, hunch=0.03, head=(0.13, 0.155, 0.13), skin="#F5DCCB", hair="#D8D8E0",
         hair_type="bun", glasses=True, top_type="cardigan", top="#B79BD6", top_light="#D8C7EE", accent="#F6E3A1", bottom_type="skirt",
         bottom="#6A5A8C", skirt_len=0.45, shoe="#2E2A33", wrinkles=2, bags=1, lids="half", lid_cut=0.45, mood="happy",
         brow_col="#B8B8C4"),
    dict(id="zed", name="Zed, punk du quartier", height=1.8, shoulder=0.13, chest=(0.11, 0.075), waist=(0.09, 0.065), hips=(0.1, 0.07),
         leg_r=0.045, arm_r=0.026, skin="#F0D2C0", hair="#6BE04F", hair_type="mohawk", top_type="tank", top="#1C1C22",
         top_light="#3A3A44", bottom="#3A4D7A", shoe_type="boot", shoe="#1C1C22", sole="#0E0E10", piercing=True, earrings=True,
         lids="half", lid_cut=0.35, bags=1, brows="thick", brow_col="#2A2A2A", mood="angry"),
    dict(id="clara", name="Clara, cadre pressee", height=1.74, skin="#E8C4A8", hair="#141218", hair_type="bob", top_type="suit",
         top="#2E3A5C", top_light="#46557E", collar="#FFFFFF", bottom="#2E3A5C", shoe="#141218", sole="#0E0E10", lashes=True,
         lids="half", lid_cut=0.4, mood="neutral", brow_col="#141218"),
    dict(id="momo", name="Momo, boulanger", height=1.7, belly=0.08, chest=(0.14, 0.1), shoulder=0.15, hips=(0.13, 0.09), leg_r=0.065,
         arm_r=0.036, head=(0.135, 0.16, 0.14), skin="#D9A47E", hair="#2B1E16", hair_type="none", beard=True, mustache=True,
         top_type="tee", top="#9A9AA4", top_light="#C8C8D0", apron=True, bottom="#4A4A52", shoe="#2B1E16", mood="grin", eye_r=0.05,
         brows="thick"),
    dict(id="m_lugubre", name="M. Lugubre, croque-mort", height=1.95, shoulder=0.13, chest=(0.11, 0.075), waist=(0.085, 0.06),
         hips=(0.095, 0.065), leg_r=0.045, arm_r=0.025, head=(0.115, 0.19, 0.125), jaw=0.35, neck_len=0.12, skin="#E4E0EA",
         hair="#141218", hair_type="slick", top_type="suit", top="#1A1820", top_light="#2B2833", collar="#FFFFFF", tie_col="#6B3FA0",
         bottom="#1A1820", shoe="#0E0E10", sole="#050506", lids="half", lid_cut=0.35, bags=2, nose="long", nose_s=0.85,
         mood="neutral", brow_col="#141218"),
]

ARGS = bc.script_args()
ONLY = ARGS[ARGS.index("--only") + 1] if "--only" in ARGS else None
cast = [c for c in CAST if ONLY is None or c["id"] == ONLY]

bc.reset_scene()
SPACING = 0.68
outdir = os.path.join(bc.ROOT, "assets", "models", "characters", "rm")
os.makedirs(outdir, exist_ok=True)
placed = []
for k, spec in enumerate(cast):
    ch = rm_kit.Char(spec)
    rig = ch.build()
    bc.export_glb(os.path.join(outdir, f"{spec['id']}.glb"), rig)
    rm_kit.apply_mood(lambda n: bpy.data.objects[n], spec["mood"])
    # noms uniques avant le perso suivant
    for o in [rig] + list(rig.children_recursive):
        o.name = f"{spec['id']}:{o.name}"
    for m in list(bc._MATS.values()):
        m.name = f"{spec['id']}:{m.name}"
    x = (k - (len(cast) - 1) / 2) * SPACING
    rig.location.x = x
    placed.append((spec, x, ch.head_y))
    print("BUILT", spec["id"])

bc.preview_toon(width=0.0032, cel=0.0, min_size=0.02)
od = os.path.join(bc.ROOT, "out", "blender")
os.makedirs(od, exist_ok=True)
faces = {f"face_{s['id']}": dict(yaw=14, focus=(x, hy - 0.02, 0), dist=1.45, elev=3) for s, x, hy in placed}
bc.render_preview(os.path.join(od, "cast"), views=faces, res=(800, 900), floor=False, bg="#CFE6EC", key_only=True)
if len(cast) > 1:
    bc.render_preview(os.path.join(od, "cast"), views={"lineup": dict(yaw=8, focus=(0, 1.0, 0), dist=14.5, elev=4)},
                      res=(3600, 1300), floor=False, bg="#CFE6EC", key_only=True)
print("DONE")
