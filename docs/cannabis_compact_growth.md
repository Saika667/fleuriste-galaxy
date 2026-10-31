# La compacte : deux stades visuels

Deux modèles natifs distincts interprètent la planche `art/concepts/cannabis/growth/01_compacte_stades.png` :

- `cannabis_compact_seedling` : petite tige, deux cotylédons arrondis, deux premières feuilles dentelées, aucune tête.
- `cannabis_compact_growing` : tige plus fine que l'adulte, cinq mini-grappes, douze feuilles palmées plus petites, deux petites branches exclusivement feuillues avant/arrière.

Le pot et le sol reprennent les dimensions et les couleurs de la compacte adulte. La plante intermédiaire atteint environ deux tiers de la hauteur végétale adulte au-dessus du terreau. Les formes et les têtes sont reconstruites séparément ; il ne s'agit pas d'une mise à l'échelle globale de l'adulte. Couleurs unies, contours géométriques, origine sous le pot, mètres et axe Y vertical dans Godot.

Sources Blender et exports GLB/JSON : mêmes dossiers `art/blender/plants` et `assets/models/plants` que les autres plantes. Deux scènes réutilisables dans `scenes/props`. Instanciation possible par identifiant via `cannabis_visual.gd`. Ce sont des props statiques de présentation ; aucun changement des cycles de croissance du gameplay.

Génération : Blender `--background --python-exit-code 1 --python tools/blender/cannabis_compact_growth.py`, puis réimport Godot. Le générateur vérifie dimensions et transformations. Les rapports JSON donnent hauteur et budget géométrique ; pas de rig ni de LOD.

Captures réelles : `scenes/shop/shot_cannabis.tscn -- growth_batch <dossier absolu>`. Six captures, deux stades et trois angles, avec le même cadrage que l'adulte pour conserver une comparaison de taille. Assemblage et archive : `tools/blender/package_cannabis_growth.py`.
