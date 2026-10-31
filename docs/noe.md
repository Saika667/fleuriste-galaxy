# Noé — deuxième planche du casting

Référence : `art/concepts/cast_v1/02_noe_15_ans.png`, Noé, 15 ans.

Modèle Blender construit en volumes : silhouette adolescente longiligne, cheveux bruns en mèches, sweat prune à capuche, cordons, poche kangourou, manches retroussées, short cargo anthracite, montre, chaussettes dépareillées et baskets montantes vert olive. Taille hypothétique : environ 1,7 m avec les cheveux. La géométrie est une interprétation de la planche ; la correspondance 1:1 n'est pas validée.

## Fichiers

- `art/blender/noe.blend` : source éditable avec les pièces séparées et le squelette.
- `art/blender/noe_toon.blend` : version avec aplats et contours.
- `assets/models/characters/noe_toon.glb` : modèle utilisé par le jeu, squelette de 17 os, 7 objets de géométrie, 43 surfaces de matériau, environ 130 000 triangles avec contours.
- `scenes/shop/shot_noe.tscn` : aperçu dans la vraie boutique ; ajouter l'argument `noe_back` pour la vue arrière.
- `out/blender/noe_in_game_front.png`, `out/blender/noe_in_game_back.png` : captures réelles dans Godot.

Noé est intégré sous `extra_noe` aux passants et aux visiteurs. Ses mouvements d'attente et de marche utilisent le contrôleur squelettique partagé avec Mila ; la taille de sa capsule et les hauteurs d'interface sont adaptées à l'adolescent. Le GLB utilise des matériaux unlit et des contours géométriques déjà inclus. Pas de textures UV, de morph targets faciaux ni de clips d'animation embarqués ; le visage reste fixe et les mouvements sont calculés dans Godot.

## Régénération

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/noe.py
```

Réimporter ensuite les ressources dans Godot. Une régénération remplace les fichiers Blender générés ; conserver les retouches dans le script source.

Le contrôle `tools/blender/validate_noe.gd` vérifie l'import, les 17 os, les 43 surfaces unshaded, la capsule, le mouvement d'une jambe et son retour à la pose initiale, ainsi que le chargement simultané de Noé, Mila et du savant sans mélange des modèles. Rapport : `out/blender/noe_validation.json`.
