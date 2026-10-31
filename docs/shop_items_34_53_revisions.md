# Corrections des items 34–53

## Modèles et compositions

- Affiches 34 et 47 : illustrations imprimées intégrées dans les GLB et les fichiers Blender. Le tableau de bouquet utilise une nature morte peinte ; l'avertissement reprend le lettrage décoratif épais et les motifs de la planche. Les textures sont dans `assets/textures/shop` ; les prompts imagegen sont conservés dans `art/concepts/shop/poster_art_revisions.json`.
- Six seaux natifs : sept fleurs au lieu de dix, têtes plus espacées et variations discrètes de hauteur et de taille. Les étiquettes utilisent Arial gras et ne comportent plus de prix. Les deux autres seaux du décor utilisent également une composition plus espacée et des étiquettes en gras.
- Étagères 39 et 51 : longueurs natives de 1,50 m et 2 m, sans étirement des supports. Les objets décoratifs du shop sont replacés dans leurs nouvelles limites. Pour les captures, chaque étagère est montrée seule sur un panneau de contrôle temporaire dans le shop ; ce panneau ne fait pas partie du modèle.
- Cageot fleuri : tiges réduites. Bulbes : corps en goutte, enveloppes marquées, pointes et petites pousses, racines reposant sur la paille.
- Gradins : panneaux latéraux pleins sculptés pour la variante 1 ; trois véritables ouvertures en forme de feuille pour la variante 3. Les plateaux restent accessibles et éditables. Le rangement n'utilise pas d'emplacements imposés.
- Plante carnivore : langue rose avec sillon central, attachée à la mâchoire inférieure, conservant les dents triangulaires et l'ouverture animée.
- Cercueil : côtés diagonaux plus grands, panneaux encadrés, moulures continues, sangles et coiffes d'angle, poignées articulées visuellement, pieds et feuillage débordant. Trente fleurs sont assemblées séparément au-dessus du terreau.
- Suspension : petites ramifications, feuilles supplémentaires de tailles et orientations variées.

## Rangement et sauvegarde

O ouvre le placement ; V compose les vases. Les coordonnées se règlent au millimètre et la rotation au degré. Les objets devenus trop grands ou hors limites après le raccourcissement d'une étagère rejoignent la réserve sans perdre leur composition florale.

La scène de contrôle achète deux vases via le menu de chacun des deux gradins, déplace un vase rempli, vérifie l'absence de coût du déplacement puis sauvegarde et relit positions et fleurs. Elle utilise une partie de contrôle, sans écraser la sauvegarde du joueur.

Suite complète : 5887 assertions réussies, zéro échec. Le lanceur signale encore ses ressources utilisées à la fermeture. Les vérifications supplémentaires couvrent les textures intégrées, les longueurs natives et la conservation des fleurs après réduction d'une surface.

Les sources de géométrie sont dans `tools/blender/shop_items_34_53.py` et `shop_items_34_53_revision.py`. Les sources Blender restent dans `art/blender/shop`, les GLB dans `assets/models/shop`.

Galerie de contrôle : `out/items_34_53_revision_review/index.html` — 55 captures réelles, dont les profils et meubles vides des deux gradins et leurs menus de rangement.
