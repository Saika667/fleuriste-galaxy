# Gaston — quatrième planche du casting

Référence : `art/concepts/cast_v1/04_gaston_44_ans.png`, Gaston, 44 ans.

Révision visuelle : départ des bras abaissé et rapproché du buste, haut des manches aminci et fermé à plat pour supprimer les bosses au-dessus des épaules. Les articulations et les poids sont régénérés avec la nouvelle position.

Reconstruction en volumes : silhouette trapue, ventre arrondi, calvitie et cheveux roux, moustache tombante, veste de travail verte ouverte, polo crème rayé, ceinture à boucle dorée, pantalon bleu et mocassins bruns. Taille hypothétique d'environ 1,70 m. La géométrie est une interprétation 3D de la planche ; la correspondance exacte 1:1 n'est pas validée.

## Livrables

- `art/blender/gaston.blend` : source éditable avec les pièces séparées et le squelette.
- `art/blender/gaston_toon.blend` : version avec aplats et contours géométriques.
- `assets/models/characters/gaston_toon.glb` : modèle chargé dans Godot, 17 os, 7 objets de géométrie et 166 328 triangles contours inclus.
- `scenes/shop/shot_gaston.tscn` : aperçu dans la boutique ; argument `gaston_back` pour la vue arrière.
- `out/blender/gaston_in_game_front.png` et `gaston_in_game_back.png` : captures réelles dans Godot.

Gaston est disponible sous `extra_gaston`, dans les pools de passants et de visiteurs. Le contrôleur squelettique anime l'attente et la marche, avec une capsule adaptée à sa silhouette. Les expressions faciales restent fixes. Le GLB n'embarque pas de clips d'animation, de morph targets, de LOD ou de textures UV. Les couleurs viennent des matériaux unlit ; ne pas superposer un second contour à ceux déjà inclus. Le maillage dense doit être optimisé pour une utilisation massive de personnages.

## Régénération et validation

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/gaston.py
```

Réimporter les ressources dans Godot après la génération. Modifier le script pour conserver les retouches ; une régénération remplace les sources Blender générées.

`tools/blender/validate_gaston.gd` vérifie l'import, les matériaux unshaded, les 17 os, la capsule, la déformation d'une jambe et le retour à sa pose initiale, ainsi que le chargement simultané de Gaston, Aya, Mila, Noé et du savant. Rapport : `out/blender/gaston_validation.json`.
