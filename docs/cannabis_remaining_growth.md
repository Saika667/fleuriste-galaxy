# Deux stades pour les cinq autres plantes

Dix nouveaux props natifs, reconstruits depuis les planches `art/concepts/cannabis/growth/02_elancee_stades.png` à `06_menthe_rose_stades.png`. Chaque famille reçoit un modèle `_seedling` et un modèle `_growing` :

| Famille | Aspect conservé | Mini-têtes au stade intermédiaire |
|---|---|---|
| cannabis_elancee | Tige haute, feuilles étroites vert citron, pot turquoise/crème | 4 |
| cannabis_pourpre | Buisson large, revers pourpres, pot rectangulaire ivoire/prune | 6 |
| cannabis_eventail | Trois axes en éventail, jaune-vert, coupe olive | 3 |
| cannabis_sauvage | Tige en S asymétrique, vert bleuté, pot bordeaux | 4 |
| cannabis_menthe_rose | Feuilles menthe, têtes roses fictives, pot bleu arrondi | 5 |

Petite pousse : deux cotylédons et deux premières feuilles dentelées, aucune tête. Les feuilles sont inclinées pour rester lisibles du dessus. Stade intermédiaire : tige plus fine, branches plus courtes, feuilles palmées réduites, petits rameaux avant/arrière et mini-grappes en volume. La végétation atteint environ deux tiers de la hauteur adulte au-dessus du terreau. Les pots gardent leurs dimensions adultes et leurs palettes exactes. Les stades sont des constructions distinctes, pas une mise à l'échelle globale des adultes.

Sources `art/blender/plants/<id>.blend`, consolidation `<id>_toon.blend`, exports `assets/models/plants/<id>_toon.glb`, rapport géométrique `<id>_toon.json`, scènes `scenes/props/<id>.tscn`. Origine sous le pot, mètres et axe Y vertical dans Godot, contours par géométrie et couleurs unies sans texture photo. Props statiques sans LOD ni rig. Les cycles du gameplay de la cave ne sont pas modifiés.

Génération : Blender `--background --python-exit-code 1 --python tools/blender/cannabis_remaining_growth.py`. Une sélection de familles peut suivre `--`. Le script réutilise les spécifications littérales de palette et de pot du générateur adulte ; il construit les jeunes végétations séparément et vérifie dimensions et transformations à l'export.

Réimporter dans Godot, puis lancer `scenes/shop/shot_cannabis.tscn -- remaining_growth_batch <dossier absolu>` pour trente vues réelles. Même caméra entre les deux stades d'une famille, avec la distance de présentation de l'adulte. Le mode `growth_batch` conserve les deux stades de la compacte et `plant_batch` conserve les six modèles adultes. `tools/blender/package_cannabis_remaining_growth.py` prépare les planches de captures, la galerie et les archives sans repeindre les images.
