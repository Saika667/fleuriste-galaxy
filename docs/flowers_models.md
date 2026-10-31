# Fleurs cartoon 3D

Les dix variétés du catalogue `data/flowers.json` possèdent désormais un modèle natif : rose, tulipe, lys, tournesol, lavande, marguerite, coquelicot, fleur xéno, orchidée mordeuse et pleurelune. Références : `art/concepts/flowers/*_cartoon.png`.

Sources éditables dans `art/blender/flowers/<identifiant>.blend`. Versions avec contours dans `<identifiant>_toon.blend`. Assets de jeu : `assets/models/flowers/<identifiant>_toon.glb`. Les rapports JSON voisins indiquent les triangles, les surfaces et les caractéristiques de chaque fleur.

Tous les modèles partagent une origine à la coupe de la tige, l'axe Y vertical, la face vers +Z et un centre de fleur vers Y=0,445 m. Les neuf nouvelles fleurs sont consolidées en un maillage chacune, avec des matériaux partagés par couleur. Les pétales et feuilles ont une épaisseur. Le calice et les faces arrière sont modélisés. Couleurs en aplats unlit et contours par coque inversée. Pas de textures photographiques.

Six variétés ont également trois palettes supplémentaires, décrites dans `docs/flower_variants.md`. Les vases et bouquets les alternent visuellement ; les couleurs logiques des commandes restent dans le catalogue existant.

Particularités : six pétales et coupe creuse pour la tulipe ; six tépales et six étamines pour le lys ; douze pétales et grand disque brun pour le tournesol ; six étages de fleurons pour la lavande ; douze pétales et petit cœur jaune pour la marguerite ; quatre pétales et cœur sombre pour le coquelicot ; trois lobes, un œil et une antenne pour la fleur xéno ; cinq pétales, deux lèvres et dix dents pour l'orchidée ; cloche creuse à cinq lobes et une goutte pour la pleurelune.

`src/world/flower_visual.gd` associe les dix identifiants aux GLB. Les vases de stock et les bouquets emploient les nouveaux modèles en conservant les couleurs de fraîcheur et l'affaissement du bouquet. Les plantes purement décoratives sans variété de catalogue gardent leurs formes actuelles. Les règles d'achat et de déblocage restent dans le catalogue existant.

Les nouveaux modèles sont statiques : aucun clip ni rig, la mâchoire de l'orchidée reste ouverte. Pas encore de LOD ; environ 15 000 à 31 000 triangles par fleur, contours compris. Une simplification supplémentaire serait utile avant d'afficher de très grandes quantités. La géométrie est interprétée depuis les dessins, pas une reconstruction métrique 1:1.

## Régénération

Lancer Blender avec `--background --python tools/blender/flowers.py` pour les neuf nouvelles fleurs, ou ajouter `-- tulip lily` pour une sélection. La rose conserve son script `tools/blender/rose.py`. Réimporter ensuite dans Godot. La génération vérifie les dimensions et la conservation des positions pendant la consolidation.

La scène `scenes/shop/shot_flower.tscn` présente un modèle sur socle dans la boutique réelle. Arguments : identifiant puis `front`, `back` ou `top`. Pour les 27 captures des neuf nouvelles fleurs en un lancement : ouvrir cette scène avec `-- flower_batch <dossier absolu de sortie>`. La galerie est assemblée avec `tools/blender/package_flowers.py` ; elle recadre les captures sans modifier leur contenu.
