# Quartier et jardin — révision du 29 octobre 2026

## Modifications

- **Façades opposées au fleuriste** : remplacement de la rangée de cubes par quatre bâtiments natifs de 42 m de largeur totale, avec portes à échelle humaine, fenêtres encadrées, balcons, corniches, toits en pente, lucarnes, cheminées, gouttières et vitrines. Brique et pierre sont détaillées par un matériau de maçonnerie. Sources Blender éditables et GLB conservés dans `art/blender/street` et `assets/models/street`.
- **Circulation** : deux voies indépendantes, voitures et utilitaires en mouvement avec roues animées. Délais irréguliers et pauses entre groupes, flotte limitée à huit véhicules, suppression des véhicules en bout de parcours. Les voitures attendent lorsqu’un joueur est devant elles ; elles gardent une distance dans leur voie. L’ancienne camionnette immobile et son obstacle invisible sont retirés.
- **Police** : patrouilles marquées POLICE. La fréquence augmente avec les manifestations du système de suspicion existant, alimenté notamment par le dépassement de blanchiment et les nuisances de culture. Le niveau de boutique est repris dans le calcul de blanchiment. Aucun chiffre de suspicion n’est affiché au joueur ; un passage n’est pas un compte à rebours d’arrestation. Intervalles techniques : 150–240 s au plus faible palier, puis 90–140, 45–75 et 18–30 s ; premier passage possible après 50 s.
- **Ruelle** : anciennes barrières invisibles supprimées, nouvelles façades, corniches, fenêtres, descentes d’eau et bâtiments latéraux. Découpe du terrain élargie pour ne plus traverser les façades. Rampe de 24 m environ descendant de 4,2 m, raccordée à un palier bas sans ressaut vertical. Test de marche réelle du personnage dans les deux sens, avec gravité et collisions.
- **Se décoincer** : bouton dans la pause. Replace sur un passage vérifié libre, remet la vitesse à zéro et annule le placement ; un carton transporté est reposé. Aucun coût ni pénalité.
- **Arrière du terrain** : environ 280 m² au-dessus du sous-sol, dont une serre d’environ 76 m². Grande porte au nord de la boutique, allées dégagées, sol nuancé, terre, bordures et touffes d’herbe en MultiMesh. Jardin et serre sont construits et visitables dès le départ. Production, placement et organisation des équipements restent verrouillés tant que l’extension n’est pas achetée. Les tables ont été reculées pour dégager le passage de la porte de serre.
- **Bouche d’égout** : déplacée vers l’accès de la ruelle, en dehors du passage piéton ; points d’apparition et de départ correspondants mis à jour.
- **Téléphone** : coque, bordure, vitre intérieure, écouteur, caméra, boutons latéraux et barre inférieure. Cadre fixe de 640 × 1 000 unités, mis à l’échelle pour tenir dans la fenêtre. Seule la page interne défile ; une fiche longue ne peut plus déformer le téléphone. Contrôlé en 1 280 × 720, 1 600 × 900 et 1 920 × 1 080.
- **Placement** : R tourne de 90°, T de 180°, molette de 15° ; Ctrl active l’aimantation à 5 cm. Légende persistante en bas d’écran, état libre/bloqué. Un carton est refusé comme support et comme volume de chevauchement, même vide.
- **Aliens** : retirés des figurants de rue et de boutique. Pas de tirage automatique de jour ; visites clandestines la nuit, supprimées au matin. Les anciennes files sont conciliées à l’entrée dans le monde. Les récompenses uniques et les drapeaux de progression sont également accordés après une vente nocturne, sans duplication.

## Vérification

- `out/street_v2_tests.log` : 6 507 assertions réussies, aucun échec. Les avertissements de ressources en fin de banc de tests étaient déjà présents ; le contrôle de l’exécutable est séparé.
- `out/street_garden_revision_review/checks.json` : 56 contrôles de rendu, d’interface, de portes, de placement et de trafic.
- `out/street_garden_revision_review/walk_checks.json` : sept étapes parcourues par le véritable CharacterBody3D, de la rue à l’impasse puis retour ; aucun blocage.
- `out/street_garden_revision_review/index.html` : captures et animation de circulation provenant du moteur.
- `out/windows_quartier_smoke.log` et `out/windows_quartier_graphics.log` : contrôle de la version Windows autonome depuis un répertoire extérieur au projet.

## Fichiers pour tester

`build/windows/Fleuriste-Quartier.exe` contient les modèles et les données. Fermer l’ancienne version avant de l’ouvrir. « Continuer » permet de retrouver sa progression ; « Nouvelle partie » permet de tester le départ vide. Le jardin et la serre sont visibles dans les deux cas, leur usage dépend toujours des déblocages.

Le comportement détaillé des arrestations reste celui du système de police existant ; cette révision ajoute le signal visuel des patrouilles et ne remplace pas l’enquête par une jauge publique.

## Planche et génération

Planche finale : `art/concepts/street/opposite_buildings_sheet.png`.
Génération avec l’outil intégré **imagegen**. Prompt : [street_architecture_prompt.txt](../art/concepts/street/street_architecture_prompt.txt).
Modélisation déterministe : `tools/blender/street_architecture_v2.py`.
