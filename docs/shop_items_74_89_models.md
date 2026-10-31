# Modèles du shop — items 74 à 89

16 modèles métriques natifs, chacun livré en GLB et avec sa source Blender éditable. Ils remplacent leurs anciennes géométries dans la boutique normale. Les illustrations des tapis, des cadres et des couvertures viennent des vues à plat des planches approuvées ; les volumes, reliures, encadrements, supports et attaches sont des maillages 3D. Les textures sont embarquées dans les GLB et les fichiers Blender.

- **74–76 :** tapis et trappe de cave, états secret / fermé / ouvert. Le couvercle est construit avec les mêmes quatre planches et ferrures dans les deux états. L’ouverture est limitée à 80° pour rester devant le mur ouest. Le sol extérieur est découpé au droit du puits pour rendre l’échelle visible. Le déplacement vers la cave conserve l’interaction existante ; le joueur ne tombe pas physiquement dans le trou.
- **77–78 :** paillasson avec lettres en maillage et plaque PRIVÉ en émail, bordure, vis et ornements.
- **79–80 :** étagères de 2 m et 1,50 m, plateaux séparés de leurs contenus. Les huit vases indicateurs et leurs nombres restent synchronisés avec les stocks du jeu. Les panneaux et vases ont une échelle adaptée aux nouveaux meubles. Chaque tablette expose une surface de rangement via O ; les emplacements des indicateurs automatiques sont réservés, et les zones libres peuvent accueillir les objets du joueur. Les deux niveaux conservent 1,15 m d’écartement, avec 1,05 m de dégagement déclaré.
- **81–83 :** tableaux rose, tournesol et fleur xéno. Peinture plane sur UV, moulures, passe-partout, renforts et fil de suspension en volume.
- **84–86 :** livres rose, turquoise et ocre. Couvertures rigides, bloc de pages, nerfs, coiffes, coutures et signet. Ils sont posés sur l’étagère supérieure.
- **87–89 :** rideaux plissés et embrasses, encadrement lumineux du passage et bandeaux lumineux sur trois murs. Les diffuseurs sont orientés vers l’intérieur de la pièce. Les rideaux et l’enseigne restent indépendants de la porte mobile.

## Validation

La scène `scenes/shop/shot_items_74_89.tscn` exécute une partie de contrôle dédiée (`user://review_items_74_89.json`). Elle vérifie réellement la découverte du secret, l’achat de la cave et l’entrée/sortie, puis l’achat, le déplacement et la sérialisation d’un vase sur chacune des deux étagères. Les huit vases de stock sont vérifiés dans la scène installée. Résultats dans `out/items_74_89_review/interaction_checks.json`.

La suite existante a produit **5 960 vérifications réussies, 0 échec**. Elle conserve ses avertissements de sortie déjà présents sur les ressources et le test volontaire de sauvegarde JSON corrompue.

Les captures proviennent directement du viewport Godot en 1920 × 1061 : six vues du décor installé et trois vues de chacun des seize éléments. Pour les présentations individuelles, certains meubles du premier plan sont masqués et les objets sont temporairement placés dans le shop ; ces copies ne sont pas ajoutées à la partie normale. Pour la trappe, les vues montrent les états installés ; pour les néons, les trois angles montrent le système installé.

Reconstruction : `tools/prepare_shop_textures_74_89.py`, puis Blender avec `tools/blender/shop_items_74_89.py`, import Godot, scène de contrôle, et enfin `tools/package_shop_items_74_89.py`.
