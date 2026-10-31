# Fleuriste Galaxy — ville V7

Révision du 31 octobre 2026 à partir du second retour de test. Le nouvel exécutable est `build/windows/Fleuriste-ville-v7.exe`. Les images de contrôle sont dans `out/city_v7/review/index.html`.

## Personnages et étage

Deux nouvelles planches ont été produites avec l’outil intégré **imagegen**. Les références de Noé et Gaston ont été fournies à la génération des habitants. Les prompts complets et les références sont conservés dans `art/concepts/city_v7/prompts.json`.

- `art/concepts/city_v7/residents_sheet.png` : Inès, Lucas et Marcel, vues de face, profil, dos, trois quarts et expressions. Grands yeux blancs, petites pupilles, contours fins, nez et anatomies dans la direction des personnages existants.
- `art/concepts/city_v7/roof_studio_sheet.png` : petite pièce couverte, baie coulissante, auvent, terrasse et détail des acrotères.
- Les trois habitants ont été reconstruits avec le même outillage Blender et le même export de squelette que les personnages existants. Sources éditables : `art/blender/resident_*_v7.blend` et variantes `_toon.blend`. Modèles intégrés : `assets/models/characters/resident_*_v7_toon.glb`. Chacun possède un squelette de 17 articulations ; la marche déforme jambes et bras.
- La pièce de l’étage occupe l’arrière du toit, avec accès à l’escalier et postes d’employés. Une vraie baie s’ouvre par translation sur la terrasse. Les panneaux restent dans la largeur de la façade.
- Parquet intérieur, dallage extérieur, auvent rayé à lambrequin festonné et bras métalliques. Les parapets ont soubassement, panneaux en retrait, pilastres, corniches et garde-corps à anneaux. Trois tablettes de 42 cm sont raccordées au système existant de pose d’objets ; les petits pots peuvent y être achetés et posés.

## Sous-sol, pente et jardin

| Retour | Modification réalisée |
|---|---|
| Tuyaux disjoints, extrémités libres | Cinq conduites continues, coudes arrondis, raccords, brides et suspentes. Les extrémités pénètrent les murs. Deux vannes à volant. |
| Tuyau dans l’escalier | Le détour passe devant l’extrémité de la verrière, au plafond de la cave, sans traverser la rampe. |
| Porte trop étroite et style incorrect | Porte de 1,50 m en acier, dormant, rivets, panneau ventilé, poignée et plaque technique. Collision et interaction suivent le battant. |
| Murs de l’escalier | Brique basse et verrière à montants d’acier, prolongées jusqu’au mur arrière. La finition industrielle s’arrête sous le plafond de la cave. Les murs de la boutique conservent leur finition verte et florale. |
| Virage trottoir-façade vers la pente | Un raccord incliné relie les deux niveaux. Sa collision est un volume convexe continu ; le virage et la remontée ont été parcourus avec le personnage joueur, sans saut. |
| Raccords et textures de chaussée | Un matériau d’asphalte en coordonnées monde et un matériau de dallage communs à la rue principale, aux extensions, à la pente et à la place. Découpes des surfaces aux intersections pour éviter les couches superposées. |
| Trou entre jardin et façade du sous-sol | Habillage porté à la cote du jardin ; prolongement du sol jusqu’au bord, haie déplacée et accès réservé à l’escalier. |
| Façade du sous-sol trop simple | Nervures métalliques sur toute la hauteur, soubassement, ossature, affiches, petites grilles de cave et couvertine métallique. |
| Accès au jardin depuis la ruelle | Escalier en pierre le long du bâtiment, rampe continue de collision et main courante. La circulation de la ruelle conserve un passage libre à côté. |

## Implantation et vie du quartier

Les maisons répétées utilisent désormais des volumes et des ouvertures construits à des dimensions communes. Les 109 volumes principaux sont contrôlés contre les intersections. Les façades visibles sur les côtés et à l’arrière portent aussi fenêtres, corniches, descentes d’eau, lampes murales et, suivant le bâtiment, balcons, pots et végétation grimpante.

| Retour | Modification réalisée |
|---|---|
| Maison jaune encastrée dans la verte | Maison d’angle décalée ; les volumes se raccordent par leurs limites. |
| Portes des maisons sur la pente | Fondations adaptées à la pente, petit palier et marches devant les portes. |
| Jours entre les maisons et jardins de la place | Maisons latérales jointives et prolongement du jardin jusqu’à la maison bleue du bas de la ruelle. |
| Nouveau bâtiment entre immeuble et serre | Maison transversale, porte tournée vers l’immeuble, dos contre la serre déplacée. Le mur mitoyen de la serre reçoit une brique blanche. |
| Angle de la place ouvert sur la limite | Maison longue en brique, façade alignée sur le trottoir, raccordée aux constructions voisines et au sous-sol. Toiture légèrement surélevée par rapport aux maisons basses de la place. |
| Immeuble gris dans la maison bleue | Emprise corrigée ; deux ouvertures superposées de la face concernée sont remplacées par des climatiseurs avec ventilateur, grille, supports et conduites. |
| Jardins sans entrées | Portillons à battants avec collision, interaction et ouverture vers le jardin. Les habitants peuvent les ouvrir lors de leur passage. |
| Place et ruelle piétonne arrière mal reliées | Chemin dallé et bâtiments de fond ; continuité du passage et du sol contrôlée. |
| Arbres sur la route | Arbres reportés sur les trottoirs élargis ; bordures côté chaussée. |
| Sol du niveau zéro visible le long de la descente | Découpe du sol supérieur derrière la rangée de maisons et fondations fermant les pieds de façades. |
| Nouvelle ruelle à gauche du fleuriste | Ruelle entre les maisons rose et violette, façades jointives, immeuble au bord du quartier, balcons, pots, lampes suspendues, plantes grimpantes et vélos adossés aux murs. |
| Routes ajoutées entourées de vide | Fronts bâtis complétés, rangées arrière détaillées séparées par de petites voies piétonnes, bâtiments de fermeture aux extrémités et sols de ces voies. |
| Nouveaux lieux du quartier | Station-service avec pompes, tuyaux et auvent ; épicerie, librairie, café, police, cinéma, casino et parc avec fontaine. Ce sont des décors urbains et façades ; cette révision n’ajoute pas de mini-jeux au cinéma ou au casino. |
| Lampadaires massifs ou mal orientés | Nouveau modèle noir et gris, pied et fût fins, bagues, console, lanterne à cadres et détails autour de l’ampoule. Lanternes orientées vers les routes, poteaux écartés et placés hors des parcours centraux. |
| Poteaux électriques irréalistes | Fûts, traverses, isolateurs, boîtiers et câbles avec flèche entre les poteaux. Plusieurs lignes dans le quartier. |
| Poubelles dispersées | Quatre zones de collecte de quartier avec plusieurs conteneurs ; une seule poubelle utilisable à côté du fleuriste, commune au recyclage et à l’élimination des objets. |
| Ville peu habitée | Affiches, tags, papiers, enseignes dont certaines lumineuses, lampes de façade et plantations. |
| Auvents mal assemblés | Toile continue à la jonction du toit et du lambrequin, festons bordés, barre frontale et bras métalliques triangulés. |
| Vélos identiques ou au milieu du trottoir | Cadres triangulés, rayons, moyeux, selle, guidon, pédales et chaîne ; plusieurs couleurs et pose parallèle aux façades. |
| Voitures et barre de police flottante | Vitrages et joints, essuie-glaces, rétroviseurs, poignées, pare-chocs, plaques, détails de carrosserie. La rampe de police repose sur deux pieds ; antenne affinée. |

Les habitants circulent sur un graphe de 82 points. 68 portes possèdent un raccord valide à ce réseau. Les passants sortent d’une maison et reviennent à cette même porte ; les façades de fond hors des voies publiques servent à fermer le quartier.

Les maisons de fond sont jointives. Les soubassements de soutènement derrière les dernières façades ferment aussi le dessous du niveau zéro, sans couper les chemins publics.

## Performances et reconstruction des ressources

Deux coûts ont été traités : la reconstruction répétée des bâtiments/décors au lancement et la perte des niveaux de détail des modèles lors de leur fusion. Les bâtiments et les accessoires préparés sont livrés en scènes Godot ; les maillages fusionnés possèdent à nouveau des niveaux de détail à distance. Les squelettes et les éléments articulés restent séparés. Le joueur ne calcule pas les simplifications lors du lancement.

Sources : `src/world/city_revision.gd`, `src/world/city_v7.gd`, `src/world/static_merge.gd` et `src/world/shop_collection_visual.gd`. Ressources préparées : `assets/optimized_buildings/v7`, `assets/optimized_props/v7`, `assets/optimized_batches/v7`. Pour les reconstruire après modification des sources : `tools/build_city_v7.ps1`. Le niveau graphique élevé conserve son traitement spécifique ; les scènes préparées livrées ciblent les modes économique et équilibré.

Les mesures détaillées sont dans `out/city_v7/benchmark_with_lods.json` et `benchmark_without_lods.json` : mêmes vues, même ville, 1 440 × 900, synchronisation verticale désactivée, 90 images de chauffe et 240 images mesurées par vue. La comparaison isole les optimisations de cette ville, pas la version précédemment testée par le joueur. Elle ne prédit pas le résultat sur une autre configuration.

## Vérification

- Suite du cœur du jeu : 6 513 assertions réussies, zéro échec. Le test de sauvegarde corrompue produit volontairement un message d’erreur JSON.
- Contrôles V7 : volumes principaux, lampadaires, zones de collecte, voies publiques, marche réelle autour du sous-sol, remontée de la pente, escalier du jardin, nouvelle ruelle, accès au parc, baie coulissante, portillon, pose sur les trois rebords et squelettes des habitants.
- Contrôles de ville précédents : trajets vers les portes, retours à domicile, sols et maintien des ombres intérieures.
- Parcours du jeu vérifié dans une boutique vide puis meublée : escalier du sous-sol, saut, cartons, placement, filtres, véhicules et accès à l’étage.
- Captures Vulkan à hauteur de jeu et vue d’ensemble dans la galerie. L’exécutable est vérifié en mode sans affichage et avec Vulkan depuis un répertoire extérieur au projet.

Les tests utilisent `.runtime/appdata` et des sauvegardes sous `out`. L’ancien exécutable reste disponible et la sauvegarde du joueur n’est pas utilisée pour ces contrôles.

## Résultats chiffrés de livraison

Version autonome : **Fleuriste-ville-v7.exe**, 533.0 Mio, ressources incorporées. Contrôlée depuis `C:\Windows\Temp`, en mode sans affichage puis avec Vulkan.

**6 513 assertions générales et 701 contrôles ciblés réussis, zéro échec.** Les tests des mâchoires de la plante carnivore et de préservation des squelettes passent après la préparation des ressources. Aucun `SCRIPT ERROR` dans les journaux finaux. Les avertissements de certificats Windows et de libération de ressources à la fermeture sont distincts des assertions fonctionnelles.

Mesures sur NVIDIA GeForce RTX 3070 Laptop GPU, 1 440 × 900, mode équilibré :

| Vue | Primitives avant | Primitives après | Réduction | Temps médian avant / après |
|---|---:|---:|---:|---:|
| Devanture | 8,186,436 | 4,698,702 | 42.6 % | 8.88 / 8.96 ms |
| Quartier étendu | 1,162,834 | 687,076 | 40.9 % | 1.70 / 1.71 ms |
| Sous-sol | 6,546,729 | 3,773,705 | 42.4 % | 7.26 / 7.35 ms |
| Nuit | 5,794,510 | 3,381,050 | 41.7 % | 7.64 / 7.77 ms |

Temps de préparation et des premières images mesuré dans ces exécutions : 105.1 s avant, 20.2 s avec les ressources préparées. Les caches de shaders et la charge de la machine peuvent influencer ce temps. La réduction de primitives est reproductible à vue fixe ; les variations de temps médian ne constituent pas une promesse de fluidité sur un autre ordinateur.

Journaux : `out/city_v7/core_final.log`, `checks_final.log`, `legacy_city_final.log`, `traversal_empty.log`, `traversal_furnished.log`, `export_smoke_engine.log`, `export_vulkan_engine.log`. Les captures et les deux planches sont accessibles depuis la galerie. Empreinte de l’exécutable : `build/windows/Fleuriste-ville-v7.json`.
