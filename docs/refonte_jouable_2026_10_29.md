# Refonte jouable — demandes du 29 octobre 2026

Référence de travail : les demandes ci-dessous remplacent les anciennes hypothèses du prototype. Les parties existantes doivent rester lisibles ; le nouveau départ s’applique aux nouvelles parties.

## Critères d’acceptation

- Mesurer puis réduire les ralentissements, avec comparaison avant/après ; proposer des réglages graphiques.
- Sensibilité souris réglable dans les paramètres et conservée entre deux lancements ; valeur initiale réduite.
- Sous-sol conservé en mémoire, aucune reconstruction pendant le passage boutique/cave. Même principe pour les autres zones.
- Boutique au niveau 0 ; ruelle extérieure en cul-de-sac au niveau −1, sortie de la cave par une vraie porte interactive ; grande baie de vente, rideau métallique, comptoir actif à l’ouverture du commerce clandestin.
- Reprendre surtout le design des meubles et équipements du sous-sol (précision de l’utilisateur).
- Refaire la rue devant le fleuriste et les voitures ; vérifier terrasse, jardin et serre.
- Placement des meubles et équipements libre dans toutes les zones ; supprimer les emplacements imposés des bacs. Conserver la protection des passages.
- Nouvelle partie : boutique vide, budget initial limité. Tutoriel : téléphone → achat et paiement → cartons sur le trottoir → transport/déballage → placement du comptoir, caisse, établi, étagère de pots, pots et présentoir de bouquets. Poubelle extérieure pour jeter les emballages.
- Téléphone : écran d’accueil à icônes (fournisseur fleuriste, darknet, mini-jeu, statistiques). Fournisseur : onglets mobilier, décoration, pots/matériel, fleurs/graines. Objets verrouillés visibles en silhouette avec niveau requis.
- Établi : vue du vrai plan de travail et étagères de pots ; sélection des fleurs en pointant les pots. Sélection d’un rouleau puis utilisation des ciseaux ; longueur de papier choisie influant sur le coût et la valeur du bouquet.
- Histoire : trame existante (reprise, cave, clandestin, extraterrestres), à relier au tutoriel et aux déblocages.

## Constats initiaux mesurés

Sonde du sous-sol, 1920 × 1080, RTX 3070 Laptop : 4 941 appels de dessin, 6 308 objets rendus, 1 048 388 primitives, moyenne 136,3 i/s, 1 % bas 80,3 i/s. Ces chiffres sont ceux de cette machine et de cette vue, pas une garantie sur le PC du joueur. Effets activés simultanément : MSAA, SSAO, brouillard volumétrique, glow et ombres. La cave est instanciée et fusionnée à chaque entrée puis détruite à chaque sortie : défaut confirmé dans `main.gd`.

## Implémentation et vérification

- Fusion des maillages réactivée pour les GLB : les métadonnées d’import `extras` empêchaient la fusion. Les parties articulées restent séparées. Exemple : sol de cave, 436 → 7 maillages ; bac, 29 → 8.
- Sonde comparable du sous-sol sur RTX 3070 Laptop, 1080p : 4 941 → 1 798 appels de dessin, 136,3 → 299,8 i/s en moyenne. Le réglage équilibré coupe le MSAA, le SSAO et le brouillard volumétrique. Le nombre de primitives augmente avec la fusion (perte des LOD importés), mais les temps mesurés CPU/GPU baissent. Ce résultat concerne cette sonde, pas toutes les vues ni tous les PC.
- Sensibilité initiale divisée par deux. Paramètres persistants : sensibilité, trois qualités graphiques et résolution interne.
- Cave créée une seule fois au démarrage de la partie, conservée en mémoire. Vingt allers-retours vérifiés sans changement d’instance, environ 0,5 ms par aller-retour dans le scénario mesuré. Terrasse, jardin, serre et extensions restent dans la scène principale. Le premier démarrage reste plus coûteux ; l’interaction de la trappe déplace instantanément le joueur, et une rampe extérieure relie physiquement les deux niveaux.
- Ruelle en impasse à −4,2 m, porte utilisable des deux côtés, baie de vente et rideau métallique animé avec commande visible. Le commerce au comptoir exige l’ouverture du rideau. Son état est sauvegardé.
- Onze équipements de cave revus : bac, composteur, comptoir, armoire, pot individuel, deux lampes et quatre terminaux. Deux véhicules natifs ajoutés. Sources Blender éditables conservées.
- 257 références de fournisseur avec vignettes produites depuis les modèles réels ; accès vérifié côté logique, paiement, livraisons sur le trottoir, transport, déballage unique et élimination des cartons vides.
- Départ joueur vide avec 300 € et objectifs successifs jusqu’à la première vente. Les anciennes sauvegardes restent lisibles ; sélectionner « Nouvelle partie » pour tester ce départ. La découverte de la cave est précédée de la première vente de fleurs.
- Placement continu des biens achetés, rotation par pas de 15°, aimantation facultative à 5 cm, collisions et protection des passages. Mobilier existant déplaçable avec R ; pose et transformations sauvegardées. Les bacs n’utilisent plus de plots imposés. Les murs et ouvertures structurelles restent fixes.
- Les nouveaux comptoirs et postes de travail de la boutique sont inclus dans la navigation et les postes des employés. Cette navigation reste calculée sur les cellules de la boutique : vendre depuis un comptoir installé dans une autre zone ne dispose pas encore d’un routage commercial propre à cette zone. Les objets peuvent néanmoins y être placés.
- Téléphone : fournisseur à quatre onglets, darknet, jeu de mémoire et informations commerciales ; articles verrouillés en silhouettes avec niveau requis.
- Établi 3D : pots proches du poste, sélection au curseur, rouleaux, longueur tirée à la souris, ciseaux, bobine de liaison. Coût et prix tiennent compte du papier. Les fleurs sont prélevées exactement dans les pots choisis, avec fraîcheur et couleur conservées. Annuler ne consomme rien.
- Pots à graines de fleurs : semer, attendre la croissance et récolter. Pots de stockage : une variété et une couleur par pot. Vases décoratifs modifiables conservés dans le nouveau système de placement.

## Limites et points à tester en partie longue

Le réglage des ventes et de la progression demande encore une partie réelle prolongée. Les améliorations horticoles utilisent toujours les niveaux globaux de simulation existants ; elles ne simulent pas encore une couverture lumineuse ou une ventilation calculée équipement par équipement. L’histoire existante est reliée au nouveau départ, sans réécriture complète des dialogues. Les performances finales doivent être confirmées sur la machine du joueur, en particulier après plusieurs heures et avec beaucoup d’objets ajoutés.

Les tests de logique produisent encore des avertissements de ressources résiduelles à la fermeture du banc de tests, déjà présents avant cette refonte. Les résultats de logique et le démarrage de l’exécutable sont contrôlés séparément.

## Fichiers de contrôle

- `out/refonte_tests.log` : 6 341 assertions, aucun échec.
- `out/refonte_jouable_review/checks.json` et `index.html` : contrôles et captures du jeu réel ; le champ `passed` dépend de chaque résultat.
- `out/refonte_perf_baseline.log`, `out/refonte_perf_after.log` : mesures de la sonde.
- `out/windows_export_smoke.log` : contrôle de l’exécutable autonome depuis un autre répertoire.
- `build/windows/Fleuriste-Refonte.exe` : version Windows avec ressources intégrées.
