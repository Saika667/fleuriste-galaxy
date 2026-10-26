# Jeu du fleuriste — Cahier de conception

Version 0.1 — 22 octobre 2026

Ce document rassemble les décisions prises avec le créateur et une proposition de réalisation. Les éléments signalés « proposition » ou « provisoire » restent à valider en jouant. Aucun nom définitif n’est fixé.

## 1. Intention

Le joueur incarne une fleuriste qui reprend une boutique et découvre son secret : une cave destinée à une activité clandestine. Il développe une entreprise à double activité, compose des bouquets et gère des incidents de plus en plus absurdes. La réputation de ses productions finit par attirer des clients extraterrestres.

Les plaisirs principaux sont l’optimisation de l’entreprise et les situations chaotiques et drôles. La décoration soutient ces deux axes. Le ton est cartoon, macabre et absurde. Les personnages, espèces, dialogues et éléments visuels seront originaux.

Objectif de campagne accepté dans son principe : devenir une adresse reconnue à travers la galaxie. Les conditions exactes de victoire restent à concevoir. La partie peut continuer après cet objectif.

## 2. Direction de réalisation proposée

- Jeu solo pour PC Windows, clavier et souris.
- Godot avec GDScript ; version stable précise à fixer au lancement du projet.
- 3D stylisée, vue à la première personne.
- Établi avec vue rapprochée pour les bouquets.
- Mode placement pour agencer les espaces.
- Dialogues écrits courts, sans doublage obligatoire.
- Sauvegarde locale avec copie de secours.

La plateforme, le moteur et la caméra constituent les recommandations issues du cadrage. Ils ne correspondent pas à un projet déjà installé ou développé.

Le développement doit pouvoir être piloté par fichiers, scripts et commandes. Le créateur ne doit pas avoir à programmer ni assembler manuellement des scènes. Les essais de jeu et les décisions artistiques restent nécessaires ; une validation automatique ne prouve pas qu’une mécanique est agréable.

## 3. Cycle de jeu

1. Préparation sans chronomètre : achats, réception, entretien, compositions anticipées, prix et aménagement.
2. Ouverture : horloge active, clientèle fleuriste, commandes et incidents. Quelques visiteurs clandestins peuvent se présenter en journée.
3. Bilan : recettes, charges, état du stock, décisions économiques quotidiennes et achats.
4. Nuit : activité clandestine principale, entretien du sous-sol, ventes et événements.
5. Fin du cycle et sauvegarde.

Proposition provisoire : un cycle actif complet de 25 à 30 minutes, hors phases de respiration. La répartition jour/nuit sera ajustée après essais. Les menus de pause et les écrans de préparation doivent indiquer clairement si le temps est arrêté.

Le joueur doit arbitrer entre servir, préparer, entretenir et répondre aux incidents. Le temps de déplacement est un coût que l’agencement permet de réduire.

## 4. Boutique et extensions

Espaces prévus : pièce principale, terrasse, remise, jardin, serre, étage, agrandissement de la pièce principale et cave. Leur ordre exact et leurs prix restent provisoires.

La cave se débloque obligatoirement par l’histoire. Les autres espaces élargissent les capacités et les choix du joueur.

Le placement des meubles doit préserver les accès, les portes et les chemins des clients. Prévoir rotation, aperçu de placement, validation visible et déplacement des objets déjà posés.

La décoration influence la satisfaction des clients et la valeur perçue. Éviter qu’empiler le même objet décoratif soit la meilleure stratégie : proposition de rendements décroissants et de prise en compte de la circulation et de la variété.

## 5. Bouquets et commandes

Le joueur assemble les bouquets tige par tige. La disposition précise est esthétique ; elle ne nécessite pas un algorithme de jugement de la forme.

Les quatre critères sont :

- Respect de la demande.
- Harmonie des couleurs.
- Fraîcheur des composants.
- Présentation : emballage et accessoires adaptés.

Deux types de demandes : commandes précises et intentions à interpréter. Plusieurs compositions doivent satisfaire une intention. Les règles évaluables sont définies dans les données des commandes ; leur formulation doit donner au joueur assez d’indices pour comprendre le résultat.

Les bouquets peuvent être fabriqués sur commande ou à l’avance, puis exposés et vendus. Une composition anticipée conserve sa liste de composants, son coût, son prix et sa fraîcheur.

Les fleurs et bouquets fanent à l’air libre. Un réfrigérateur ralentit ce processus sans l’annuler. Sortir un bouquet du réfrigérateur ne réinitialise jamais sa fraîcheur. Les durées et capacités sont à équilibrer.

Proposition d’interaction : placement assisté des tiges et aperçu immédiat, sans simulation physique complexe obligatoire.

## 6. Approvisionnement et prix

Les fleurs proviennent de livraisons, du jardin ou de la serre. Le stock suit au minimum la variété, la quantité, la qualité et la fraîcheur.

Le joueur fixe librement le prix de vente. Le prix recommandé prend en compte les composants, la réputation et la décoration. Proposition : afficher séparément le coût des composants et le prix recommandé pour rendre la marge compréhensible.

Le prix demandé influence l’acceptation et les attentes du client. Une vente ne doit jamais créer d’argent ni consommer des composants deux fois en cas de double interaction.

La boutique est à peine rentable au début, après charges et pertes normales. Elle doit rester intéressante et pouvoir se remettre d’une mauvaise journée. Sa croissance, ses clients et ses compositions apportent des objectifs propres.

Charges prévues : énergie, taxes fictives et frais de fonctionnement. Loyers éventuels, fréquence des paiements et tarifs restent à définir. Toute échéance doit être annoncée à l’avance et visible dans le bilan.

## 7. Deux économies

Deux soldes distincts sont toujours lisibles : argent utilisable pour la boutique et argent clandestin.

- Les ventes florales alimentent le premier solde.
- Les ventes clandestines alimentent le second.
- L’argent clandestin achète directement les améliorations liées à cette activité.
- Les achats du fleuriste nécessitent des recettes légitimes ou des fonds convertis par la mécanique fictive de couverture.

La conversion est une décision quotidienne rapide depuis la gestion. Elle s’appuie sur une capacité commerciale fictive dépendant de l’activité réelle, de la réputation et du développement de la boutique. Dépasser cette capacité augmente le risque d’incidents et d’enquête.

Cette mécanique reste abstraite, avec des règles propres au jeu. Les coefficients doivent être réglables dans les données. Aucun pourcentage de risque ni jauge de suspicion n’est montré au joueur.

Des événements imprévus peuvent modifier temporairement les conditions et provoquer des choix. Leurs conséquences doivent rester cohérentes avec les signaux donnés au joueur.

## 8. Cave et cultures

Un bac contient au maximum quatre plantes. Chaque emplacement possède son état ; un bac partiellement rempli est autorisé.

La cave accueille des améliorations de capacité, d’entretien, de maîtrise des nuisances et de sécurité. Les besoins de culture sont simplifiés et fictifs. Les paramètres précis de croissance seront définis pour le rythme du jeu.

Une installation surchargée par rapport à ses équipements peut produire des signaux : fumée verte occasionnelle, bruits, remarques de visiteurs et réactions du voisinage. Le joueur doit apprécier lui-même la situation.

La qualité des productions peut être améliorée par le compost macabre, des plantes extraterrestres ou des équipements coûteux. La progression sans tuer reste possible, mais plus longue et plus exigeante.

## 9. Suspicion et police

Aucune jauge visible. Le jeu utilise un état interne pour assurer la cohérence de ses conséquences.

Sources de signaux prévues : activité commerciale incohérente avec le développement de la boutique, nuisances de la cave, témoignages et incidents.

Manifestations : véhicule qui revient, remarques des clients, changement de comportement et visites particulières. Une action risquée doit laisser une possibilité raisonnable de percevoir ses conséquences avant une sanction importante.

Les policiers en civil constituent une rencontre de dialogue et de décision commerciale. Ils ne sont pas traités comme des voleurs à combattre.

Les dialogues proposent peu de choix et restent rapides. Le joueur peut refuser une vente, avec des réponses commerciales courtes. Aucun indice isolé ne doit identifier automatiquement un policier. Les clients ordinaires peuvent partager certains comportements ; refuser des clients a des conséquences commerciales.

Sanction décidée : confiscation du cannabis en cours de croissance et amende. Les extensions et équipements ne sont pas supprimés par cette sanction.

À fixer par essais : montant de l’amende, traitement d’un solde insuffisant et délai de récupération. Le joueur doit pouvoir continuer sa partie après une sanction.

## 10. Voleurs, combat et compost

Des voleurs peuvent se mêler à la clientèle clandestine et tenter de voler dans la cave. Des armes se débloquent progressivement, notamment une batte puis des armes à feu.

Le combat est une mécanique récurrente. Le style reste cartoon macabre et absurde : réactions exagérées et effets visuels cohérents avec cette direction.

Le composteur transforme les corps en ressource donnant un bonus à la qualité des productions. Ses valeurs, sa capacité, ses délais et ses complications sont encore à concevoir.

Règle d’équilibrage : les plantes extraterrestres et les équipements coûteux permettent une progression complète sans tuer. Éviter que le même incident puisse générer des ressources à l’infini ou qu’un personnage indispensable disparaisse sans solution de remplacement.

## 11. Clients et extraterrestres

La clientèle est humaine au début. Une cinématique introduit le premier extraterrestre, venu après avoir entendu parler des productions sur sa planète.

Les espèces suivantes ont des formes, looks, demandes, monnaies, plantes et incidents variés. Chaque nouvelle espèce doit ajouter au moins une différence de jeu identifiable, sans imposer un système entièrement nouveau à chaque apparition.

Voies d’arrivée prévues : rue, bouche d’égout et apparition via un personnage interdimensionnel. Les arrivées spéciales rejoignent ensuite un parcours et une file gérables par le jeu.

Les dialogues et comportements utilisent des définitions de clients et d’événements plutôt que des scripts distincts pour chaque visiteur.

## 12. Employés

L’embauche intervient plus tard dans la progression. Les postes, salaires et conditions de déblocage restent à définir.

Propositions initiales : caisse, entretien des fleurs et préparation de commandes simples. Les employés utilisent les mêmes stocks et règles économiques que le joueur.

Le système doit gérer les réservations de tâches pour éviter que deux personnes consomment les mêmes composants. Un employé bloqué par un meuble doit être détectable et récupérable.

## 13. Mode streamer

Un sub produit aléatoirement un événement ou un client dans la file d’attente à l’extérieur du magasin.

Prévoir une file d’événements persistante pendant la session, un espacement des déclenchements et des limites configurables pour absorber les vagues d’abonnements. Le hasard ne doit pas créer un événement dont les conditions ne sont pas réunies.

La plateforme de streaming reste à confirmer. Développer d’abord un simulateur local de subs ; la connexion réelle viendra ensuite avec les autorisations du compte concerné. Les pseudos visibles et les messages de viewers ne sont pas encore décidés.

## 14. Progression narrative proposée

1. Reprise de la boutique et apprentissage du fleuriste.
2. Découverte du secret et acquisition obligatoire de la cave.
3. Première activité nocturne et apprentissage des deux économies.
4. Agrandissements, nuisances, voleurs et premiers contrôles.
5. Cinématique du premier client extraterrestre.
6. Nouvelles espèces, plantes, équipements et personnel.
7. Objectif de réputation galactique, puis poursuite libre.

Cette séquence est une proposition de rythme, pas un nombre de niveaux fixé. Les déblocages utilisent des conditions explicites et testables.

## 15. Organisation technique

Séparer les systèmes de temps, inventaire, économie, commandes, cultures, clients, événements, progression et sauvegarde. Les contenus et les paramètres d’équilibrage sont définis dans des ressources éditables.

Toute transaction valide ses conditions avant de modifier les soldes et stocks. Les événements possèdent un identifiant pour éviter les récompenses en double. La sauvegarde conserve les bouquets, plantes, meubles, clients nécessaires et conditions de progression.

Prévoir des outils de développement pour avancer le temps, simuler un sub, déclencher une visite, remplir un stock et atteindre un chapitre. Les informations internes de suspicion sont accessibles uniquement dans ces outils.

Choisir une version stable du moteur, la documenter et éviter les changements de version pendant une étape de réalisation. Les ressources externes doivent avoir une provenance et une licence enregistrées.

## 16. Première version jouable complète

La vision finale reste celle de ce document. La première livraison doit démontrer une boucle jour/nuit dans un périmètre réduit :

- Une boutique, un établi, un réfrigérateur, une porte arrière et une cave.
- Quelques fleurs, deux types de demandes et assemblage libre.
- Stock, fraîcheur, prix libres, ventes et charges.
- Un bac pouvant accueillir de zéro à quatre plantes.
- Deux soldes et une décision quotidienne de conversion fictive.
- Clients, file d’attente et dialogues courts.
- Un signal de nuisance, une visite policière et la sanction prévue.
- Un incident de voleur, une interaction de combat simple et le composteur.
- Un premier client extraterrestre et une alternative de qualité sans tuer.
- Placement de quelques meubles.
- Simulation locale d’un sub.
- Sauvegarde, chargement et exécutable Windows.

Les extensions, nombreuses espèces, armes supplémentaires, employés et connexion streaming réelle se construisent ensuite sur cette boucle. Les premiers graphismes peuvent être provisoires, mais doivent permettre de lire toutes les interactions.

## 17. Vérifications avant livraison

- Parcourir une journée et une nuit sans blocage.
- Composer et vendre un bouquet précis, puis satisfaire une demande d’intention.
- Constater le vieillissement et le ralentissement au réfrigérateur.
- Vérifier qu’un cinquième plant ne peut jamais entrer dans un bac.
- Vérifier que l’argent clandestin ne paie pas directement un meuble fleuriste.
- Déclencher une sanction et vérifier la confiscation, l’amende et la poursuite de partie.
- Vérifier qu’aucune jauge de suspicion n’apparaît dans l’interface normale.
- Tester un refus de vente et ses conséquences.
- Tester les deux voies d’amélioration de qualité, avec et sans tuer.
- Simuler plusieurs subs rapprochés et vérifier le traitement de la file.
- Sauvegarder puis charger en conservant les soldes, plantes, bouquets et placements.
- Jouer une session avec l’exécutable exporté, en complément des vérifications automatiques.

## 18. Informations encore nécessaires avant le choix des performances cibles

La configuration du PC n’a pas été fournie. La version du moteur, les réglages graphiques et les objectifs de performance seront choisis après vérification de l’environnement de développement.

Les noms, prix, durées, salaires, coefficients, taille des files et probabilités restent des paramètres à régler. L’agent peut proposer des valeurs initiales, les documenter et les faire évoluer à partir des essais, sans demander une validation pour chaque chiffre.
