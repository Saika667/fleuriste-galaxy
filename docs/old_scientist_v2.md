# Savant : reconstruction 3D depuis les sept références

Version du 26 octobre 2026. La version précédente est conservée.

## Fichiers

- Source modifiable, pièces séparées et squelette : `art/blender/old_scientist_v2.blend`.
- Version avec aplats et contours, réimportée du GLB : `art/blender/old_scientist_v2_toon.blend`.
- Export destiné à Godot : `assets/models/characters/old_scientist_v2_toon.glb`.
- Export avec matériaux PBR, sans contours : `assets/models/characters/old_scientist_v2.glb`.
- Comparaison des références et des rendus : `out/blender/sci_v2_review.png`.
- Rendus face, dos, profil, trois quarts et portraits : `out/blender/sci_v2_*.png`.

## Portée et fidélité

Reconstruction géométrique procédurale à partir des dessins, en mètres, avec une hauteur approximative de 1,80 m jusqu'au crâne. Cette taille est une hypothèse, aucune dimension physique n'ayant été donnée.

Les sept images décrivent le personnage et sa canne, avec de petites variations de proportions et de placement des accessoires entre les vues. La face sert de référence aux proportions ; le profil guide la posture voûtée et la profondeur du visage.

**La fidélité 1:1 demandée n'est pas atteinte.** La chevelure reste trop segmentée, les contours et volumes de la bouche et des oreilles diffèrent, les revers et déchirures de la blouse sont approximatifs et certains accessoires sont simplifiés. Les pupilles fixes ne reproduisent pas les ajustements de perspective du dessin dans toutes les vues. Les trous sont des surfaces colorées, pas des ouvertures physiques. Le modèle constitue une base de reconstruction révisable, pas un personnage final validé pour la production.

## Caractéristiques de l'export pour le jeu

- Squelette de 17 os avec poids de déformation : tronc, tête, bras, mains, jambes et pieds. Les doigts ne sont pas articulés individuellement.
- 11 objets de géométrie, 62 surfaces de matériau, 28 matériaux.
- 149 230 triangles, contours géométriques inclus ; environ 4,22 Mo.
- Matériaux en aplats via `KHR_materials_unlit`, contours par coques à normales inversées. Ne pas ajouter le contour du jeu par-dessus sans désactiver les coques déjà présentes.
- Aucune animation exportée. Les variantes faciales restent des pièces de la source Blender, sans morph targets ni contrôleur facial livré.
- Pas de textures UV, normal maps, LOD ni collision livrés. Le budget doit être réduit si le personnage doit apparaître en foule ou sur mobile.
- Intégré à `CustomerActor` sous `extra_scientist` : nouveau passant « Le savant », présent dans les pools de la rue et des visiteurs. Le premier passant de la rue utilise ce modèle.
- `scientist_visual.gd` conserve la pose importée et ajoute des mouvements légers du squelette pour la marche et l'attente. Les expressions faciales du modèle restent fixes.
- Aperçu jouable dans la vraie boutique : `scenes/shop/shot_scientist.tscn`. Capture : `out/blender/scientist_in_game.png`.
- L'argument `scientist_animation` active une boucle de démonstration de 12 secondes : attente, cycle de marche sur place vu de face puis de profil, retour à l'attente. Cette boucle appelle l'animation réelle de `CustomerActor` sans déplacer le personnage. Captures : `out/blender/scientist_animations.gif` et `.mp4`.

## Vérification

`validate_scientist_v2.py` réimporte le GLB livré dans Blender : positions finies, poids normalisés, 17 os, mouvement effectif des sommets lorsque l'avant-bras tourne de 15 degrés, retour exact à la pose de repos. Un rendu provient de ce GLB réimporté.

`validate_scientist_v2.gd` charge directement le même fichier dans Godot 4.7.2 : import réussi, 11 objets de géométrie, 17 os et 62 surfaces en mode unshaded. Ce contrôle d'import ne remplace pas une validation des animations dans le jeu.

Rapports : `out/blender/sci_v2_validation.json`, `out/blender/sci_v2_godot_validation.json`, `assets/models/characters/old_scientist_v2_toon.json`.

## Régénération

Révision visuelle : la portion marron de la bandoulière qui traversait le dos a été supprimée. La portion avant et le boîtier restent présents.

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/old_scientist_v2.py
tools/blender/run.ps1 -Script tools/blender/validate_scientist_v2.py
```

Le premier script reconstruit les deux exports et les rendus. Le second vérifie l'export et sauvegarde le `.blend` avec le rendu en aplats. Les retouches manuelles de ces fichiers `.blend` seraient écrasées par une régénération.
