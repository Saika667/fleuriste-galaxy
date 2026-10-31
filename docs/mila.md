# Mila — première planche du casting

Référence : `art/concepts/cast_v1/01_mila_8_ans.png` (Mila, 8 ans).

Reconstruction géométrique Blender : enfant rousse à couettes, t-shirt vert, salopette moutarde, poche à marguerite, bretelles en Y au dos, poches arrière, chaussettes et baskets bordeaux. La taille est une hypothèse d'environ 1,3 m, cheveux inclus. Les proportions et détails sont une interprétation 3D de la planche ; la concordance exacte 1:1 n'est pas validée.

## Livrables

- `art/blender/mila.blend` : source éditable, pièces séparées et squelette.
- `art/blender/mila_toon.blend` : version avec les aplats et contours.
- `assets/models/characters/mila_toon.glb` : export pour Godot, 17 os, 7 objets de géométrie et 32 surfaces de matériau.
- `out/blender/mila_in_game_front.png` et `mila_in_game_back.png` : captures réelles dans la boutique.
- `scenes/shop/shot_mila.tscn` : aperçu jouable ; argument `mila_back` pour la vue arrière.

Le GLB comporte environ 107 000 triangles, contours géométriques inclus. Les formes sont colorées par matériaux, sans textures UV. Il n'embarque pas de clips d'animation ni de morph targets faciaux. Les mouvements d'attente et de marche sont pilotés dans Godot ; les expressions faciales restent fixes.

Mila est enregistrée sous `extra_mila`, dans les pools des passants et des visiteurs. `mila_visual.gd` utilise le chargeur de modèles squelettiques partagé avec le savant. Le cache est indexé par chemin de modèle pour conserver les deux personnages distincts. La capsule d'interaction et la hauteur de l'interface sont adaptées à sa taille.

## Régénération et contrôle

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/mila.py
```

Réimporter ensuite les ressources dans Godot. La régénération écrase les fichiers Blender générés ; modifier le script pour conserver les retouches.

`tools/blender/validate_mila.gd` vérifie l'import, les matériaux unshaded, la présence du squelette, la déformation de marche, le retour à la pose initiale, la capsule enfant et l'isolation du cache avec le savant. Résultat dans `out/blender/mila_validation.json` : contrôles réussis.
