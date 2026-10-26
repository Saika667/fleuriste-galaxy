# Progression de la gauntlet loop

Barre : Dave the Diver (captures officielles dans `bar/dave-the-diver/`). Objectif : première version jouable complète (§16 du GDD).

## État technique (23 octobre 2026)
- Godot 4.7.2 stable, GDScript, dans `tools/godot-4.7.2/`. Modèles d'export Windows installés.
- Tests : `powershell -File tools\run_tests.ps1` → 2759 vérifications, 0 échec.
- Exécutable : `build/windows/Fleuriste.exe` (106,8 Mo), démarre et reste vivant.
- Capture d'écran : `tools\screenshot.ps1 -Scene res://... -Out ... -Frames N`.

## Scores de la critique à l'aveugle (jeu / paires)
| Tour | Monde 3D | Cave | Interface + établi | Total |
|---|---|---|---|---|
| 1 | 0/3 | 0/11 | 1/10 | 1/24 |
| 2 | 1/8 | 4/11 | 5/10 | 10/29 |
| 3 (protocole durci) | 2/6 | 5/7 | 3/5 | 10/18 |
| 4 (question neutre, sans biais de genre) | 2/6 | 4/7 | 1/5 | 7/18 |

Réserves : la barre n'a aucune boutique de fleuriste ni écran de gestion détaillé, donc les paires sont inéquitables par construction. Au tour 3 la consigne « meilleure image d'un jeu de gestion cartoon fini » favorise le jeu face aux images sombres d'exploration sous-marine de la barre : les victoires de la cave sont à pondérer.

Lecture du tour 4 : la baisse n'est pas forcément un recul. La question du tour 3 (« jeu de gestion cartoon ») favorisait le jeu face aux images sombres de la barre ; le tour 4 la neutralise, et 18 paires par tour avec des critiques différents donnent beaucoup de bruit. Mais un vrai défaut est apparu : les visages du tour 4 (têtes agrandies, grandes bouches) ont produit un effet « poupées / clowns » jugé dérangeant en boutique.

## QA de bout en bout (tour 4)
- Robot sur la vraie scène (`tools/e2e_play.gd`, `tools/e2e_run.ps1`), fuzz du cœur (`tests/test_fuzz.gd`). Détails : `docs/qa-report.md`.
- 11 bugs du cœur corrigés avec tests (chargement depuis la pause, autosave bloquante, récompense d'alien en double, inflation de réputation par les subs, voleur jamais résolu, etc.).
- 4 bugs d'autres zones corrigés ensuite : polygone dégénéré dans les portraits (54 à 56 erreurs moteur par lot de parties → 0), avertissement « DevTools désactivés » dans l'exécutable, Échap traité deux fois dans la cave, paiement de bac avant vérification du plafond.
- Dernier lot : 8 parties de 10 jours, 0 échec, 0 erreur de script. Tests : 2836, 0 échec. Exécutable relancé 20 s sans aucun avertissement.
- Performance mesurée (RTX 3070 Laptop, 1920x1080) : 106 à 109 images/s en moyenne, minimum 66, environ 3000 draw calls.
- Équilibrage observé : jour 1 à -73, puis rentabilité qui grimpe vite (jour 10 : ~530 €/jour de net et ~2800 € en caisse) faute de puits d'argent : les extensions du GDD (terrasse, jardin, serre, étage) ne sont pas implémentées.

## Tour 5 : visages sobres, extensions de boutique (état final au 23 octobre 2026)
- Visages : têtes à échelle 1,06-1,15, yeux nets, sourire discret, plus de joues roses ni de grande bouche (jugement sur captures, non re-soumis à la critique aveugle).
- Extensions (`src/core/expansions.gd`, `data/expansions.json`) : terrasse, remise, jardin, serre, agrandissement, étage, payées en argent légitime uniquement, avec charges quotidiennes annoncées. Caisse au jour 10 avec le robot QA : ~2680 € → ~300 à 730 € (6 à 10 graines), sans effondrement.
- Interface : écran « Agrandir la boutique » (touche X, tuile de la barre, bouton du bilan). Monde : file jusqu'à 8 clients, pièces achetées visibles, placement de meubles dans les nouvelles pièces.
- Le robot e2e n'était pas à l'abri d'une course (bilan fermé par lui-même, nœud libéré) : corrigé dans `tools/e2e_play.gd`. Ce n'était pas un bug du jeu.
- Vérifications finales : 3098 tests, `tools/ui_test.gd` 37/37, 9 parties e2e de 10 jours sans échec après correction, exécutable (107 Mo) 25 s sans aucun avertissement.
- Performance (RTX 3070 Laptop, 1080p, machine calme) : base 81-85 i/s moyens (minimum 57,6) ; tout acheté + file de 8 : 67-78 i/s moyens, minimum 44,3 en vue de rue (~2940 draw calls). À optimiser (fusion de maillages, instanciation) avant une machine plus faible.

## Écarts restants (tour 3, toujours valables au tour 4)
1. Boutique de jour : lumière plate et orange uniforme, personnages sans visage lisibles comme des mannequins, sol orange immense, peu de vie à 12:00.
2. Rue : personnages en silhouettes sombres sans visage qui écrasent la scène.
3. Boutique de nuit : violet uniforme, personnages verdâtres sans relief, surfaces mal séparées.
4. Fumée de la cave : deux grandes tables vides au premier plan, nuage qui noie le centre.
5. Alien : couloir presque vide, escalier orange plat.
6. Écrans de gestion (bilan) : corrects mais plats, sans scène vivante derrière.

## Reste à faire pour le §16
- Session de jeu complète à la souris avec l'exécutable (jamais faite).
- Voleur : phases de combat reliées à la cave (fait), équilibrage réel à tester en jeu.
- Mode streamer : simulateur local fait, connexion réelle hors périmètre.
