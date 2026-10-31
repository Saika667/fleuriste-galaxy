# Révision de la ville — 31 octobre 2026

Cette révision répond au retour de test fourni dans « Texte collé.txt ». Le jeu reste un projet Godot 4.7.2 ; les nouveaux éléments sont de véritables géométries 3D.

## Boutique, jardin et sous-sol

| Retours | Changements |
|---|---|
| Papier peint qui dépasse, clignotements latéraux et encadrement droit | Papier peint opaque, visible du côté intérieur, séparation du cadre de service et du lambris. Dans l’annexe, le motif est limité à la hauteur réelle de 3,2 m. |
| Parois et jonctions de l’escalier | Habillage vert et floral sur les faces visibles depuis la boutique, y compris le linteau. Le conduit contourne la cage d’escalier. |
| Enseigne et couleurs de devanture | Enseigne en bois peint « FLEURISTE », lettres claires, cadre et deux supports d’éclairage en laiton ; palette sauge et pierre. |
| Auvents de la boutique et de la boulangerie | Pente, bandes de toile, lambrequin continu, traverses et bras métalliques mesurés. |
| Terrasse sur la route, barrière latérale | Chaussée décalée et élargie à 8 m, trottoir de boutique élargi ; seule la rambarde côté rue est conservée. |
| Parasol | Nouveau modèle à dix panneaux courbes, coutures, baleines, entretoises, mât, bague et pied lesté. |
| Sous-sol industriel et bande blanche | Enveloppe en béton, tôle nervurée, montants d’acier et soubassement bas. Deux soupiraux grillagés par élévation latérale, affiches vieillies aux bords irréguliers. L’élévation côté pente atteint le bord du trottoir. |
| Culture extérieure et lampes suspendues | Bac et cultures déplacés dans le sous-sol ; lampe fixée au bac. Ancienne ampoule extérieure isolée supprimée. |
| Serre, porte trop large et passage derrière | Serre jointe au mur arrière, porte ramenée à environ 1,35 m, panneau fixe vitré et collisions adaptés. Sol intérieur dallé ; découpe de la pelouse recalée. |
| Fenêtres basses arrière du fleuriste | Supprimées. |
| Étage et vue extérieure | Terrasse ouverte devant et côté ruelle, parapets et garde-corps ; ouvertures vitrées réelles à l’arrière et à l’ouest. Suppression des murs et de la toiture qui masquaient la vue. |
| Composteur | Planche de référence générée, nouveau modèle à lattes, yeux, pupilles, sourcils, bouche et dents, couvercle articulé, ferrures et trappe. Placé sur le bord du jardin, près du point d’eau. Interaction et compost conservés. |

## Ville et circulation

| Retours | Changements |
|---|---|
| Raccord place / pente, trous et sols superposés | Découpe réelle du sol de la place autour de la pente ; profils visuels et collisions alignés. Découpe du trottoir principal prolongée jusqu’au nouveau bord de chaussée. |
| Trottoirs dans les jardins, clôtures détachées | Cheminements publics replacés hors des parcelles ; clôtures prolongées jusqu’aux façades et dimensions des jardins latéraux recalées. |
| Immeuble de la place, arrière-plan répétitif | Immeuble contigu à la rangée de maisons ; nouveaux immeubles à baies larges, balcons pleins ou métalliques sur plusieurs faces, terrasses et volumes de toiture différents. |
| Ruelle piétonne et éloignement du fond | Bande pavée de 5 m entre les maisons et les immeubles du fond ; vélos détaillés, bacs municipaux, poteaux et petits déchets. |
| Maison d’angle et maison jaune | Fondation prolongée sous la maison d’angle ; élévations latérales et arrière conservées en volume. Bâtiment jaune reculé hors de l’emprise de la pente. Plaque « RUELLE DES ÉRABLES » à l’angle. |
| STOP et lampadaire dans l’intersection | Ligne et panneau déplacés sur l’autre voie ; lampadaire dégagé de l’emprise de la ruelle. |
| Lampadaires | Modèle complété par colliers moulurés, consoles en volute, croisillons de lanterne et fleuron. |
| Voitures | Pare-brise extérieur à la carrosserie, lunette arrière, joints, essuie-glaces, rainures de portes, baguettes et calandre. Les roues existantes restent animées. |
| Route trop courte, apparition des voitures | Route prolongée, deux rues perpendiculaires, virages arrondis réellement suivis par les véhicules et bâtiments de fermeture au-delà des intersections. |
| Bâtiments supplémentaires et identités des services | Entrepôt de prêt, ambassade galactique, salon interstellaire et galerie macabre répartis à quatre adresses. Volumes, panneaux, quais, drapeaux, auvent et présentoirs distincts. |
| Feuillages presque transparents | Feuilles opaques sur leurs deux faces, canopées plus denses et haies épaissies. Feuilles d’érable de couleurs vertes, jaunes, orange, rouges et brunes au sol ; mousse, brins courbés et petites marguerites dans les pieds d’arbres. |
| Habitants et vie de quartier | Trois nouveaux modèles humains d’après la planche. Réseau de promenade reliant rue principale, rues latérales, pente, place et ruelle piétonne. Chaque passant résident sort d’une porte, parcourt la ville puis rentre par sa propre porte ; ouverture et fermeture animées, disparition derrière la façade. Population simultanée limitée à huit. Les accès du joueur ne servent pas de domicile. |

Les résidents décoratifs ne remplacent pas les files de clients, l’économie, les employés ou les arrivées scénarisées du jeu.

## Performances

Le relevé initial de la scène chargée compte **15 681 699 triangles**, **5 847 MeshInstance3D** et **2 602 passes de contour**. Ce total comprend aussi des objets masqués ; ce n’est pas le nombre de triangles affichés à chaque image.

Les corrections portent sur le papier peint transparent, les contours décoratifs en qualité équilibrée, la réutilisation des géométries préparées, les formes planes sans arrondi inutile et la prise en charge des modèles à plusieurs surfaces dans le regroupement des maillages. Les bâtiments, murs et plafonds reçoivent des volumes d’occlusion. Les accessoires du sous-sol ne projettent plus d’ombres lorsqu’on reste à l’extérieur, y compris sur la place basse : la hauteur du joueur ne suffit plus à réactiver ces ombres. Les murs et plafonds restent structurels. Les personnages à squelette sont exclus du découpage des surfaces.

La ville agrandie contient davantage d’objets. La réduction du nombre d’objets de toute la scène n’est donc pas utilisée comme mesure d’un gain de fluidité. Les relevés de rendu par vue sont dans les journaux de captures. Les fréquences d’image dépendent de la machine, du point de vue et de la compilation initiale des shaders.

## Références et sources

- Planche : `art/concepts/city_v6/composter_residents_sheet.png`.
- Prompt et provenance : `art/concepts/city_v6/prompt.txt`.
- Modèles éditables : `art/blender/city_v6/`.
- Exports utilisés par le jeu : `assets/models/city_v6/`.
- Reconstruction : `tools/blender/city_v6.py` et `tools/blender/city_v6_environment.py`.
- Architecture et aménagement : `src/world/city_revision.gd`.
- Promenades : `src/world/crossing_walkers.gd`.

## Vérifications

Les tests utilisent `.runtime/appdata` et des sauvegardes de contrôle sous `out/city_v6`, sans écrire dans la sauvegarde du joueur.

- **6 513 assertions de la suite générale : 0 échec**, aucune erreur de script (`out/city_v6/core_final.log`).
- **215 contrôles de la ville : 0 échec**, accès aux 48 maisons enregistrées, 67 points de cheminement, retours complets à domicile et marche sur la pente (`out/city_v6/checks_final.log`).
- **114 contrôles de parcours et d’interaction : 0 échec**, boutique vide et meublée, six étapes réelles sur l’escalier du sous-sol, saut, cartons, placement et étage (`out/city_v6/traversal3.log`, `out/city_v6/traversal_furnished.log`). Les anciennes coordonnées des outils de contrôle ont été mises à jour pour correspondre au véritable escalier et au nouveau composteur ; le verrouillage de l’étage est testé explicitement hors du mode de visite.
- **25 captures Vulkan** vérifiées dans `out/city_v6/review/index.html` ; la vue de l’escalier est recadrée depuis son axe réel.
- **Exécutable autonome testé depuis un autre répertoire**, en mode sans affichage puis avec rendu Vulkan : catalogue de 257 références, onze extensions, commandes, meubles, placement et sous-sol persistant. Journaux `out/city_v6/export_smoke_engine.log` et `out/city_v6/export_vulkan_engine.log`.
- `git diff --check` : aucune erreur d’espacement.

Sur les mêmes points de vue de cette révision, entre le premier contrôle Vulkan et le contrôle final, les appels de dessin passent de **3 150 à 2 780** devant la boutique, de **1 951 à 1 311** dans la boutique et de **3 292 à 2 721** dans le sous-sol. Il s’agit d’une comparaison entre deux étapes de cette révision, pas d’un benchmark de la version initialement testée par le joueur. La scène est plus grande et le feuillage plus dense ; les compteurs de triangles ne baissent pas partout.

Le pilote Windows signale un avertissement de lecture du magasin de certificats au démarrage ; les contrôles ci-dessus vont néanmoins à leur terme. Aucun accès réseau n’est nécessaire pour jouer.

## Version à lancer

`build/windows/Fleuriste-31-octobre.exe` — exécutable Windows autonome, ressources incorporées (396.1 Mio). Métadonnées et empreinte SHA-256 : `build/windows/Fleuriste-31-octobre.json`.

La sauvegarde du joueur et l’ancien exécutable restent disponibles. La galerie et le rapport permettent de revoir les modifications sans lancer le jeu.
