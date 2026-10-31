# Sous-sol — collection intégrée

101 modèles GLB et 101 sources Blender éditables couvrent les 44 familles de planches. La planche 01 correspond à l’agencement de la scène réelle. Les murs gardent leurs matériaux d’origine ; la pièce mesure désormais 24 × 18 m, hauteur 3,80 m. Les illustrations de référence ont été interprétées en géométrie native, sans textures de rendu plaquées sur les meubles.

La scène jouable scenes/cellar/cellar.tscn charge les nouveaux modèles via CellarView et CellarRemodel. Les captures proviennent de cette scène et de ses actifs réels dans Godot ; elles utilisent une sauvegarde de présentation distincte, avec quatre bacs, huit pots et des cultures à différents stades. La sauvegarde du joueur n’est pas remplacée. La vue du dessus masque uniquement le plafond pour rendre le plan lisible.

Les pots individuels possèdent une capacité effective de un, sont intégrés au comptage des cultures, poussent avec le temps du jeu et envoient la récolte dans le stock existant. Plantation, ressources, récolte unique et sauvegarde sont testées. Les grands bacs conservent quatre emplacements. Les quatre cultures ont chacune quatre modèles de stades, et l’herbe sombre réutilise la géométrie du cannabis approuvé, sans son ancien pot ni sa coque de contour.

Deux bouches au plafond portent chacune une cartouche amovible. Le joueur débloque l’équipement au terminal FILTRE, puis installe ou retire les cartouches en interaction avec les bouches. Chaque cartouche montée contribue à la réduction des nuisances existantes, reliées au système de soupçons et de police. Les anciennes sauvegardes conservent l’effet des améliorations déjà achetées jusqu’à la première gestion manuelle des cartouches.

Les étagères exposent leurs surfaces libres sous forme de métadonnées pour le système de placement ; leurs accessoires sont des modèles distincts. L’éditeur de placement de mobilier du shop n’est pas étendu au sous-sol dans cette livraison. Les bacs et huit pots sont installés dans l’agencement de la cave.

Les collisions du sol, des murs, des marches, des grands meubles et des pots sont posées séparément du rendu. Un contrôle physique avec le volume d’un joueur vérifie dix points de l’allée centrale. Les poignées de porte, les mâchoires du composteur et le couvercle d’égout restent articulés. Le commerce et les visiteurs continuent d’utiliser le système existant.

Validation : 6 279 vérifications passent, zéro échec ; compilation et capture de la scène sans erreur de script. Le runner signale encore des objets et ressources non libérés à la fermeture, déjà signalés par les exécutions précédentes.

## Sources

- tools/blender/cellar_collection.py — génération métrique et export des modèles.
- src/cellar_view/cellar_remodel.gd — installation du décor et des collisions.
- src/cellar_view/single_pot_view.gd — interactions des pots individuels.
- src/cellar_view/cellar_equipment_visual.gd — bouches et cartouches.
- tests/test_cellar_remodel.gd — capacité, ressources, croissance, récolte, filtres, migration de sauvegarde.

## Correspondance planches / modèles

01 — Plan du sous-sol agrandi : agencement de la scène 24 × 18 m

02 — Plafond, poutres et deux aérations : ceiling, vent_socket, filter_cartridge, duct_module

03 — Bouches, conduits métalliques et filtres amovibles : vent_socket, filter_cartridge, duct_module, duct_elbow

04 — Sol, plinthes et patine : floor

05 — Escalier, marches et rampe : stairs

06 — Pancartes d’accès et bottes oubliées : entry_sign, step_warning, boots

07 — Ampoules et guirlande multicolore : bulb, garland

08 — Lanternes du sous-sol : lantern

09 — Bocaux de culture et étiquettes : culture_jar, label

10 — Truelles, cisailles, arrosoirs et seaux : trowel, shears, watering_can, bucket

11 — Câbles et multiprises : power_strip, cable_tray

12 — Quatre terminaux d’amélioration : terminal_capacity, terminal_lamp, terminal_filter, terminal_lock

13 — Armoire à produits et serrure : cabinet, cabinet_lock, cabinet_lock_electronic, cabinet_lock_heavy

14 — Composteur animé : composter

15 — Comptoir de vente et accessoires : counter, register, tip_jar, desk_bell, harvest_jar_q2

16 — Porte des visiteurs et accès discret : visitor_door, door_frame

17 — Caisse de graines : seed_crate

18 — Bouche d’égout et accessoires : sewer, sewer_sign, cone, pipes, mushroom_mint

19 — Ancien associé et pancarte : skeleton

20 — Tuyauterie décorative et vannes : pipes

21 — Boîte à fusibles et panneau haute tension : fusebox

22 — Soupirail grillagé : window

23 — Étagère à cinq bocaux : shelf_150, culture_jar

24 — Étagères murales modulaires : shelf_150, shelf_200, found_sign, contraband_sign

25 — Canard décoratif et grille-pain : duck, toaster

26 — Bombe cartoon et bananes dorées : cartoon_bomb, gold_bananas

27 — Bocal à poisson et casque spatial sous cloche : fish_jar, space_helmet

28 — Tasse crâne, mini-fusée et mini-lune : skull_mug, mini_rocket, mini_moon

29 — Caisses et colis de contrebande : shipping_crate, paper_parcel

30 — Tonneaux, bidons et sacs : barrel, jerrycan_red, jerrycan_yellow, sack, syrup_sign

31 — Champignons et mousse lumineux : mushroom_mint, mushroom_pink, mushroom_lilac, moss_patch

32 — Corde et bouquets suspendus : drying_line

33 — Coin sieste, chat et radio : sleeping_cat, radio, nap_sign

34 — Affiches et signalétique du sous-sol : warning_poster, tariffs_sign, payments_sign

35 — Paillasson et pot destiné au compost : doormat, wilted_pot

36 — Bacs de culture modulaires : grow_bed

37 — Lampes suspendues pour grands bacs : bed_lamp

38 — Herbe sombre — quatre stades : herb_seedling, herb_growing, herb_budding, herb_ripe

39 — Lotus xéno — quatre stades : lotus_seedling, lotus_growing, lotus_budding, lotus_ripe

40 — Mousse de gouffre — quatre stades : moss_crop_seedling, moss_crop_growing, moss_crop_budding, moss_crop_ripe

41 — Liane d’étoile — quatre stades : star_vine_seedling, star_vine_growing, star_vine_budding, star_vine_ripe

42 — Bocaux de récolte — qualités 1 à 4 : harvest_jar_q1, harvest_jar_q2, harvest_jar_q3, harvest_jar_q4

43 — Pot individuel — un seul plant : single_pot

44 — Lampe pour pot individuel : single_lamp

