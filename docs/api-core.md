# API du coeur de jeu (src/core)

Logique pure, sans visuels. Point d'entree : l'autoload `Game` (`src/core/game.gd`). Les sous-systemes sont des classes `RefCounted` (`class_name`) accessibles via `Game.<nom>`. Donnees et equilibrage : `data/*.json` (cles `_doc` = documentation ; rechargeables via `GameData.reload()`).

Tests : `powershell -File tools/run_tests.ps1` (headless, code de sortie non nul en cas d'echec).

## Regles pour l'interface

- Ne jamais afficher de jauge de suspicion. `Game.public_state()` n'expose que `world_hints` (identifiants de manifestations : `customer_remark`, `vehicle_returns`, `behavior_change`) ; la file publique masque la police (`category` = `florist` | `visitor`).
- Toute action retourne `{ok: bool, error?: String, ...}` ; en cas d'echec rien n'est modifie. Afficher `error`/`hints`.
- Apres `Game.new_game()` ou `game_reset`, relire les references (`Game.inventory`, `Game.economy`...).
- Temps : `Game.clock.is_time_stopped()` (true en preparation, bilan, sauvegarde, pause). Pause : `Game.clock.set_paused(bool)`. L'autoload avance seul le temps dans `_process` (`manual_time=false`).

## Game (autoload)

Signaux : `game_reset`, `state_changed`, `customer_served(result)`, `bouquet_composed(bouquet)`, `daily_report_ready(report)`, `event_triggered(def_id, instance_id, reward)`, `message(id, args)` (ex. `sanction`).

Proprietes : `clock, inventory, economy, cellar, suspicion (interne), police, thieves, customers, events, subs, progression, rooms{shop,cellar}, bouquets[], dev, last_report, now, save_path`.

Methodes :
- `new_game(seed=-1)` : etat initial + etabli, refrigerateur, comptoir poses.
- `tick(delta)` : fait avancer tous les systemes (si le temps tourne).
- `public_state() -> Dictionary` : jour, phase, time_stopped, legit, shady, arrears, reputation, chapter, queue[], bouquets, world_hints, conversion_remaining.
- Stock/bouquets : `buy_stock(variety, qty, quality=1)`, `supplier_price(variety)`, `compose_bouquet(picks{variete:qte}, wrap="none", accessories=[], price=-1, for_order="") -> Bouquet|null`, `recommended_price(b)`, `set_bouquet_price(id, price)`, `set_bouquet_cold(id, bool)`, `set_lot_cold(lot_id, bool)` (exige un refrigerateur place), `has_fridge()`, `find_bouquet(id)`.
- Ventes : `sell_bouquet_to(customer_uid, bouquet_id, price=-1)` -> `{ok, amount, evaluation, reward?}` ou `{error: rejected|price_refused|no_such_*, evaluation, verdict}`.
- Clandestin : `begin_dialogue(uid) -> Dialogue`, `choose_dialogue(uid, choice_id, stock_index=0)`, `sell_product(uid, stock_index)`, `refuse_customer(uid)`, `convert_money(amount, allow_overflow=false)`.
- Meubles : `buy_furniture(def_id, room, x, y, rot=0)` (valide placement + fonds, portefeuille impose par la categorie). Deplacements : `rooms[room].move/rotate_item/remove`.
- Histoire/cave : `discover_secret()`, `acquire_cellar()`, `plant_in_cellar(planter_idx, crop, compost_units=0)`.
- Evenements : `trigger_event(def_id, instance_id)`, `apply_reward(reward)`.
- Sauvegarde : `save_game(path="")`, `load_game(path="") -> {ok, from_backup}`, `to_dict()/from_dict()`. Sauvegarde auto a chaque fin de cycle.

## GameClock (`Game.clock`)

Phases `GameClock.Phase.{PREPARATION, OPENING, REVIEW, NIGHT, SAVING}`. Signaux : `phase_changed(new, old)`, `day_started(day)`, `time_stopped_changed(stopped)`, `cycle_ended(day)`. Le temps ne s'ecoule qu'en OPENING et NIGHT. Le joueur passe PREPARATION->OPENING et REVIEW->NIGHT avec `next_phase()` ; OPENING->REVIEW et NIGHT->SAVING->PREPARATION sont automatiques en fin de duree. `phase_fraction()`, `hour_of_day()`, `phase_name()`, `day`.

## Economy (`Game.economy`)

`legit`, `shady`, `arrears`, `reputation`, `shop_level`, `decoration`. Signaux `changed(legit, shady)`, `transaction(tx)`, `over_capacity(excess)`. `pay(amount, category, tx_id="")` (categories dans `balance.economy.categories` ; l'argent clandestin ne paie jamais `furniture`/`stock`/`charges`), `can_pay`, `earn_legit`, `earn_shady`, `convert`, `conversion_capacity()`, `conversion_remaining()`, `upcoming_charges()` (annonce avant le bilan), `end_day_charges()`, `apply_fine`. Les `tx_id` rendent les operations idempotentes.

## Stock, bouquets

- `Inventory` : lots `{id, variety, qty, quality, freshness, cold, unit_cost}` ; `add`, `total`, `take`, `set_cold`, `age`, `remove_wilted`, signal `changed`.
- `Bouquet` : `stems[]`, `wrap`, `accessories[]`, `price`, `cold`, `cost()`, `freshness()`, `recommended_price(rep, deco)`, `counts()`.
- `BouquetScorer.evaluate(bouquet, order_id) -> {demand, harmony, freshness, presentation, total, accepted, hints[], failed_rules[]}` ; `price_verdict(...)`. Les regles des commandes sont dans `data/orders.json` ; `hints` = indices lisibles pour le joueur.
- `Freshness` : taux de fanage (frigo = `fridge_factor`, jamais de remontee).

## Cave

`Cellar` (`Game.cellar`) : `planters[]` (`Planter`, 0 a 4 plantes, `slots[i]` = null ou `{crop, quality, growth, growth_seconds}`, `stage_of(i)` = empty/seedling/growing/ripe, `plant`, `harvest`), `equipment{capacity,lamp,filter,lock}`, `upgrade(kind, economy)`, `seeds`, `buy_seed`, `stock[]` (produits recoltes, `harvest(planter, slot)`), `load_factor()`, `nuisance_probability()`, signal `nuisance_signal(kind)` (fumee verte / bruit : a animer), `composter` (`units`, `queue`, `add_body`). Qualite : voie avec tuer (compost) ou sans tuer (plante xeno + lampe), maximum identique.

## Police, voleurs

- `Police` (`Game.police`) : signaux `visit_started`, `visit_resolved(result)`, `sanction_applied(report{confiscated, fine})`. Dialogue : `Game.begin_dialogue(uid)` puis `Game.choose_dialogue(uid, choice_id)`; `Dialogue.current().text`, `choices()`, `is_done()`, `outcome`.
- `Thieves` (`Game.thieves`) : `spawn(day) -> incident`, `resolve(id, "fight"|"subdue"|"ignore", cellar)` (une seule resolution par incident). Signaux `incident_started`, `incident_resolved`.

## Clients, evenements, subs

- `CustomerQueue` (`Game.customers`) : `queue[]`, `arriving[]` (egout/portail), `spawn(def_id, route, chapter, rng)`, `find`, `remove`, signaux `customer_arrived`, `customer_left(c, reason)`. Client = `{uid, def, kind, route, order, patience, eta, name, label, tells, look_seed, face_id}` (apparence : voir « Règle GDD 9 ») ; definitions : `data/customers.json` (`GameData.customer(id)`).
- `EventBook` (`Game.events`) : `fire(def_id, instance_id, ctx)`, anti-doublon par identifiant.
- `SubQueue` (`Game.subs`) : `push_sub(name)`, `pending`, `dropped`, signal `sub_released(sub, pick)` ; limites dans `balance.sub_queue`.

## Placement

`Game.rooms.shop|cellar` (`Placement`) : grille, `items[]`, `can_place(def, x, y, rot) -> {ok, error}` (erreurs : `out_of_bounds, overlap, blocks_door, blocks_access, wrong_room`), `place`, `move`, `rotate_item`, `remove`, `decoration_score()` (rendements decroissants), signal `changed`. `Placement.footprint_size(def, rot)`, `cells_of(...)` pour l'apercu.

## Progression

`Progression` (`Game.progression`) : `chapter`, `chapter_id()`, `flags`, `has_flag`, `set_flag`, `check_advance(ctx)`, signaux `chapter_changed`, `flag_set`. Chapitres dans `data/chapters.json`.

## Outils de dev (`Game.dev`, actifs en build debug)

`advance_time(s)`, `simulate_sub(name)`, `simulate_subs(n)`, `trigger_visit()`, `fill_stock(qty)`, `give_money(legit, shady)`, `goto_chapter(id)`, `goto_phase(phase)`, `peek_suspicion()`, `set_suspicion(v)`. Seuls lieux ou la suspicion interne est lisible.

## Réfrigérateur à capacité (tour 2)

Capacité en tiges : `balance.fridge.capacity_per_unit` (24) x nombre de réfrigérateurs placés ; un bouquet compte son nombre de tiges.
- `Game.fridge_capacity()`, `fridge_used()`, `fridge_free()`, `fridge_state() -> {capacity, used, free, units}` ; `public_state().fridge` expose le même dictionnaire.
- `Game.try_set_lot_cold(lot_id, cold, qty=-1) -> {ok, lot_id, moved}` ou `{ok:false, error: no_fridge|fridge_full|no_such_lot|invalid}` (`fridge_full` porte `free`/`needed`, rien n'est modifié). `qty` scinde le lot (`Inventory.split_lot`) pour remplir exactement ; la fraîcheur n'est jamais touchée.
- `Game.try_set_bouquet_cold(id, cold)` : mêmes erreurs. `set_lot_cold` / `set_bouquet_cold` restent des wrappers booléens (false si plein). Sortir du froid est toujours permis.

## Combat par états (voleurs)

`Thieves` : un incident porte `phase` (`approach` -> `stealing` -> `fleeing` -> `done`), `endurance`, `timer`, `loot[]`. Signal `phase_changed(incident, phase)`.
- `Thieves.tick(dt, cellar)` fait progresser les phases ; `Game.tick` l'appelle seulement si `balance.thieves.auto_advance` est vrai (false par défaut : la vue de cave pilote encore ses voleurs via `resolve`).
- `Game.strike_thief(id, weapon="", lethal=false)` / `Thieves.strike(id, cellar, weapon, chapter, lethal)` : un coup retire `damage` d'endurance ; tout coup non fatal fait fuir le voleur (il garde son butin tant qu'il n'est pas vaincu). À 0 : tué (corps au composteur) seulement si `lethal` ET arme létale, sinon il s'enfuit et rend le butin. Erreurs : `unknown_incident, already_resolved, unknown_weapon, weapon_locked`. L'arme à feu ajoute un signal de suspicion `noise`.
- Armes (`balance.thieves.weapons`, par chapitre) : poings (0, non létal), batte (chapitre 3), arme à feu (chapitre 5). `Game.available_weapons()`, `best_weapon()` ; `Cellar.weapon` suit le déblocage. La voie sans tuer (poings, `lethal=false`, `resolve("subdue")`) est toujours possible.
- Repli inchangé : `resolve(id, "fight"|"subdue"|"ignore", cellar)` fonctionne à tout moment (une seule résolution).

## Réservation de composants (employés, GDD 12)

API seule, sans interface. `Game.reserve_components(owner, {variété: qté}) -> {ok, error?}` (`insufficient_stock`, `already_reserved`, `invalid`), `release_components(owner)`. `Inventory.available(variété)` = stock libre ; `reserved`, `reserved_by(owner)`, `can_take`. `take()` et `Bouquet.compose` refusent de toucher aux tiges réservées à autrui ; `Game.compose_bouquet(..., for_order="", owner="")` permet au propriétaire de consommer sa réservation. Les réservations sont sauvegardées et purgées si le stock fane.

## Équilibrage initial (simulation headless)

`tools/sim_balance.gd` (`godot --headless --path . -s tools/sim_balance.gd`) et `tests/test_balance.gd` simulent 10 jours avec un robot (achète, compose la commande, vend au prix conseillé, range le surplus au frais) : `tests/balance_sim.gd`.
Valeurs retenues (`data/balance.json`) :
- `customers.spawn_interval_opening` 120 s (≈ 6 clients/jour au chapitre 0) ; départ 150 en caisse, charges 15/jour.
- `scoring.reputation_per_star` 0.1 (≈ +0,45 réputation par vente ; le chapitre « premier extraterrestre » reste atteignable vers le jour 6-7).
- Résultat seed 7 : net +10 le jour 1, +29 / +32 les jours suivants (à peine rentable), +63 au jour 10 ; une journée sans client coûte ≈ -63 et la caisse d'avant est retrouvée en 3 jours.
- `suspicion.min_hint_days_before_visit` 2 : une visite n'est due qu'après deux jours pleins de manifestations perceptibles (`customer_remark`, `vehicle_returns`...). Scénario imprudent (cave surchargée, conversions en dépassement, vente au policier) : signaux dès le jour 1, visite et sanction au jour 3. `dev_set` ignore ce délai.
- `fridge.capacity_per_unit` 24 ; `thieves.endurance` 3, `approach_seconds` 12, `steal_seconds` 4, `flee_seconds` 3.

## Données et textes

Tous les textes joueur de `data/*.json` sont en français accentué ; `tests/test_core2.gd` vérifie le chargement, l'absence de mots courants sans accent, l'encodage et la cohérence des références (commandes, dialogues, événements).

## Export Windows

`export_presets.cfg` : preset « Windows Desktop », x86_64, PCK embarqué, sans console ; `build/windows/Fleuriste.exe` via `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/windows/Fleuriste.exe`.

## Règle GDD 9 : aucun champ public n'identifie le policier (tour 3)

Le policier en civil et les clients clandestins sont indiscernables par tout ce que voit le joueur. Règles :

- **Tirage par instance** (`CustomerQueue.persona(uid, def_id)`, appelé par `spawn`) : pour les kinds `shady` et `police`, nom, tells, `face_id` et `look_seed` viennent de `data/customers.json > visitor_pools` (mêmes pools, mêmes probabilités), à partir d'un RNG privé seedé par l'uid (ne consomme pas `Game.rng`). Aucun tell n'est exclusif au policier ; il peut avoir n'importe quel look commun. Noms : surnoms et noms civils mélangés dans un seul pool. Étiquette : « Visiteur » pour tous (« Client » pour les fleuristes, « Visiteur d'ailleurs » pour les non-humains).
- **Dialogues** : `police_visit` et `shady_sale` ont les mêmes trois choix (`sell`, `refuse`, `stall`, mêmes libellés, même ordre) et les mêmes répliques finales. L'ouverture est tirée de `visitor_pools.openers` (`text_pool`) via `Dialogue.new(id, seed)` ; `Game.begin_dialogue` passe `look_seed`. Le report (`stall`) d'un clandestin renvoie `{done, outcome:"stall"}` : le client repart sans coût.
- **Route** : le policier peut arriver par `street` ou `sewer`.
- **Vues** : ne jamais lire `kind`, `def` ni les champs de définition (`GameData.customer(def).visible_tells/name`) pour l'apparence, les couleurs ou les textes. Utiliser `Game.public_state().queue[i]` ou `CustomerQueue.public_view(c)` : `{uid, name, label, species, tells, look_seed, face_id, route, category, order_text}` (mêmes clés pour tous). Les valeurs de repli des définitions shady/police sont identiques entre elles.
- **Apparence exploitable** : `look_seed` (entier ≥ 0, stable par uid, indépendant du type) pilote visage et accessoires (un même uid donne le même look pour n'importe quel type). `face_id` : fixe pour les récurrents (`mme_pivoine`, `m_bleuet`, `zzorb`), `anon_0`..`anon_11` pour les visiteurs. Les champs sont dans le dictionnaire client (sauvegardés) et rétro-compatibles avec d'anciennes sauvegardes.
- **Tests** : `tests/test_visitors.gd` (200 policiers + 200 clandestins simulés : noms, étiquettes, tells, combinaisons, ouvertures, visages, libellés de choix, clés de définition, clés de `public_state`).

## Extensions de boutique (tour 5, GDD 4)

Données : `data/expansions.json` (`order` + `expansions{id}`) ; classe `Expansions` (`src/core/expansions.gd`), `Game.expansions`. Six extensions : `terrace`, `shed`, `garden`, `greenhouse`, `enlargement`, `upstairs`. Payées en argent LÉGITIME (catégorie `economy.categories.expansion` = `["legit"]`, garde-fou `illegitimate_funds` si les données la changeaient).

- `Game.expansions.list() -> Array` : par extension `{id, name, description, cost, state: "locked"|"available"|"owned", lock_reason (texte français de la première raison, "" si aucune), reasons[{code: chapter|reputation|day|expansion, text, need}], requires, charges{energy,taxes,upkeep}, charges_total, effects, effects_text[] (phrases françaises), room, affordable (disponible ET payable)}`. `info(id)` = une entrée, `state_of(id)`, `lock_reasons(id)`, `is_owned(id)`, `owned_ids()`.
- `Game.expansions.buy(id) -> {ok, id, cost, charges, effects}` ou `{ok:false, error}` : `unknown`, `already_owned`, `locked` (+ `reasons`), `insufficient_funds` (+ `cost`, `missing`), `illegitimate_funds`. Toutes les conditions sont validées AVANT de toucher au solde ; en cas d'erreur rien ne change ; un second appel renvoie `already_owned` (jamais de double débit ni de double effet).
- Signaux : `Game.expansions.changed`, `Game.expansions.bought(id)` ; `Game.message("expansion_bought", {ids})` et `state_changed` à chaque achat. `Game.message("garden_harvest", {items, lost})` à chaque récolte du matin.
- `Game.public_state().expansions` : `{owned[], available[], charges{}, charges_total, capacity{queue, fridge, stock, stock_used, employee_slots}, garden_yield{}, last_harvest{day, items, lost}, rooms[]}`. `Game.capacity_state()` donne `capacity`.
- Prérequis (`requires`) : `chapter` (id de `chapters.json`), `min_reputation`, `min_day`, `expansions[]` (extensions précédentes) ; toutes obligatoires.
- Charges : ajoutées à `Economy.upcoming_charges()` (mêmes clés energy/taxes/upkeep, via `Economy.extra_charges`) dès l'achat, donc annoncées dans `last_report.upcoming_charges` et prélevées par `end_day_charges()` (jamais de solde négatif : le manque devient dette récupérable). Détail par extension : `expansions.charges_of(id)`, total `expansions.charges()`.
- Effets (`effects`) : `queue_capacity` (+places de file : `customers.max_length()` ; le monde 3D n'a que 6 emplacements de file, `shop_world._compute_slots`, à étendre côté UI), `customer_rate` (+% de clients : `Game.spawn_factor()` divisé par 1+x), `decoration_bonus` (valeur perçue : s'ajoute à `economy.decoration`, donc au prix conseillé ; `Game.refresh_decoration()` somme aussi la déco des pièces ajoutées), `fridge_capacity` (tiges en plus, seulement si un réfrigérateur est posé), `stock_capacity` (tiges), `garden_daily`/`garden_quality`/`garden_multiplier` (récolte chaque matin au passage au jour suivant, dans la limite de la place libre ; surplus perdu et annoncé), `employee_slots` (étage ; `expansions.employee_slots()`, aucun employé encore).
- Stock plafonné : `Game.stock_capacity()` (`balance.stock.capacity` 60 + remise 60 + étage 20), `stock_used()`, `stock_free()` ; `buy_stock` refuse `{error: "stock_full", free, needed}` sans rien modifier.
- Pièces de placement : `Game.rooms.terrace|garden|annex|upstairs` n'existent qu'une fois l'extension achetée (grilles dans `data/furniture.json`). `buy_furniture(def, room, x, y)` renvoie `room_locked` avant l'achat. Nouveaux meubles : `bench`, `parasol` (terrasse/jardin/annexe), pots/présentoirs/tapis aussi à l'annexe et à l'étage. Le catalogue du mode placement (boutique) est inchangé.
- Sauvegarde : clé `expansions` {owned{id: jour}, last_harvest} dans `Game.to_dict()` ; rétro-compatible (absente = aucune extension) ; charger une partie sans extension retire les pièces d'extension.

Équilibrage retenu (coûts / réputation / charges par jour) : terrasse 90 / 4 / 5, remise 150 / 10 / 3, jardin 300 / 12 (+terrasse) / 7, serre 600 / 18 + chapitre « Agrandissements » (+jardin) / 14, agrandissement 750 / 20 + chapitre (+terrasse) / 14, étage 1000 / 30 + chapitre (+agrandissement) / 12. Charges de base 15/jour. Effets : terrasse file +1, +15 % clients, valeur +3 ; remise stock +60, froid +12 ; jardin 11 tiges/jour (roses 3, lavande 2, tulipes 3, marguerites 3, qualité 2) ; serre récolte x1,5 + 3 fleurs xéno + 3 lys, qualité 3 ; agrandissement file +1, +15 % clients, froid +12 ; étage 1 poste d'employé, stock +20, +10 % clients. Robot QA (`tools/e2e_play.gd > expansions_routine`, achète quand `caisse - coût >= 70 + 4 x charges`) : voir `docs/qa-report.md` / rapport du tour.

## Tour 6 : nouvelles espèces, employés, mode streamer

Tout est piloté par des données (`data/customers.json`, `orders.json`, `events.json`, `flowers.json`, `balance.json`, `employees.json`, `streamer.json`) ; tests dans `tests/test_tour6.gd` (+ fuzz étendu), robot dans `tools/e2e_play.gd` (`--staff=N --staff-day=D`).

### Nouvelles espèces (GDD 11)

| Espèce (`species`) | Clients (`def`) | Arrivée | Différence de jeu | Incident propre |
|---|---|---|---|---|
| `weeper` Pleurnoïdes (brume de deuil) | `weeper_veuve` (récompense unique : 2 graines `gloom_moss`, +3 réputation, drapeau `weeper_served`), `weeper_cousin` | égout (`sewer`) ou rue | **Paient en larmes de comète** (`currency: comet_tear`), converties au **cours du jour** (entre 0,6 et 1,5, frais 5 %) ; commandes de deuil (`weeper_condolence`, `weeper_vigil`, `weeper_consolation`) | `weeper_fog` : brouillard (moins de passants + signal de fumée interne, seulement si la cave a des plants) ; `tear_market_crash` / `tear_market_boom` : choc de cours |
| `ploc` Plocs (gelée gloutonne) | `ploc_goinfre` (2 graines `star_vine`, +3 réputation, drapeau `ploc_served`), `ploc_gourmet` | portail (`portal`) ou rue | **Exigent une plante extraterrestre précise** : `snap_orchid` (Orchidée mordeuse) dans `ploc_feast` / `ploc_picnic` / `ploc_gift` | `ploc_munch` : avale 4 tiges libres à l'air (jamais le frigo ni les réservations) |

- Déblocage explicite : `unlock_chapter` + `unlock_flags` (+ `unlock_min_day`, `unlock_min_reputation`) dans `customers.json`. Pleurnoïdes : chapitre `species` ; Plocs : avoir servi une Pleurnoïde ; cousin / gourmande : avoir servi la première de leur espèce. `Game.customer_available(def_id)` est utilisé par le tirage automatique et par les subs.
- Nouvelles fleurs (`flowers.json`, `unlock_chapter`/`unlock_flags`) : `pleurelune` (chapitre `species`), `snap_orchid` (après la Pleurnoïde). `Game.flower_available(id)`, `Game.available_flowers()` ; `buy_stock` refuse `{error:"flower_locked"}` sans rien modifier. **L'interface du fournisseur doit filtrer avec `available_flowers()`.**
- Nouvelles cultures de cave (`balance.crops`, `unlock_chapter`/`unlock_flags`) : `gloom_moss` (Mousse de gouffre, après la Pleurnoïde), `star_vine` (Liane d'étoile, après le Ploc). Voie **sans tuer** conservée (bonus de qualité xéno, pousse plus lente, graine plus chère, maximum atteignable avec la lampe). `Game.available_crops()`, `Game.buy_seed(crop, n)` (refuse `crop_locked`), `plant_in_cellar` refuse `crop_locked`.
- Monnaie : `Game.exchange` (`Exchange`) : `rate(id)`, `trend(id)` (`up|down|flat`), `to_euros(id, n)`, `state()`. `Game.expected_payment(uid, price)` -> `{amount, foreign_amount, currency, rate}` ; `Game.customer_currency(uid)` -> `{currency, name, symbol, rate, trend}` ou `{}` (afficher « paie en larmes de comète, cours 0,95 »). `sell_bouquet_to(uid, id, price=-1, actor="")` renvoie en plus `foreign_amount`, `currency`, `rate`, `actor`. Le cours évolue à chaque fin de cycle (graine de la partie + jour : déterministe) et par événement ; il est sauvegardé. Le prix reste fixé par le joueur : à cours bas il peut le relever (tolérance du client).
- Répliques (florists, `customers.json > lines`) : `Game.customer_line(uid, kind)` avec `kind` = `greet | thanks | grumble | leave` (`""` pour les autres visiteurs : GDD 9). Visuel : `public_view` inchangé (mêmes clés pour tous) : `species` = `weeper` / `ploc` ; tells publics `veil`, `dripping` (Pleurnoïdes) et `tentacles`, `drooling` (Plocs) ; `face_id` récurrents `brumeline`, `sanglot`, `gloutonille`, `machouille` (l'interface retombe sur `look_seed` sans portrait fixe) ; `label` = « Visiteur d'ailleurs » ou « Client ».
- Événements (`events.json`) : nouvelles conditions `min_day`, `min_reputation`, `min_stems` (fleurs libres à l'air), `min_plants`, `min_queue_room` ; `max_per_day` (plafond quotidien, erreur `daily_cap`, aussi appliqué aux candidats des subs) ; `incident` {`stock_loss`, `suspicion`, `rate_shock`}. `Game.message("incident", {id, type, lost? | currency?, rate?})`.

### Employés (GDD 12) : `Game.employees` (`Employees`, `data/employees.json`)

- Déblocage (`settings.unlock`, toutes obligatoires) : extension **Étage** (`upstairs`, donne les emplacements `employee_slots`), réputation 30, chapitre `species`. `employees.hire_reasons()` -> `[{code: expansion|reputation|chapter|day|no_slot, text}]` (vide = possible). Frais d'embauche (`hire_fee`, catégorie `staff`, argent légitime) ; **salaire quotidien** inclus dans `Economy.upcoming_charges()` (clé `wages`, donc dans `charges_total()` et dans les charges du bilan) ; `last_report.wages = {total, details[{id,name,wage,unpaid_days}], quit[], earned[{id,name,tasks,earned}]}` ; impayé : dette (jamais de solde négatif).
- API : `Game.hire_employee(id)` -> `{ok, id, wage, fee}` ou `{error: unknown|already_hired|not_available (+days)|locked (+reasons)|no_slot|insufficient_funds}` ; `Game.fire_employee(id)` -> `{ok, severance}` ou `{error: not_hired|insufficient_funds}` ; `employees.candidates()` (`{id, name, role, role_label, role_description, station, trait, quirk, quality, speed, wage, hire_fee, hired, available, available_in_days, can_hire}`) ; `employees.view(id)` / `views()` ; `severance_for(id)`, `on_probation(id)`, `stuck()`, `recover(id)`. Signaux : `hired(id)`, `fired(id, reason)`, `task_started`, `task_finished`, `employee_blocked`, `employee_recovered`, `changed`.
- Licenciement : gratuit pendant `probation_days` (2), ensuite indemnité `severance_days` (2) x salaire (refus `insufficient_funds` si impayable) ; impayés pendant `quit_after_unpaid_days` (2) jours de suite : démission (`message("employee_quit")`) ; un partant est réengageable après `rehire_days` (4).
- Postes (`roles`) : `cashier` (sert les clients avec les bouquets déjà prêts, au prix <= prix conseillé, via `sell_bouquet_to` : mêmes règles ; réputation gagnée x `quality`), `caretaker` (range au frais les lots/bouquets les plus fatigués selon la capacité du frigo ; la fraîcheur n'est jamais touchée), `preparer` (résout les commandes simples avec `OrderSolver` et le stock **libre**, réserve ses composants via `Game.reserve_components("emp:<id>")`, compose avec `compose_bouquet(..., owner)`). Qualité et vitesse par employé ; bourdes drôles (`Game.message("employee_blunder", {id, name, text})`).
- Machine à états : `idle` -> `going` (marche en cases dans la boutique jusqu'au poste : comptoir, frigo, établi) -> `working` -> `idle`, ou `blocked`. Vue : `{id, name, role, state, cell:[x,y], station, task, target, progress 0..1, blocked_reason, note, stats, wage, severance, on_probation}`. Les employés ne travaillent que dans leurs `phases` (caisse et préparation : ouverture ; entretien : ouverture et nuit) ; entre les phases ils sont à la porte arrière (`cell` = porte `back`).
- **Bloqué par un meuble** : détecté immédiatement quand le plan change (`rooms.shop.changed`) ou en marchant : raisons `trapped` (meuble posé sur l'employé), `no_path`. Tâche annulée, réservations libérées, `Game.message("employee_blocked", {id, name, reason})`. Récupération : déplacer le meuble (libéré automatiquement), `employees.recover(id)` (retour à la porte, jamais bloquée) ou automatique après `unstick_seconds` (20). Poste de travail absent (meuble vendu) : l'employé attend, sans blocage.
- Aucune double consommation : cibles réservées (`employees.claims`, `claimed_by(key)`), composants réservés, revalidation de la cible à la fin de la tâche (si le joueur a servi le client avant, la tâche est annulée proprement). `Game.message("employee_blunder"|"employee_blocked"|"employee_recovered"|"employee_quit"|"staff_changed")`.
- Sauvegarde : clé `employees` {staff, gone} (tâches en cours reprises au chargement ; réservations orphelines libérées) ; absente = aucun employé. Outil de dev : `Game.dev.force_hire(id)` (sans conditions ni frais).
- `public_state().employees` : `{staff[], slots, free_slots, wages_total, can_hire, hire_reasons[texte], unlock{}, stuck}`. `capacity.employee_slots` existait déjà.

### Mode streamer (GDD 13) : `Game.streamer_mode`, `Game.subs` (`SubQueue`), `data/streamer.json`

- **Interrupteur** `Game.streamer_mode` (défaut `false`, sauvegardé, `message("streamer_mode", {on})`). Éteint : aucun sub n'entre (`push_sub` -> false) ni ne sort ; la file en attente est conservée. Simulateur local branché dessus : `Game.simulate_subs(count=-1)` -> `{ok, pushed, dropped}` ou `{error:"streamer_off"}` (vague de pseudos fictifs ; taille par défaut `balance.sub_queue.simulator.wave_size`) ; `Game.sim_subs_per_minute` (> 0 : arrivée automatique de subs fictifs) ; les outils de dev (`simulate_sub(s)`) allument le mode. **Aucune connexion réseau.**
- Limites configurables (`balance.sub_queue`) : `min_spacing_seconds`, `max_releases_per_minute` (3), `max_releases_per_cycle` (10), `max_releases_per_day` (24), `max_pending` (20 ; l'excédent est compté dans `dropped`), `wave_threshold` / `wave_window_seconds` / `wave_spacing_factor` (étalement : l'espacement s'allonge tant qu'une vague d'abonnements dure), `kind_weights` (événement ou client), `feed_size`.
- Un sub produit aléatoirement un événement **ou** un client dans la file extérieure, parmi les candidats dont les conditions sont réunies (chapitre, drapeaux, phase, stock, plants, place dans la file, plafond quotidien) ; aucun candidat : le sub reste en attente. `Game.message("sub_released", {name, kind, id, text})`.
- Pseudos : `SubQueue.make_pseudo(seed)` (liste `streamer.json > pseudos` + combinaisons préfixe/suffixe) ; `push_sub("")` en génère un. Fil d'activité : `subs.feed[]` `{name, kind, id, text, day}`.
- `Game.streamer_state()` = `public_state().streamer` : `{enabled, pending[], pending_count, max_pending, dropped, released_total, released_cycle, released_today, released_minute, caps{}, wave, next_release_in, blocked_by (off|empty|spacing|minute_cap|cycle_cap|day_cap), feed[]}`.
- Sauvegarde : `subs` (file, fil, fenêtres de liberation) + `streamer` {on, sim}.

### Autres changements du tour 6

- **Extensions de fin de partie** (`data/expansions.json`, sans nouvelle pièce de placement) : `gallery` Galerie d'art macabre (2500, réputation 45, +5 % clients, valeur +3), `warehouse` Entrepôt de fret (3000, réputation 55, stock +120, froid +24), `salon` Salon interstellaire (7000, chapitre `species`, réputation 80, **2e emplacement d'employé**, file +1, +8 % clients), `embassy` Ambassade galactique (18000, chapitre `galaxy`, réputation 130). Charges quotidiennes élevées (16 à 80 par jour) : puits d'argent légitime des parties longues. `Expansions.order()` compte désormais 10 entrées (l'écran d'extensions doit défiler).
- Un plan de pièce modifié (`Placement.changed`) rafraîchit la valeur perçue (`refresh_decoration`), ramène à l'air les tiges en trop si le frigo est retiré (jamais de `fridge_used > fridge_capacity`) et fait détecter les employés coincés.
- Aucun client n'est créé dans les 6 dernières secondes d'une phase (tirage automatique, subs, événements de type client : `trigger_event` renvoie `{error:"closing"}`) : un client par l'égout ou le portail met jusqu'à 5 s à arriver et se retrouvait en file après la fermeture.
- `Game.message` : nouveaux identifiants `streamer_mode`, `sub_released`, `incident`, `staff_changed`, `employee_blunder`, `employee_blocked`, `employee_recovered`, `employee_quit`.
