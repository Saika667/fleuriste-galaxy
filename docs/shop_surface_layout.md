# Shop : modèles et rangement des surfaces

Les modèles Blender et GLB révisés sont produits par `tools/blender/shop_items_14_33.py`, avec les détails dans `shop_revision_details.py`. Le lierre suit la planche 23 : pot en terre cuite, soucoupe, bande crème et turquoise, couronne de feuilles lobées et six lianes distinctes.

Le plafond mesure 5,20 m. Les niveaux des étagères sont espacés de 1,15 m. Trois modèles d'étagère existent : 5,60 m, 2,40 m et 1,20 m. L'auvent est relevé de 48 cm.

## Utilisation

Appuyer sur O, ou sur E devant le présentoir, pour ouvrir le rangement. Choisir une surface, cliquer dans le plan ou saisir les positions en centimètres, puis régler la rotation. Acheter et poser ajoute un objet ; déplacer un objet possédé ne coûte rien. La réserve conserve les objets et les compositions florales. Le menu Vases permet de choisir leurs fleurs.

Les positions sont continues et sauvegardées. Le placement vérifie les bords, les chevauchements et la hauteur disponible. Les indicateurs du stock gardent leur place réservée. Un présentoir personnalisé utilise les objets du joueur ; les bouquets préparés restent dans le stock.

## Persistance et validation

`surface_layout` sauvegarde les objets avec identifiant stable, modèle, surface, position, angle et échelle. La composition d'un vase utilise `layout|<identifiant>` et suit le vase lorsqu'il est déplacé. Une surface supprimée renvoie les objets dans la réserve.

`tests/test_surface_layout.gd` couvre les achats, collisions, déplacements, réserve, sauvegarde et conservation des fleurs. Suite complète : 5828 assertions réussies, aucune en échec. Le moteur signale encore des ressources utilisées à la fermeture du lanceur de tests.

`shot_shop_revisions.tscn` réalise des achats via le menu, déplace un vase rempli, vérifie la sauvegarde/relecture et produit 16 captures réelles. Cette scène utilise une partie de contrôle et ne modifie pas la sauvegarde du joueur.
