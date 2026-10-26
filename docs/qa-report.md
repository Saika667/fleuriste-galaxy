# Rapport QA de bout en bout (agent QA)

Outils : `tools/e2e_play.gd` (robot qui joue la vraie scène `main.tscn`, entrées réelles Key/Mouse/Action + appels de Game en repli),
`tools/e2e_run.ps1` (lot de parties parallèles + tableau d'équilibrage), `tests/test_fuzz.gd` (fuzz du cœur, contrat « refus = rien ne change »),
`tests/test_e2e_regressions.gd` (non-régressions).
Lancer : `powershell -Command ".\tools\e2e_run.ps1 -Seeds (1..10) -Days 10 [-NoSubs] [-Mode real -Scale 12] -Tag nom"` ; fuzz long : `FUZZ_SEEDS=60 FUZZ_OPS=1200` puis `tools\run_tests.ps1`.

## Bugs corrigés (src/core, data) — chacun avec test dans tests/test_e2e_regressions.gd
1. Charger depuis le menu Pause relançait le temps derrière le menu (`GameClock.from_dict` remettait `paused=false`).
2. L'autosave de fin de cycle était écrite en phase SAVING : la charger bloquait la partie. Sauvegarde désormais après le passage en PREPARATION ; les anciennes sauvegardes SAVING avancent à leur chargement.
3. Récompense du premier extraterrestre (5 réputation + 2 graines xéno) accordée à CHAQUE alien (clé par uid) : unique par définition de client. Gonflait la réputation (jusqu'à 11 fois par partie).
4. Un sub libérant un client extraterrestre échouait en silence (route « street » interdite pour lui) : route propre au client.
5. Les extraterrestres représentaient 1/3 des clients après le chapitre 4 : `spawn_weight` (0,3) dans customers.json, tirage pondéré.
6. Vague de subs = inflation de réputation (+2 par défilé et par sub) : `max_rewards_per_day` dans events.json.
7. Événements « modificateur » (défilé, panne) sans aucun effet : `effect` (spawn_factor / growth_factor, durée), sauvegardés.
8. Voleur jamais résolu si le joueur ne descend pas à la cave (incident actif indéfiniment) : résolu à la fin de la nuit (vol sauf serrure).
9. Policier qui part (fermeture/impatience) en laissant une visite active fantôme : visite fermée.
10. `look_seed` des clients rechargé en flottant après chargement (JSON) : cast en entier.
11. Nombre de bacs non borné côté cœur : `planters.max_planters` = 4.

## Bugs d'autres zones (non corrigés)
- **UI** `src/ui/portrait.gd:376` (`_draw_hair_front`, style 5 « carré ») → `ui_art.gd:64` `poly()` : « Invalid polygon data, triangulation failed » (≈8 à 40 erreurs moteur par partie de 10 jours, une partie sur deux). Polygone dégénéré/auto-sécant de `_hair_cap(hc, rx, ry, 0.02, 0, 0)` (probablement portrait de taille nulle au premier dessin). Correctif suggéré : dans `A.poly`, ne remplir que si `Geometry2D.triangulate_polygon(pts).size() >= 3` (et ignorer si rx/ry <= 1).
- **UI/cave** `cellar_view/overlay.gd:153` et `hud.gd:722` : Échap est traité par les deux (menu d'action cave + pause du HUD, `handle_escape` reste vrai en mode cave) : risque d'ouvrir la pause en annulant un menu. Correctif : `main._set_hud_escape(false)` quand l'overlay de cave est ouvert.
- **Cave** `cellar_view.gd:626` `pad_action` paie 40 avant `add_planter()` (désormais pouvant retourner null au plafond) : tester le retour. Le prix 40 est codé en dur (data : `furniture.grow_bin.cost`).
- **Cave** `_drive_thieves` : les voleurs n'avancent que si la vue de cave est ouverte (voir correctif 8 côté cœur).
- Les événements `modifier` ne montrent aucun retour visuel (le HUD affiche seulement le texte).

## Invariants vérifiés (robot + fuzz)
Aucun SCRIPT ERROR ; soldes jamais négatifs ni modifiés hors transaction (registre de comptes par signal `transaction`) ; achats = débit exact ; double validation d'achat/livraison sans effet ; jamais 5 plants (UI, cœur, emplacement 5) ; argent clandestin ne paie ni meuble, ni stock, ni cave, ni charges ; aucune clé/texte de suspicion dans `public_state` ni dans le HUD visible ; temps figé en préparation/bilan/sauvegarde/pause/stock/prix/placement ; file ≤ 6 et clients ni coincés ni sans acteur (mode réel) ; fraîcheur jamais remontée ; pas de NaN ; sauvegarde/chargement identiques (soldes, plantes, bouquets, meubles, clients) ; pas de fuite de nœuds sur 10 jours (nœuds ≈ stables, orphelins 0).

- **UI** `src/ui/dev_panel.gd:57` : `_susp_slider.value_changed` appelle `Game.dev.set_suspicion` dès l'initialisation du slider (avant `_slider_lock`) : en build exporté cela produit l'avertissement « WARNING: DevTools desactives » au lancement (seul message du journal de l'exe), et en debug remet la suspicion à 0 à chaque ouverture. Correctif : utiliser `set_value_no_signal` à l'initialisation / tester `Game.dev.enabled`.

## Parties jouées
- 10 graines × 10 jours sans subs (21-30), 10 × 10 jours avec rafales de subs (31-40), 8+8 de tours précédents, 2 parties en temps réel (Engine.time_scale 12, acteurs 3D vérifiés) : 0 SCRIPT ERROR, 0 invariant de jeu cassé ; seules erreurs : le polygone de `portrait.gd` (UI) ci-dessus. Fuzz du cœur : 60 graines × 1200 appels, 0 échec.
- Couverture du robot : préparation, achat de stock (écran Tab), bouquets à l'établi (commande précise et intention, livraison, exposition, frigo), prix (P), placement souris (pose valide, refus porte/chevauchement/sans fonds, déplacement, rotation), vente, bilan, conversion, nuit, cave (bacs, graines, plantation, récolte, améliorations, vente clandestine, voleur poings/batte/arme à feu/ignorer/maîtriser, composteur), policier (vente/refus/report + sanction), alien (forcé au jour 7 si nécessaire), rafales de subs, pause, sauvegarde/chargement mis en scène depuis le menu pause, chargement de l'autosave.

## Équilibrage observé (moyennes, bot « joueur appliqué »)
Sans subs (10 parties) : ventes fleuriste ≈ 105-170 €/jour, net caisse jour 1 ≈ -74 (achat de stock initial), puis +20 à +70/jour (à peine rentable, jamais d'effondrement : la caisse ne passe pas sous ≈ 75) ; clandestin produit 300-790/jour dès la nuit 5 ; converti 46-116/jour ; perte par fanage ≈ 5-10 tiges/jour ; visites de police 0 avant le jour 8 pour un joueur prudent (cave ≤ 4 plants), 1 visite / 3 jours pour un joueur gourmand (16 plants, surcharge, sur-conversion), jamais avant 2 jours pleins de manifestations ; réputation ≈ 18 au jour 10.
Avec subs (burst de 70 subs/jour, 10 libérations max par cycle) : ventes ≈ 520 €/jour et réputation 70 au jour 10 (avant correctifs : 150-175, chapitre « galaxie » dès le jour 8 et alien récompensé 11 fois). Ajustements de data : plafond de récompense par jour (événements), `spawn_weight` alien 0,3, `max_planters` 4 ; aucun chiffre de `balance.json` modifié (aucune boucle cassée après correction des récompenses).
Constat non corrigé : une fois les améliorations de cave achetées (≈ 2 000 clandestins) et les meubles posés, aucune dépense n'absorbe plus l'argent (légitime ou clandestin) : les extensions du GDD (étage, terrasse, personnel) sont le puits attendu.

## Export Windows
`build/windows/Fleuriste.exe` (112 Mo) exporté sans erreur (code 0, aucun ERROR/WARNING dans le journal d'export). Lancé 20 s avec `--log-file` : processus vivant, Vulkan/RTX 3070 initialisé, seul message : l'avertissement « DevTools desactives » (voir dev_panel.gd:57). Journal : out/e2e/exe.log.
