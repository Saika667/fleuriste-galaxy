# Shop — modèles 3D des planches 54 à 73

20 modèles natifs en mètres, avec sources Blender modifiables et exports GLB. Galerie : `out/items_54_73_review/index.html`. Archive : `out/shop_items_54_73_models_and_renders.zip`.

Les fichiers sont générés par `tools/blender/shop_items_54_73.py`, à partir des briefs et planches dans `art/concepts/shop`. Les anciennes sources des vases 07–14 restent distinctes ; cette série utilise le préfixe `stock_vase_`.

## Intégration

| Items | Modèles et comportement |
|---|---|
| 54 | Guirlande de 9,60 m avec 30 fanions, ourlets, manchons, motifs et attaches ; longueur adaptée aux points d’accroche. |
| 55 | Sol 10 × 8 m en vraies lattes et dalles, jonction en laiton et tapis à motifs. Découpe visuelle conservée à l’emplacement réel de la trappe. |
| 56 | Plafond et quatre poutres, corniche et supports teal/laiton. Hauteur du shop conservée à 5,20 m. |
| 57–58 | Portes vitrées / de service : montants, panneaux, moulures, poignées, serrure et charnières. Vantail mobile et cadre fixe séparés ; interactions et collisions existantes conservées. |
| 59–60 | Suspensions à six lobes, doublure ivoire, douille, ampoule et câble. Éclairage du shop conservé. |
| 61–68 | Huit contenants creux aux profils distincts, avec intérieur et fond. Exemples floraux séparés ; versions vides disponibles. Verre rose à transparence modérée pour conserver sa lisibilité. |
| 69 | Crâne avec orbites réellement creusées, ouverture pour les tiges, nez, dents, pommettes et fond stable ; rose séparée. |
| 70 | Cadran gradué et numéroté, aiguilles indépendantes, boîtier et couvercle de pile. Les aiguilles suivent l’heure du jeu. |
| 71 | Enseigne double face, moulures, chaînes et attaches ; texte vivant OUVERT / FERMÉ. |
| 72 | Tableau de file, cadre et emplacement des chiffres séparés. Nombre lié aux clients réels, sans inscription fixe « 02 » dans la géométrie. |
| 73 | Pot en terre cuite avec bande botanique, trois cordes et anneau, terre, couronne de feuilles et huit tiges retombantes ramifiées. |

Les huit nouveaux vases figurent aussi dans le rangement des étagères via **O**, sous des noms de forme/couleur plutôt que des noms verrouillant une espèce. Le joueur peut les acheter, les déplacer et les tourner sur les surfaces compatibles. **V** permet d’y choisir les fleurs ; une composition mixte est autorisée. Les vases automatisés des étagères de stock conservent leur fonction d’indicateurs d’inventaire.

Le grand sol et le plafond sont des ensembles architecturaux, adaptés à l’agencement réel plutôt qu’à une interprétation littérale des vignettes. Les ornements utilisent des reliefs simples et des matériaux unis pour rester dans la direction cartoon. Les objets statiques sont regroupés par le moteur ; les articulations et affichages dynamiques restent indépendants.

## Rendus et contrôle

La scène `scenes/shop/shot_items_54_73.tscn` charge la vraie boutique. Elle prend 68 captures : vues générales, face et dos des vingt références, vases vides et vus du dessus, portes ouvertes, dessous des suspensions et états des affichages. Les petits objets sont temporairement présentés sur l’établi ou dans l’allée ; les éléments architecturaux sont photographiés en place. Aucun rendu n’est une image générée ou une retouche d’une capture.

La scène utilise une partie de contrôle et ne remplace pas la sauvegarde joueur. Elle vérifie l’ouverture des deux portes avec leur interaction existante, le suivi de l’horloge, les états de l’enseigne, un nombre de clients, l’achat et le rechargement d’un nouveau vase, ainsi que le mélange rose/tulipe dans le vase xéno. Résultats dans `out/items_54_73_review/interaction_checks.json`.

Les tests `tests/test_shop_collection_54_73.gd` vérifient les vingt chargements, la séparation cadre/vantail, les aiguilles après optimisation, les positions des détails devant le cadran, le pot sous son crochet et la modification des compositions des huit vases. Les avertissements de libération de ressources à la fermeture du runner préexistaient à cette série ; ils sont distincts des résultats des assertions.

Suite complète validée : **5 945 assertions réussies, zéro échec**. Le test de sauvegarde volontairement corrompue produit aussi un message JSON attendu ; les logs de la scène de capture doivent, eux, rester sans erreur de script.

Régénération : Blender en arrière-plan avec `tools/blender/shop_items_54_73.py`, import Godot, tests `tests/run_tests.gd`, lancement de `scenes/shop/shot_items_54_73.tscn`, puis `tools/package_shop_items_54_73.py`.
