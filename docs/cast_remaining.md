# Planches 05 à 10 — modèles intégrés

Les six modèles sont des reconstructions procédurales éditables à partir des PNG de `art/concepts/cast_v1`. Les volumes, les proportions et les accessoires sont interprétés depuis les vues dessinées ; la fidélité exacte 1:1 n'est pas validée.

| Planche | Modèle | Particularités | Squelette |
|---|---|---|---|
| 05 | Odette | Chignon gris, lunettes cerclées, châle à motifs et franges, robe prune, sacoche, bottines | 17 os |
| 06 | Léon | Grandes oreilles, moustache blanche, dos voûté, cardigan rouille, bretelles, pantalon olive | 17 os |
| 07 | Vexa | Tête en croissant, trois yeux, deux cornes, quatre bras, tunique fendue et ceinture corail | 23 os |
| 08 | Bloop | Corps turquoise en poire, œil unique, deux antennes, tablier orange avec poche et nœud arrière | 17 os |
| 09 | Kragg | Carapace ocre, deux yeux pédonculés, six pattes articulées, deux pinces, poncho vert déchiré | 25 os |
| 10 | Luma | Tête en cloche menthe, taches lavande, gilet corail, sacoche, deux bras souples et trois tentacules inférieurs | 15 os |

Révision visuelle : les épaules de Léon sont rapprochées du haut du cardigan et leurs articulations suivent ce nouveau raccord. Les trois pupilles de Vexa ont un rayon égal à 28 % de celui des yeux, contre 9 % initialement. Le dos de Bloop comporte douze taches supplémentaires. Ses fesses sont deux volumes ellipsoïdaux fusionnés au corps par remeshing, puis lissés et simplifiés, avec un vrai creux entre les deux. Le trait vert initial est supprimé ; une teinte discrète suit les surfaces inférieures pour rendre le volume lisible avec les matériaux unlit. `out/blender/bloop_rear_geometry.json` mesure la profondeur des deux lobes et du creux central.

## Fichiers

Pour chaque identifiant `odette`, `leon`, `vexa`, `bloop`, `kragg`, `luma` :

- `art/blender/<identifiant>.blend` : source avec pièces séparées et squelette.
- `art/blender/<identifiant>_toon.blend` : version avec contours géométriques.
- `assets/models/characters/<identifiant>_toon.glb` : export utilisé dans Godot.
- `assets/models/characters/<identifiant>_toon.json` : rapport d'export, nombre de triangles et de maillages.
- `out/blender/<identifiant>_front.png`, `_back.png`, `_three_quarter.png` : vues de contrôle Blender.
- `out/blender/<identifiant>_in_game.png` : capture dans Godot, face à gauche, dos à droite.

## Utilisation dans le jeu

Les six personnages figurent dans les pools de passants et de visiteurs de la boutique, sous `extra_<identifiant>`. `customer_actor.gd` choisit leur modèle, leur vitesse, leur capsule d'interaction et la hauteur de leurs bulles. Les anciens modèles conservent leur contrôleur existant.

`cast_visual.gd` anime les squelettes importés : marche pour les humains et Bloop, deuxième paire de bras pour Vexa, cycle alterné des six pattes de Kragg et ondulation des tentacules avec flottement pour Luma. Les animations sont produites par le contrôleur Godot, sans clips intégrés au GLB. Les visages restent fixes.

Les matériaux sont unlit avec contours en coque inversée. Les maillages de présentation sont denses, sans LOD, textures UV ni morph targets ; une optimisation supplémentaire est nécessaire pour de grandes foules. Ne pas appliquer un second contour par-dessus celui du GLB.

## Régénération

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/remaining_cast.py -ScriptArgs odette
```

Remplacer `odette` par l'un des cinq autres identifiants. Les retouches durables se font dans le script ; une régénération remplace les fichiers Blender générés. Réimporter ensuite les ressources dans Godot.

## Captures et validation

`scenes/shop/shot_cast.tscn` ouvre la véritable scène de jeu. Arguments : identifiant du personnage, puis `pair` pour les vues face et dos ensemble, ou `back` pour une vue arrière seule. Le cadrage de contrôle fige les personnages et les papillons, sans modifier les animations de la partie normale.

`tools/blender/validate_remaining_cast.gd` vérifie les six imports, les os supplémentaires de chaque anatomie, les skins, les matériaux, les capsules, une pose animée et la coexistence avec Mila, Noé, Aya, Gaston et le savant. Résultats : `out/blender/remaining_cast_validation.json`.
