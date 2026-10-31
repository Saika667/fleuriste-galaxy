# Sous-sol — directives de modélisation et d’intégration

## Portée

44 planches de concepts, générées avec l’outil intégré image_gen, couvrent les 145 références hors murs du catalogue et les ajouts demandés. Une famille partage sa planche entre exemplaires identiques, accessoires et stades : ce ne sont pas 145 nouveaux modèles indépendants. Les murs 001 à 004 gardent leur aspect actuel. Les fichiers du jeu jouable ne sont pas modifiés par cette livraison de concepts.

## Plan de référence

La planche 01 définit le zonage proposé : 24 × 18 m, hauteur 3,80 m, contre 10 × 8 × 3 m dans la scène actuelle. Le jeu conservera la texture et le style des murs existants lors de l’extension. L’escalier débouche au sud-ouest ; vente et porte visiteurs au sud-est ; stockage à l’est ; service et compost à l’ouest ; grands bacs au nord et pots individuels au centre. Allée principale de 2 m et passages dégagés à vérifier avec le contrôleur joueur et les visiteurs lors de l’intégration. Quatre bacs et huit pots sur le plan sont des exemples de placement, pas une limite de capacité du jeu. Les vues d’ambiance des autres planches sont illustratives ; ne pas en reprendre les implantations divergentes. Corriger la seconde étiquette A de l’axonométrie 01 en B lors de la réalisation.

## Deux aérations et filtres de jeu

Exactement deux bouches A et B au plafond, reliées par des conduits métalliques argentés, avec un logement distinct pour une cartouche de filtre à charbon amovible sur chacune. Planche 02 pour l’assemblage au plafond, planche 03 pour la géométrie détaillée du kit et ses états. Créer une seule géométrie maîtresse de bouche et la dupliquer pour A et B : les différences de forme dessinées entre vues ne créent pas de troisième modèle. Aucun soupirail ou accès d’égout ne compte comme bouche supplémentaire.

Prévoir des points d’interaction accessibles au joueur pour les cartouches (emplacement vide / cartouche installée / remplacement). Les états visuels doivent pouvoir suivre les règles de jeu : absence ou inefficacité du filtre → odeur perceptible côté boutique → réaction des clients et risque d’alerte de la police. Ces interactions et règles restent à réaliser et à tester dans le jeu lors de l’intégration des nouveaux modèles. Le schéma est une fiction de gameplay, sans dimensionnement d’une installation réelle.

## Culture et placement

Les pots individuels n’acceptent qu’un seul pied chacun, via un point central unique. Pot, soucoupe, terre, plante et étiquette sont des pièces distinctes. La lampe individuelle est un objet autonome, de taille adaptée au pot, avec un socle stable ; la rampe des grands bacs reste un autre modèle. Les pots et lampes du plan 01 sont des silhouettes de placement : utiliser les planches 43 et 44 pour leurs formes définitives.

La version corrigée de la planche 44 remplace le brouillon miniature : pot de 0,48 m de diamètre et 0,42 m de hauteur, lampe sur pied de 1,40 à 2,20 m, base de 0,85 × 0,80 m et ouverture intérieure de 0,60 m. Ce sont des cotes de maillage pour le jeu. Le brouillon initial n’est pas une référence d’intégration.

Pour l’herbe sombre, réutiliser et adapter les géométries et animations cartoon existantes du cannabis dans assets/models/plants/cannabis_*_toon.glb. La planche 38 guide la palette sombre et la cohérence des quatre états, sans reconstruire inutilement les six variétés déjà produites. Conserver les feuilles nombreuses et les petites ramifications. Les stades doivent partager la même origine de tige pour l’animation de croissance. Lotus, mousse et liane ont leurs stades dédiés.

## Objets et lisibilité

Armoire 13 : retenir une hauteur cible de 1,80 m (largeur 1 m, profondeur 0,45 m) pour rendre cohérents les deux dégagements intérieurs de 0,60 m et le rangement inférieur ; la cote 1,20 m imprimée dans l’illustration est à corriger lors de la modélisation.

Étagères et comptoirs : surfaces libres, accessoires non fusionnés, supports et dégagements réels ; le joueur doit pouvoir disposer les objets. Bocaux : contenu posé au fond, couvercle séparé. Cisailles : deux boucles, un pivot et de vraies lames. Toute écriture finale doit être composée dans Godot/Blender avec une vraie police pour corriger les imperfections éventuelles des lettres dans les concepts. Les cotes des images sont des propositions ; les dimensions contradictoires d’une vue à l’autre sont à résoudre avec le plan de référence et les collisions. Aucun effet de lumière dessiné n’est une géométrie solide.

## Correspondance avec le catalogue

| Réf. catalogue | Élément | Planche(s) |
|---|---|---|
| 001 | Mur en pierre — panneau 4 | Murs conservés — pas de nouvelle planche |
| 002 | Mur en pierre — panneau 3 | Murs conservés — pas de nouvelle planche |
| 003 | Mur en pierre — panneau 2 | Murs conservés — pas de nouvelle planche |
| 004 | Mur en pierre — panneau 1 | Murs conservés — pas de nouvelle planche |
| 005 | Plafond en pierre | 02 |
| 006 | Sol en pierre | 04 |
| 007 | Poutres du plafond | 02 |
| 008 | Plinthes sombres | 04 |
| 009 | Ampoules et fils de suspension | 07 |
| 010 | Escalier et accès boutique | 05 |
| 011 | Pancarte de l’accès à la boutique | 06 |
| 012 | Bocaux sur le rebord — variante 1 | 09 |
| 013 | Truelle — variante 1 | 10 |
| 014 | Arrosoir — variante 1 | 10 |
| 015 | Étiquette du bac — variante 1 | 09 |
| 016 | Câble et multiprise — variante 1 | 11 |
| 017 | Seau au sol — variante 1 | 10 |
| 018 | Bocaux sur le rebord — variante 2 | 09 |
| 019 | Truelle — variante 2 | 10 |
| 020 | Cisailles — variante 2 | 10 |
| 021 | Étiquette du bac — variante 2 | 09 |
| 022 | Câble et multiprise — variante 2 | 11 |
| 023 | Bocaux sur le rebord — variante 3 | 09 |
| 024 | Truelle — variante 3 | 10 |
| 025 | Arrosoir — variante 3 | 10 |
| 026 | Étiquette du bac — variante 3 | 09 |
| 027 | Câble et multiprise — variante 3 | 11 |
| 028 | Seau au sol — variante 2 | 10 |
| 029 | Bocaux sur le rebord — variante 4 | 09 |
| 030 | Truelle — variante 4 | 10 |
| 031 | Cisailles — variante 4 | 10 |
| 032 | Étiquette du bac — variante 4 | 09 |
| 033 | Câble et multiprise — variante 4 | 11 |
| 034 | Ensemble des quatre terminaux d’amélioration | 12 |
| 035 | Chemin de câbles et enseigne AMÉLIORATIONS | 11 |
| 036 | Armoire à produits | 13 |
| 037 | Composteur animé | 14 |
| 038 | Comptoir clandestin, sonnette et enseignes | 15 |
| 039 | Bocal de transaction et pièces | 15 |
| 040 | Porte des visiteurs et enseigne ENTRÉE DISCRÈTE | 16 |
| 041 | Caisse de graines | 17 |
| 042 | Bouche d’égout et décor | 18 |
| 043 | Squelette de l’ancien associé et sa pancarte | 19 |
| 044 | Barils et caisse du coin nord-est | 29 |
| 045 | Conduites du plafond et colliers | 03 |
| 046 | Flaque au sol | 04 |
| 047 | Soupirail grillagé | 22 |
| 048 | Affiche INTERDIT AUX FLICS | 34 |
| 049 | Guirlande lumineuse multicolore | 07 |
| 050 | Étagère de cinq bocaux et pancarte NE PAS BOIRE | 23 |
| 051 | Vanne rouge | 20 |
| 052 | Boîte à fusibles, diode et panneau haute tension | 21 |
| 053 | Marches patinées, nez de marche et clous | 05 |
| 054 | Rampe d’escalier en bois | 05 |
| 055 | Lanterne suspendue | 08 |
| 056 | Lanterne de l’escalier | 08 |
| 057 | Bottes oubliées et pancarte de la 7e marche | 06 |
| 058 | Conduites cuivre et turquoise du mur est | 20 |
| 059 | Colonne de tuyau et vanne rouge | 20 |
| 060 | Conduite rouillée du mur sud | 20 |
| 061 | Tuyau vertical au-dessus du seau | 20 |
| 062 | Étagère murale | 24 |
| 063 | Canard décoratif | 25 |
| 064 | Grille-pain | 25 |
| 065 | Bombe cartoon décorative | 26 |
| 066 | Bananes dorées | 26 |
| 067 | Étagère murale — exemplaire 2 | 24 |
| 068 | Bocal à poisson | 27 |
| 069 | Casque spatial sous cloche | 27 |
| 070 | Tasse crâne | 28 |
| 071 | Mini-fusée | 28 |
| 072 | Étagères garnies du mur sud et pancarte OBJETS TROUVÉS | 24 |
| 073 | Étagère murale — exemplaire 3 | 24 |
| 074 | Mini-lune | 28 |
| 075 | Canard décoratif — exemplaire 2 | 25 |
| 076 | Grille-pain — exemplaire 2 | 25 |
| 077 | Étagère murale — exemplaire 4 | 24 |
| 078 | Bombe cartoon décorative — exemplaire 2 | 26 |
| 079 | Tasse crâne — exemplaire 2 | 28 |
| 080 | Bananes dorées — exemplaire 2 | 26 |
| 081 | Étagères garnies du mur est et pancarte ZONE DE CONTREBANDE | 24 |
| 082 | Caisse de contrebande | 29 |
| 083 | Caisse de contrebande — exemplaire 2 | 29 |
| 084 | Pile de caisses FRAGILE et CE CÔTÉ VERS LE HAUT | 29 |
| 085 | Caisse de contrebande — exemplaire 3 | 29 |
| 086 | Caisse de contrebande — exemplaire 4 | 29 |
| 087 | Caisses ÉCHANTILLONS et SOUPE DE FLICS | 29 |
| 088 | Tonneau cerclé | 30 |
| 089 | Tonneau vert et pancarte SIROP | 30 |
| 090 | Bidons rouge et jaune, sacs en toile | 30 |
| 091 | Lanterne suspendue — exemplaire 2 | 08 |
| 092 | Lanterne suspendue — exemplaire 3 | 08 |
| 093 | Lanterne suspendue — exemplaire 4 | 08 |
| 094 | Champignon lumineux | 31 |
| 095 | Champignon lumineux — exemplaire 2 | 31 |
| 096 | Champignon lumineux — exemplaire 3 | 31 |
| 097 | Champignon lumineux — exemplaire 4 | 31 |
| 098 | Champignon lumineux — exemplaire 5 | 31 |
| 099 | Champignon lumineux — exemplaire 6 | 31 |
| 100 | Champignon lumineux — exemplaire 7 | 31 |
| 101 | Champignon lumineux — exemplaire 8 | 31 |
| 102 | Champignon lumineux — exemplaire 9 | 31 |
| 103 | Champignon lumineux — exemplaire 10 | 31 |
| 104 | Groupe de champignons lumineux | 31 |
| 105 | Mousse lumineuse au pied du mur | 31 |
| 106 | Corde de séchage, bouquets suspendus et pancarte | 32 |
| 107 | Chat endormi | 33 |
| 108 | Radio et pancarte SIESTE | 33 |
| 109 | Affichettes TARIFS et moyens de paiement | 34 |
| 110 | Paillasson BIENVENUE (non) | 35 |
| 111 | Colis empilés TERRE et HAUT | 29 |
| 112 | Pot fleuri destiné au compost | 35 |
| 113 | Ventilation et espace | 03 |
| 114 | Lampes de culture | 12 |
| 115 | Filtre a odeurs | 03 |
| 116 | Serrure blindee | 12 |
| 117 | Bac de culture 1 — cannabis | 36 |
| 118 | Rampe de culture — bac 1 | 37 |
| 119 | Herbe sombre — pousse | 38 |
| 120 | Herbe sombre — croissance | 38 |
| 121 | Herbe sombre — bourgeonnement / croissance avancée | 38 |
| 122 | Herbe sombre — maturité | 38 |
| 123 | Bac de culture 2 — xeno_lotus | 36 |
| 124 | Rampe de culture — bac 2 | 37 |
| 125 | Lotus xéno — pousse | 39 |
| 126 | Lotus xéno — croissance | 39 |
| 127 | Lotus xéno — bourgeonnement / croissance avancée | 39 |
| 128 | Lotus xéno — maturité | 39 |
| 129 | Bac de culture 3 — gloom_moss | 36 |
| 130 | Rampe de culture — bac 3 | 37 |
| 131 | Mousse de gouffre — pousse | 40 |
| 132 | Mousse de gouffre — croissance | 40 |
| 133 | Mousse de gouffre — bourgeonnement / croissance avancée | 40 |
| 134 | Mousse de gouffre — maturité | 40 |
| 135 | Bac de culture 4 — star_vine | 36 |
| 136 | Rampe de culture — bac 4 | 37 |
| 137 | Liane d'étoile — pousse | 41 |
| 138 | Liane d'étoile — croissance | 41 |
| 139 | Liane d'étoile — bourgeonnement / croissance avancée | 41 |
| 140 | Liane d'étoile — maturité | 41 |
| 141 | Bocaux de produits récoltés — qualités 1 à 4 | 42 |
| 142 | Serrure, renforts et diodes de l’armoire — niveau 3 | 13 |
| 143 | Caisse enregistreuse | 15 |
| 144 | Pot à pourboires | 15 |
| 145 | Pancarte de sortie d’égout | 18 |
| 146 | Champignons de la bouche d’égout | 18 |
| 147 | Tuyau d’égout qui goutte | 18 |
| 148 | Cône de chantier | 18 |
| 149 | Salissures, mousse et halos de lumière — surfaces décoratives | 04 |

## Briefs de production complets

### 01 — Plan du sous-sol agrandi

Top-down orthographic master floor PLAN plus roofless axonometric of proposed expanded basement 24m x18m x3.8m high, replacing old10x8m footprint. SAME existing grey stone wall appearance, do not redesign walls. Clearly distinct accessible zones: stairs/shop entry southwest, discreet selling counter and visitor entrance southeast, lockable stock and packing along east, compost/service west, four reusable large grow beds north, generous center area with eight individual single-plant pots and separate dedicated lamps. Wide unobstructed circulation, 2m central aisle. Reflected ceiling inset shows EXACTLY TWO ceiling ventilation grilles A and B at west/east positions connected by silver METAL ducts; each grille has a removable game charcoal-filter cartridge slot. Illustrative layout only, no cultivation instructions. Show empty/modular player placement option and scale ruler. No third grille. Title PLAN DU SOUS-SOL AGRANDI.

### 02 — Plafond, poutres et deux aérations

Complete reflected ceiling plan24x18m, underside axonometric and side section at3.8m height. Existing warm grey masonry palette, timber beams with iron brackets. EXACTLY TWO large ceiling grilles A and B, connected by a visible modular SILVER metal duct run; each supports one detachable charcoal-filter game cartridge underneath. Diagram one slot empty and the other occupied but total TWO grilles. Clear suspension plates for lamps, no low pipes across paths. All components isolated in lower detail panels. No walls.

### 03 — Bouches, conduits métalliques et filtres amovibles

Fictional game ventilation kit: EXACTLY TWO companion ceiling grilles A and B, silver metallic duct assembly connecting them. Removable dark charcoal-filter game cartridge for each grille: cartridge, empty receptacle, insertion arrow, latched installed state. Mechanically readable brackets and flange connections, detachable90degree elbows, straight module, T-free direct connecting pipe. Two-grille system diagram and clear orthographic views of grille/filter. Add small scent-cloud and florist/police alert pictograms for fictional game state only, not explanatory instructions. No third vent, no real ventilation calculations. Modules sized visually for24x18m proposed cellar.

### 04 — Sol, plinthes et patine

Modular cellar floor kit in dark muted stone slabs, broad stylized grout, beveled edge, wood threshold strip, stone plinth with dark base. 1x1m repeatable tile, corners, broad24x18m top plan without walls, side thickness. Separate flat decal atlas for damp stain, subtle moss patches, small puddle edge and lamp light pool. Keep walkable floor level, no raised random rocks. Controlled cartoon surfaces rather than noisy realism.

### 05 — Escalier, marches et rampe

Sturdy wooden stairs connecting3.8m cellar ceiling level to floor, warm worn treads, iron fixing plates, continuous solid handrail, clear headroom and landing. Front/back/side/top and axonometric with stringers, tread nose/nails details; no floating disconnected steps. Separate staircase/handrail/landing modules. Match current identity, refined cartoon craftsmanship. Geometry schematic, verify stair measurements in later3D integration.

### 06 — Pancartes d’accès et bottes oubliées

One family sheet: shop access wooden arrow plaque with short text BOUTIQUE and botanical symbol, small humorous seventh-step ATTENTION plaque, pair of worn work boots with folded leather cuffs and mud soles. Each prop front/back/profile and3/4; signs on actual brackets, boots rest flat with shaped soles and laces. Warm wood/ochre/olive; professional lettering.

### 07 — Ampoules et guirlande multicolore

Two modular lighting props: warm hanging bare bulb with dark braided cable, ceramic socket and ceiling rose; multicolored small-bulb string with convincing sockets, modest slack cable and two anchored hooks. Front/back/side/underside and3/4; bulb/socket closeup, separate cable module; moderately luminous without overwhelming outlines. Show off/on state.

### 08 — Lanternes du sous-sol

Single cohesive hanging lantern family with staircase wall bracket variant, slender dark wrought metal cage, amber glass panes, warm bulb, iron cap and suspension loop. Front/back/profile/top/underside and3/4, glass and bulb separate. One short and one tall lantern variant, same style, hanging anchor detail. Not extreme bloom.

### 09 — Bocaux de culture et étiquettes

Small reusable jars on grow-bed rim and detachable bed labels, four subtle material/color variants. Short chunky clear glass jar with heavy base, separate twist lid and colored fictional contents; empty and filled version. Small clip-on ivory label holder, blank replaceable icon face. Main front/back/side/top and3/4, lid underside and real clip closeup. Objects independent, no floating contents. Labels editable, no permanent specific crop inscription.

### 10 — Truelles, cisailles, arrosoirs et seaux

Four separate practical cartoon props: pointed concave steel trowel with olive wooden handle; real recognizable bypass pruning scissors with TWO oval finger loops, pivot screw and opposed curved steel blades; squat galvanized watering can with closed body/open fill hole, arched handle and long spout/rose; stout metal bucket with hinged wire handle and rolled lip. Each has front/profile/back or top and3/4, large tool mechanics closeups. Matching teal/ochre/dark steel palette, refined silhouettes, never ambiguous sticks.

### 11 — Câbles et multiprises

Game electrical accessory kit: chunky power strip with real recessed sockets, rocker switch, grounded plug; flexible dark cable, wall/ceiling cable tray with metal clips, separate small AMÉLIORATIONS sign. Front/back/side/top of strip, rear mounting slots,3/4, coil and socket detail. Stylized disconnected props no real wiring diagram. Components snap separately, no exposed loose floating ends in assembled view.

### 12 — Quatre terminaux d’amélioration

Four distinct freestanding compact game upgrade terminals, for ESPACE, LAMPES, FILTRE, SERRURE. Unified walnut/teal slanted console housing with brass screws, sculpted pictogram badge, large readable button, status light and small screen. One orthographic row of4 different faces and reverse row; one typical side/top/3quarter; mounting and detachable screen detail. Filter terminal controls fictional game state, actual cartridge is separate prop. No numeric real growth settings.

### 13 — Armoire à produits et serrure

Lockable stock cupboard warm walnut with teal reinforced frame, two upper shelves behind openable framed doors and lower enclosed storage. Empty shelves allow player chosen jars, clearance at least.60m. Front closed/open, rear, side, top and3/4. Separate visible heavy lock mechanism with three visual upgrade variants, hinges continuous, mint indicator, iron corner plates. No baked-in products. Matching wood/iron clandestine florist look.

### 14 — Composteur animé

Friendly grotesque animated cylindrical wooden compost barrel, iron bands, separate hinged top lid, two expressive eye modules and wide mouth opening with flat irregular wood/ivory toothlike shapes. Four orthographic views,3/4, lid opened and mouth/eyelid animation pivots. Stable solid base, hollow contents cavity, separate tongue-like soft compost flap optional subtle. No gore. Original mischievous cartoon identity, substantial refinement.

### 15 — Comptoir de vente et accessoires

Refined clandestine sales counter warm walnut/olive planks, brass corner guards, recessed panel and subtle botanical ornament; separate detailed cash register with many keys, screen, opening coin drawer; desk bell; clear transaction jar with coins physically on bottom and separate tip jar. Main counter front/back/side/top empty and3/4 dressed, lower large register orthographic detail/open drawer, bell/jars two views each. Back service cubby and playable accessible surface, no fused accessories, no real transaction instructions.

### 16 — Porte des visiteurs et accès discret

Discrete heavy teal timber visitor entrance door with inset wood panels, metal lower kickplate, brass handle/keyhole, believable hinges and removable ENTRÉE DISCRÈTE plaque above. Front/back/side/top,3/4 ajar, frame and hinge/latch detail. Door leaf1x2.2m, clear opening, no other room behind. Same cartoon cellar palette.

### 17 — Caisse de graines

Low reusable walnut seed crate with iron corners and removable compartments, packet slots and chalk icon label. Empty top, front/back/side,3/4 empty plus dressed example showing4 distinct colorful fictional seed sachets (leaf, star, lotus, moss pictograms). Sachets separate flat paper meshes with front/back; no cultivation instructions. Solid handles cut in end planks, base slats and visible joinery.

### 18 — Bouche d’égout et accessoires

Refined square stone/metal sewer-access surround with separate hinged round grate lid, inset shaft visible in sectional3/4. Separate bent rusty dripping pipe with real support, stylized little glowing mushrooms rooted in cracks, striped cartoon safety cone, separate SORTIE ÉGOUT arrow plaque. Main top/front/side/underside lid views and hero open state,2views per small accessory. No new ventilation grille: this is FLOOR sewer access only.

### 19 — Ancien associé et pancarte

Comedic non-gory cartoon skeleton wall display, elongated skull, readable rib cage/pelvis and jointed arms/legs, slack resting pose physically supported by two metal wall hooks and feet. Separate small wooden ANCIEN ASSOCIÉ plaque. Front/back/profile/3quarter, skull front/side, hinge/support details. No spherical cheekbones, integrated jaw/cheek arcs, stylized coherent anatomy. Stone wall not redesigned or included.

### 20 — Tuyauterie décorative et vannes

Decorative water/steam pipe kit, distinct from silver game ventilation: aged copper pipe, muted turquoise painted iron pipe, rusty elbow, vertical drain above bucket, red spoked shutoff valve. Straight/repeat modules, elbows, flanges, clamps and anchor plates, front/back/side/top/assembled3quarter. Plausible supports and rounded junctions, large valve design closeup. No real functional engineering instructions.

### 21 — Boîte à fusibles et panneau haute tension

Industrial cartoon teal metal fuse box with opening door, visible chunky switch handles and a single glowing status diode, reinforced hinges and short conduit stub, separate yellow triangle lightning warning plaque. Front closed and open, back mounting, side, top,3/4; handle/hinge/label detail. Fictional simplified interior, no real wiring schematic.

### 22 — Soupirail grillagé

Small horizontal deep-set cellar window.90x.40m, rust/teal iron rectangular frame, four sturdy bars, recessed frosted blue pane, thick stone sill insert compatible with existing grey masonry (do not redesign surrounding wall). Front/back/side section/top,3/4 detached insert, hinge/bar anchor closeup. Outside light soft. No ventilation filter here, maintain TWO dedicated ceiling vents only.

### 23 — Étagère à cinq bocaux

Single warm wood shelf1.5m long with two iron scroll brackets, 5 separate cartoon glass specimen jars various heights/lids containing non-specific colorful liquid, chunks or seeds grounded at bottom. Separate NE PAS BOIRE plaque. Front/back/profile/top EMPTY shelf and3quarter dressed;2views of each jar form. Open shelf supports arbitrary player placement, no fused jars, lids removable, glass lightly translucent.

### 24 — Étagères murales modulaires

Modular one-level wall shelves in two lengths1.5m and2m, warm planks, dark leaf-scroll brackets, olive fascia and small brass screws. Orthographic front/back/profile/top EMPTY plus3quarter dressed only with small silhouettes for scale. Labels OBJETS TROUVÉS and ZONE DE CONTREBANDE separate. Large bracket and hidden mounting rail detail. Minimum.90m clear vertical gap between separate shelves, never overlapping. Clear surfaces for player chosen objects.

### 25 — Canard décoratif et grille-pain

Two isolated cartoon collectibles: charming chunky yellow rubber duck with sculpted bill/wing marks, flat underside and black eyes; retro ivory/teal toaster with TWO true recessed top slots, metal rim, lever, round browning dial, push button, crumb drawer and rear plug. Each front/back/side/top/3quarter, duck base and toaster crumbdrawer detail. Rich clean design, no child doodles, not basic cubes.

### 26 — Bombe cartoon et bananes dorées

Two harmless cartoon collectible props: classic spherical dark purple decorative bomb with brass neck, curled unlit theatrical fuse and flat hidden foot, NO real device components; bunch of three golden stylized bananas with sculpted tapered ends, joined stalk and engraved base tray reading DORÉES. Each front/back/side/top/3quarter, material swatches. Pure game decoration, avoid photorealistic metal/no real explosives instructions.

### 27 — Bocal à poisson et casque spatial sous cloche

Two whimsical shelf collectibles: short clear glass fish jar with chunky cork lid, pale cyan water and one tiny goofy fish visible, pebble bed at bottom; retro ivory/plum astronaut helmet inside transparent round display dome on teal base, helmet visor and side hinge readable. Front/back/profile/top and3quarter for EACH, removable jar lid and removable dome/exploded base closeups. Fish grounded in water space, modest transparency clear silhouettes.

### 28 — Tasse crâne, mini-fusée et mini-lune

Three independently modeled cartoon shelf collectibles: ivory ceramic skull mug with handle, integrated cheek arcs not side balls, hollow open rim and dark eye sockets; miniature retro ivory/red rocket with three fins, porthole and flat display foot; little lavender cratered moon on dark crescent support stand. Each front/back/profile/top and3quarter in three clear rows. Mug underside/handle join, rocket fin and moon support details, restrained small sci-fi accents.

### 29 — Caisses et colis de contrebande

Modular timber shipping crates: small open crate, medium closed crate and tall strapped crate, iron corners, recessed carrying handles, stencil FRAGILE / HAUT / ÉCHANTILLONS on removable label cards. Individual front/back/side/top/3quarter and one stable stack example, separate lids and base plank detail. Include small paper parcel tied with string and TERRE label. Everything separate, boxes rest on supports, no floating props.

### 30 — Tonneaux, bidons et sacs

Four separate storage props: green wooden barrel with dark iron hoops and removable lid; red jerrycan; mustard yellow jerrycan; tied burlap sack with slumped grounded bottom and stitched seam. Front/back/profile/top/3quarter per prop, barrel bung, jerrycan spout/handle and sack tie details. Separate small SIROP plaque. Cartoon broad material marks, no photorealism. Stable forms and removable contents.

### 31 — Champignons et mousse lumineux

Glowing decorative fungus kit, three sizes of bulbous mint/pink/lilac mushroom, curved rooted stalks and visible underside gills. Front/back/profile/top/underside for individual mushrooms,3quarter cluster grounded in a separate irregular moss patch. Ten original exemplars realized by rotations/scale variations using3consistent master shapes. Detail small moss tufts, cluster base and restrained emissive edge. No floating caps, clean cartoon forms.

### 32 — Corde et bouquets suspendus

Decorative florist drying line: braided rope between2real brackets, wooden clothes pegs gripping tied stems, five small varied hanging botanical bouquets with leaves and flowerheads DOWN under gravity. Front/back/profile/top and3quarter; isolated peg open/closed, knot and bouquet attachment details. Warm wood/olive/dusty violet. No practical cultivation or processing instructions, purely stylized prop design. All bouquet meshes removable.

### 33 — Coin sieste, chat et radio

Two game decorative props: curled sleeping cartoon cat dark teal/grey with clear tucked paws, tail wrapping body, ears and closed eyes, flat textile cushion underneath; retro wood/teal radio with cloth speaker, readable tuner, two knobs, handle and folded antenna. Each front/back/profile/top and3quarter. Cat simple sleeping breathing pivot detail, radio back/battery cover, separate SIESTE plaque. No human character.

### 34 — Affiches et signalétique du sous-sol

Professional stylized sign/poster family: INTERDIT AUX FLICS warning with humorous crossed-out cartoon badge icon; TARIFS chalkboard; payment methods plaque using fictional coin/star icons. Each front/back/profile and mounted3quarter, canvas/paper/wood layers and mounting details. Hand-lettered bold highly readable refined typography, controlled worn edges, mature graphic design, not child drawing. Artwork flat plane separate from frame, exact text short, no prices needed.

### 35 — Paillasson et pot destiné au compost

Two separate floor props: coir doormat.9x.55m with plum border, neat botanical corner motifs and BIENVENUE (non) in clear handwritten lettering; small terracotta pot with visibly wilted cartoon flower, drooping stem, hanging leaves, soil below rim and no floating roots. Front/back/side/top/3quarter per prop; mat underside/edge and pot hollow section. Do not place real objects across mat walkway, stylized wear.

### 36 — Bacs de culture modulaires

Shared reusable grow-bed container for4fictional crop families, not4permanently fused plants: rectangular1.8x1.1m walnut box on sturdy short legs, dark iron corners, raised planter lip, recessed soil insert, clip-on label and clean empty ledge. Front/back/side/top EMPTY plus3quarter dressed with separate cartoon plants only as placement example. Empty hollow bed section, legs/soil liner attachment,4removable crop icon labels. Preserve original multi-plant bed purpose; objects removable and moveable by player. No real growing instructions.

### 37 — Lampes suspendues pour grands bacs

Wide cartoon growing lamp for a rectangular game bed, dark teal rectangular metal hood with two enclosed mint diffuser bars, small warm violet accent, separate hanging rods/chains with ceiling anchors and simplified cable connector. Front/back/profile/top/UNDERSIDE and3quarter above an EMPTY bed. Hood sized1.6x.5m as visual prop target, adjustable suspension for3.8m high basement. Fastener/driver cover detail, on/off. Do not include real lighting specifications or instructions. Separate lamp and bed models.

### 38 — Herbe sombre — quatre stades

Game crop HERBE SOMBRE based directly on approved EXISTING stylized cannabis compact model reference, not a new unrelated plant. Four clearly progressive fictional visual stages: tiny sprout, leafy growing plant, small developing buds, mature bush. Deep desaturated green/purple serrated compound leaves, branched bushy silhouette and stylized purple buds. Stage timeline TOP row; below mature front/back/profile/top/3quarter and separate leaf/bud cluster reference. Keep geometry centered at same stem origin, pot/soil separate. No real growth timetable, feed settings, cultivation guidance or real plant measurements. Pure videogame morph/mesh design.

### 39 — Lotus xéno — quatre stades

Fictional alien crop LOTUS XÉNO,4visual stages sprout, growing broad leaves, closed purple alien buds, mature violet bulbous flowers on thin mint stems, broad fleshy pointed green leaves. Preserve recognizable original game crop shown in image1, refine leaf/flower shapes. Timeline4stages, mature front/back/profile/top/3quarter, separate leaf underside and bloom section. Same ground origin, no permanent pot. Pure fantasy game crop no real cultivation instructions.

### 40 — Mousse de gouffre — quatre stades

Fictional alien crop MOUSSE DE GOUFFRE,4visual stages little grounded tuft, spreading dark teal cushions, curved fleshy blue shoots, mature clustered rounded teal/blue moss mounds with tiny subtle mint nodules. Preserve low rounded original game silhouette shown image1, refined organic tufts not giant cannabis bush. Timeline4stages, mature front/back/profile/top/3quarter, patch edge/underside details. All clusters touch same ground, no permanent pot. Pure fantasy game crop.

### 41 — Liane d’étoile — quatre stades

Fantasy LIANE D’ÉTOILE game crop: four stages rooted sprout, narrow blue/teal twining stems and pointed leaves, small star-shaped buds, mature delicate pale yellow luminous five-point stars on curled stems with lilac tiny berry nodes. Preserve original game crop image1 while refining readable star flowers. Timeline4stages, mature front/back/profile/top/3quarter, leaf and star front/back details. Optional separate short support stake. Pure fantasy game asset, no real cultivation instructions.

### 42 — Bocaux de récolte — qualités 1 à 4

Reusable stock product jars for fictional game crops, thick lightly smoky glass cylinder with stable flat base, screw-on dark teal lid, removable cream icon label and small1to4quality badge. Four examples quality1/2/3/4 with recognizable different visual fill shapes; contents sit on bottom, do not levitate. Front/back/profile/top empty container,3quarter filled, lid underside/hollow section and4interchangeable label designs. One material color per stored crop stack. No practical processing instructions.

### 43 — Pot individuel — un seul plant

NEW game item: one individual planting pot accommodating EXACTLY ONE cartoon cannabis/herbe sombre plant. Sturdy tapered terracotta/teal pot with rolled lip, molded grip tabs, matching separate saucer, inset soil surface and removable clip-on crop badge. Main front/back/profile/top EMPTY,3quarter empty and one dressed example with exactly ONE central plant based on approved compact model. Section shows one empty central placement socket, no multiple planting holes. Soil/pot/plant separate models, interchangeable at growth stages. Proposed potdiameter.48m height.42m for visual scaling only; no real growing instructions.

### 44 — Lampe pour pot individuel

NEW compact dedicated game growing lamp for exactly ONE individual plant pot: small rounded-square teal hood with mint light panel underside, short adjustable telescopic gooseneck on sturdy counterweighted C-shaped floor stand surrounding single pot space; cable safely clipped along stand. Front/back/profile/top/UNDERSIDE and3quarter with ONE single pot below for scale. Hood/stand/base separate meshes, articulated height joint details, on/off. Lamp silhouette clearly smaller than bed lamp, stable grounded base and clear access to pot, no multiple plants, no real lighting settings.

