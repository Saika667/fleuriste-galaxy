# Modèles de personnages avec Blender (CLI)

Blender 5.1 (`C:\Program Files\Blender Foundation\Blender 5.1\blender.exe`) tourne en arrière-plan : un script Python construit le modèle, l'exporte en `.glb` pour Godot et rend des aperçus PNG que l'on relit pour juger le résultat.

```
tools\blender\run.ps1 -Script tools\blender\characters\human_base.py -ScriptArgs '--ao','--torso','coat','--hat','fedora','--mood','angry'
```

Lancer depuis **PowerShell** (le tableau `-ScriptArgs` est mal transmis depuis bash). Options : `--torso dress|basic|coat`, `--hat sun|bowler|fedora|tophat|beanie|cap`, `--mood neutral|happy|bored|angry|shock` (aperçu seulement), `--ao` (cuit l'occlusion ambiante dans les couleurs de sommets, ~15 s), `--stats` (budget triangles par pièce).

| Quoi | Où |
|---|---|
| Scripts de modèles | `tools/blender/characters/*.py` ; outils de modélisation dans `tools/blender/bl_common.py` |
| Source `.blend` | `art/blender/*.blend` (`art/` est ignoré par Godot via `.gdignore`) |
| Export pour le jeu | `assets/models/characters/*.glb` |
| Aperçus (face, 3/4, profil, dos, visage) | `out/blender/*.png` (ignoré par git) |

Le script est la source de vérité : on modifie le `.py` puis on relance. Une retouche faite à la main dans le `.blend` est écrasée au prochain lancement.

## Outils de modélisation (`bl_common.py`)

- `sweep()` : tube à section elliptique le long d'une courbe (spline Catmull-Rom), rayon variable, bouts arrondis/plats/ouverts, modulation angulaire. Membres, mèches, nœuds, cils.
- `lathe()` : surface de révolution autour de Y à partir d'un profil (rayon, hauteur) : jupes, chapeaux, ourlets.
- `blob()` / `dome()` : ellipsoïde déformable (tête, joues) et calotte à bord lisse (coiffe).
- `bake_vertex_ao()` : AO sommet cuit dans la couche `Col` (exportée en COLOR_0).
- Positions écrites en coordonnées Godot (Y haut, visage vers **+Z**), converties par `bc.G()`.

## Contrat avec le jeu (CustomerActor)

Le client est un kit de pièces animées en code ; le `.glb` garde la même logique de pivots, mais **les proportions ont changé** (chibi ~3,3 têtes) : le chargeur doit lire les positions de repos dans le `.glb`, pas les constantes de `customer_actor.gd`.

- Pivots (Empty, origine = articulation, index 0 = x négatif) : `Leg_0/1` (±0.125, 0.60, 0), `Arm_0/1` (±0.30, 1.10, 0), `Head` (0, 1.45, 0), `Torso` (0, 0, 0), `Eye_0/1`, `Brow_0/1`, `Mouth` (+ `Mouth_seg_0..4`, `Mouth_open`, `Mouth_tongue`), `Blush_0/1`. Positions des yeux, sourcils et bouche relatives à `Head`, à l'échelle K = 1.3.
- Humeur (`_apply_mood`) : mêmes formules, mais la hauteur de repos des sourcils est `Brow_i.position.y` du `.glb` (pas `BROW_Y`) et le décalage des segments de bouche se multiplie par K × 0.9.
- Le **nom du matériau est le rôle de couleur** (`skin`, `top`, `bottom`, `hair`, `shoe`, `hat`...). Godot recolore par rôle (graine du client).
- **Activer `vertex_color_use_as_albedo = true`** sur chaque matériau importé : sinon l'AO cuit (COLOR_0) est ignorée.
- Variantes dans le même fichier, préfixées : `Torso_*`, `Hat_*`, `Detail_*`, `Hair_*`. Le chargeur garde celles du style et masque (ou libère) le reste. `Blush_*`, `Mouth_open`, `Mouth_tongue` masqués par défaut. Masquer `Hair_bang_*` sous bonnet/casquette ; `Hair_bun*`/`Hair_bone` ne sont à garder qu'avec la robe.
- Propriété perso `no_outline` → `get_meta("extras")["no_outline"]` dans Godot (à recopier en `set_meta("no_outline", true)` avant `MeshKit.apply_char_outline`).
- L'échelle de la tête (`head_s`) et du torse (`girth`) restent pilotées par le code ; la tête est à l'échelle 1 dans le fichier.

## Budget

Look par défaut (robe + chapeau de soleil) : ~41 600 triangles, 107 meshes, `.glb` 1,5 Mo avec toutes les variantes. C'est un budget « héros » ; prévoir une version allégée pour les foules (visibilité par distance : cils, cernes, doigts).

## État (26 octobre 2026)

`human_base` validé en aperçu (4 vues + visage, 5 humeurs, 6 chapeaux, 3 hauts) et à l'import Godot 4.7.2 (noms, pivots, rôles, COLOR_0). `CustomerActor` n'utilise **pas encore** le `.glb` : `_build_human` reste procédural tant que le chargeur n'est pas écrit. Pas encore portés : accessoires (lunettes, moustache, sac...), archétypes (squelette, zombie, mamie, enfant), aliens.

## MCP (optionnel)

Le CLI suffit pour construire et vérifier. Un serveur MCP Blender (addon + `uvx`) ajouterait la retouche en direct dans une fenêtre Blender ouverte ; il n'est pas installé (`uv` absent).

## Second kit : style « Rick et Morty » (`human_rm.py`)

Même contrat de noms/pivots que `human_base`, direction calquée sur la série (référence fournie le 26 octobre 2026) : adulte ~5 têtes, tête ovale plus haute que large, gros yeux globuleux qui se touchent (pupille-point, 3 cils au coin externe chez les femmes), nez en bosse, bouche fine (dents et langue sont enfants de `Mouth_open`), cou mince visible, bras longs, mains à 4 doigts, cheveux à pointes ; aplats + trait fin. Pivots : `Leg_i` (±0.068, 0.88), `Arm_i` (±0.135, 1.27), `Head` (0, 1.50) ; visage en mètres relatifs à `Head`. Le pivot `Mouth` est à l'échelle 0.55 : les formules de `_apply_mood` (unités locales) gardent leur amplitude.

```
tools\blender\run.ps1 -Script tools\blender\characters\human_rm.py -ScriptArgs '--torso','coat','--hat','fedora','--mood','angry'
```

Aperçu : `bc.preview_toon()` remplace les matériaux par des aplats émissifs et ajoute une coque inversée noire (le `.glb` reste inchangé). Côté Godot : matériaux en `shading_mode = unshaded` (ou toon à 2 tons) + contour du jeu (`MeshKit.apply_char_outline`) ; ne pas activer `vertex_color_use_as_albedo` (pas d'AO cuit).

Budget : ~23 000 triangles pour le look par défaut, `.glb` 0,8 Mo. Pièces propres à ce kit : `Arm_i_sleeve` (manche courte, bras nus en `skin`), `Hair_tip_*` (pointes du carré), frange balayée `Hair_bang_*` (à masquer sous bonnet/casquette), `Eye_i_lash_*`.
