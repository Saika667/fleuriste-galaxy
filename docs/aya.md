# Aya — troisième planche du casting

Référence : `art/concepts/cast_v1/03_aya_28_ans.png`, Aya, 28 ans.

Reconstruction en volumes : coiffure afro asymétrique et tempe dégagée, anneau doré, chemise crème à manches roulées, tablier vert, poche avec sécateur, bretelles et nœud au dos, pantalon cargo ocre, bottes prune à lacets et semelles crantées. Taille hypothétique d'environ 1,85 m avec la coiffure. La géométrie est une interprétation 3D de la planche ; la correspondance exacte 1:1 n'est pas validée.

## Livrables

- `art/blender/aya.blend` : source éditable avec les pièces séparées et le squelette.
- `art/blender/aya_toon.blend` : version avec aplats et contours géométriques.
- `assets/models/characters/aya_toon.glb` : modèle chargé dans Godot, 17 os et 7 objets de géométrie, environ 133 000 triangles contours inclus.
- `scenes/shop/shot_aya.tscn` : aperçu dans la vraie boutique ; argument `aya_back` pour la vue arrière.
- `out/blender/aya_in_game_front.png` et `aya_in_game_back.png` : captures réelles dans Godot.

Aya est disponible sous `extra_aya`, dans les pools de passants et de visiteurs. Le contrôleur squelettique anime l'attente et la marche, avec les proportions et la capsule propres au modèle. Les expressions faciales restent fixes. Le GLB n'embarque pas de clips d'animation, de morph targets, de LOD ou de textures UV. Les couleurs viennent des matériaux unlit ; ne pas superposer un second contour à ceux déjà inclus.

## Régénération et validation

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/aya.py
```

Réimporter les ressources dans Godot après la génération. Modifier le script pour conserver les retouches ; une régénération remplace les sources Blender générées.

`tools/blender/validate_aya.gd` vérifie l'import, les matériaux unshaded, les 17 os, la capsule, la déformation d'une jambe et le retour à sa pose initiale, ainsi que le chargement simultané d'Aya, Mila, Noé et du savant. Rapport : `out/blender/aya_validation.json`.
