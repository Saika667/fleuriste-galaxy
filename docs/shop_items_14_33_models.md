# Collection boutique 14–33

Vingt modèles réalisés en Blender à partir des planches de `art/concepts/shop/items_14_33.html`, exportés en GLB métriques sous `assets/models/shop`. Sources éditables dans `art/blender/shop`.

- 14 : vase orange creux avec col crème, relief et médaillon ; branchement au système existant de compositions libres et de sauvegarde.
- 15–17 : présentoir à auvent rayé avec six emplacements, grand pot de roses et tapis floral fin et praticable.
- 18–21 : enveloppes soie, kraft et noire, bouquet lié sans emballage. Fleurs choisies par le joueur, fraîcheur et variantes conservées. Les tiges traversent les enveloppes ouvertes et dépassent du lien.
- 22–30 : étagère murale avec consoles, lierre retombant, cactus fleuri, plante-crâne et cinq bocaux à couvercles distincts (yeux, bulbes, gel, dents, graines).
- 31–33 : panneau perforé avec cinq outils reconnaissables, ardoise du menu et pancarte suspendue RIP / promotions.

## Intégration

`shop_collection_visual.gd` charge et prépare les modèles, applique les contours fins et la transparence des bocaux, puis regroupe les géométries statiques par matériau. `furniture_factory.gd` conserve les identifiants de mobilier et les emplacements de bouquets. `shop_decor.gd` conserve les positions, orientations et variantes de taille des objets existants. Le vase orange est ajouté à `shop_vase_visual.gd`.

Les fleurs des pots sont des composants distincts dans Blender. Les vases et les bouquets utilisent les fleurs natives et les compositions dynamiques du jeu. Les anciens contours inversés sont retirés lors de la réimportation Blender des fleurs pour éviter les surfaces noires après réexport.

## Vérification et captures

`scenes/shop/shot_items_14_33.tscn` lance la vraie boutique Godot et enregistre 43 images dans `out/items_14_33_review`. Les éléments optionnels sont temporairement présentés sur le sol ; les petits objets sont présentés sur l’établi pour faciliter la comparaison. Le tapis possède une vue du dessus et l’étagère une vue de détail de ses consoles. Aucune sauvegarde de joueur n’est modifiée par la scène de capture.

Les tests `tests/test_shop_collection.gd` vérifient les mélanges libres dans le vase orange, les six emplacements du présentoir, le tapis praticable et la conservation des bouquets lors du rendu. La galerie contient les deux vues de chacun des vingt modèles et les liens vers GLB, Blender et planches.

Validation du 27 octobre 2026 : 5 805 assertions réussies, aucun échec ; scène de capture terminée sans erreur de script. Les avertissements ObjectDB/ressources à la fermeture du runner sont déjà présents dans la suite existante. Le paquet contrôle vingt GLB valides, vingt sources Blender et 43 PNG de 1600 × 900.

## Reproduction

Génération : `blender --background --python tools/blender/shop_items_14_33.py`. Un ou plusieurs noms d’assets après `--` régénèrent uniquement ces modèles.

Import : `godot --headless --editor --path . --import`.

Captures : `godot --path . --resolution 1600x900 scenes/shop/shot_items_14_33.tscn`.

Tests : `godot --headless --path . -s tests/run_tests.gd`.

Galerie et archive : `python tools/package_shop_items_14_33.py`. Le script contrôle les vingt GLB, leurs sources Blender et les 43 PNG avant de créer l’archive.
