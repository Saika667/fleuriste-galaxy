# Protocole du critique

Barre de qualite : **Dave the Diver** (Mintrocket), captures officielles dans `bar/dave-the-diver/` (sources : `bar/SOURCES.md`).

## Role et isolation
- Le critique est un **agent distinct, en contexte neuf** : il n'a vu ni le code, ni les intentions du constructeur, ni l'historique des essais.
- Il recoit uniquement un dossier de paire contenant `A.png` et `B.png`. Il ne lit jamais le fichier de cle (`*.key.json`) ni `bar/`, ni les noms de fichiers sources.
- Il est hostile par defaut : son travail est de trouver pourquoi le jeu perd, pas de l'encourager.

## Preparer une paire (orchestrateur)
1. `tools\screenshot.ps1 -Scene res://... -Out out\jeu.png` (1920x1080, fenetre GPU ; la fenetre peut rogner quelques pixels de hauteur).
2. `tools\blind_pair.ps1 -Game out\jeu.png -Bar bar\dave-the-diver\<capture>.jpg -PairDir out\pair01 -KeyFile out\pair01.key.json` (la cle doit etre hors du dossier de paire).
3. Choisir une capture de la barre de meme type que celle du jeu (jour/nuit, gestion, exploration, UI), a nombre egal de paires par categorie.
4. Lancer le critique avec uniquement `out\pair01\`.

## Procedure du critique
1. **Ouvrir reellement** `A.png` et `B.png` (outil de lecture d'image). Interdit de juger sur description ou sur du code.
2. Comparer a l'aveugle sur la grille ci-dessous.
3. Rendre exactement ce format :
   - `Verdict : A` ou `Verdict : B` (celle qui est le meilleur jeu commercial). Jamais de note, jamais d'ex aequo, jamais de « ca depend ».
   - `Ecart unique le plus grand : <une phrase concrete, localisable dans l'image>`.
   - Un court constat par critere de la grille (une ligne chacun, A vs B).
4. Il ne propose pas de correctif detaille ; il nomme l'ecart.

## Grille (moitie subjective, a l'aveugle)
- **Lisibilite** : on comprend l'action, les objets cliquables, la hierarchie a 1 seconde ; contraste, taille du texte, bruit visuel.
- **Charme / ton cartoon absurde** : personnalite des formes, humour visible, proportions, expressions ; pas de look generique d'assets.
- **Coherence de palette** : peu de teintes dominantes, valeurs maitrisees, accent clair, aucune texture ou couleur etrangere.
- **Profondeur de l'UI de gestion** : densite utile d'informations (stocks, commandes, prix, employes), niveaux d'amelioration visibles, sensation de systemes imbriques sans surcharge.
- **Sensation de boucle jour/nuit** : l'eclairage, l'ambiance et l'UI signalent clairement la phase et son enjeu ; contraste jour/nuit marque.

## Decision de la boucle (orchestrateur)
- Apres le verdict, l'orchestrateur ouvre la cle et note si le jeu etait A ou B.
- Le jeu **gagne** quand le critique le designe sur plusieurs paires successives et variees (au moins 3 categories, jamais une seule categorie) ET que toute la moitie mesurable ci-dessous passe.
- Sinon l'ecart nomme devient la tache suivante du constructeur. Ne jamais reveler la cle au critique, ni lui dire quelle position etait le jeu apres coup pour la paire suivante.

## Moitie mesurable : verification avant livraison (§17 de docs/gdd.md)
Chaque point est un test automatise ou une session scriptee, passe/echec, preuve jointe :
- [ ] Parcourir une journee et une nuit sans blocage.
- [ ] Composer et vendre un bouquet precis, puis satisfaire une demande d'intention.
- [ ] Constater le vieillissement et le ralentissement au refrigerateur.
- [ ] Verifier qu'un cinquieme plant ne peut jamais entrer dans un bac.
- [ ] Verifier que l'argent clandestin ne paie pas directement un meuble fleuriste.
- [ ] Declencher une sanction et verifier la confiscation, l'amende et la poursuite de partie.
- [ ] Verifier qu'aucune jauge de suspicion n'apparait dans l'interface normale.
- [ ] Tester un refus de vente et ses consequences.
- [ ] Tester les deux voies d'amelioration de qualite, avec et sans tuer.
- [ ] Simuler plusieurs subs rapproches et verifier le traitement de la file.
- [ ] Sauvegarder puis charger en conservant les soldes, plantes, bouquets et placements.
- [ ] Jouer une session avec l'executable exporte, en complement des verifications automatiques.
