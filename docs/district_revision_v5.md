# Quartier, accès et modèles — révision 5

Cette version ouvre temporairement toutes les zones pour les essais. Elle ne marque pas les extensions comme achetées dans la sauvegarde. Le paramètre de lancement `--story-locks` rétablit les restrictions de progression ; le commutateur central est dans `src/core/review_access.gd`.

## Modèles et décor

- Chat debout et couché, pigeon, araignée, papillon et luciole repris dans Blender : silhouette, ailes, articulations, pattes et détails du visage. Les insectes sont agrandis dans les captures de présentation pour permettre leur inspection.
- Arbres de trois variantes avec ramifications et feuilles pliées, bacs avec terre, herbe, fleurs et feuilles mortes nervurées. Haies composées de feuillage plutôt que de simples boules. Bancs alignés sur les arbres ; bancs des jardins tournés vers leur cour.
- Deux nouvelles planches : immeuble R+5 et vitrine de boulangerie. Les images et prompts exacts se trouvent dans `art/concepts/district_v5`. Les modèles et leurs sources Blender sont dans `assets/models/street` et `art/blender/street`.
- Immeuble R+5 près du sous-sol, variantes R+3/R+4 pour le fond de place, bâtiments mitoyens et retours latéraux. Volumes solides pour empêcher de traverser les bâtiments et d'atteindre leur arrière.
- Vitrines garnies de pains, baguettes et croissants en géométrie 3D, étagères, verre et enseignes encadrées BOULANGERIE. Retrait des anciens panneaux et croisillons qui masquaient les produits.
- Façades du fleuriste harmonisées en vert, façade arrière habillée, étage placé au-dessus de la pièce principale. Fenêtre excédentaire de la remise supprimée et poteau blanc ajouté. Petites fenêtres de la maison d'angle remontées à l'étage pour dégager la porte.

## Circulation

- Ruelle de 11 m au total : chaussée à double sens de 6,8 m et deux trottoirs de 2,1 m. Même pavage que la rue principale. STOP et panneau sur la droite en remontant.
- Profil de pente raccordé à la route et à la place basse ; volumes de collision épais sous chaque segment. Accotements fermés et soubassements prolongés sous les façades.
- Trottoir autour de la place, y compris devant le sous-sol et entre jardins et stationnement. Les devantures des extensions déverrouillées sont déplacées hors de la ruelle.
- Escalier de cave au fond à droite du shop, contre le mur droit : largeur 1,05 m, course de 3 m, dénivelé de 4,2 m. Porte dans l'axe et parois montant jusqu'au plafond. Réservation du plancher et du plafond alignée sur cet accès.
- Plancher de soutien de la remise et du sous-sol, raccords des murs de cave refermés. Ancienne trappe et encadrements superposés retirés. Composteur visible dans le jardin ; bord côté ruelle planté de haies et d'arbres.

## Vérification

Les résultats détaillés sont conservés dans `out/district_v5_checks.json` et les journaux `out/district_v5_*.log`. Le contrôle ciblé vérifie les accès temporaires sans achat des extensions, la marche réelle dans les escaliers et à la remise, la ruelle, 49 points de support au sol, la présence du composteur et l'aller-retour à l'étage. Les tests généraux comptent 6 507 assertions sans échec.

La galerie contient 38 captures du moteur Godot, dont les animaux sur un plateau de présentation. L'exécutable Windows embarque ses ressources ; ses tests de démarrage sont exécutés depuis un autre répertoire, en mode sans écran et avec rendu Vulkan. Les avertissements de certificat Windows et les avertissements de nettoyage de la suite générale sont consignés dans les journaux ; ils ne sont pas comptés comme des validations visuelles.

Les feuilles et haies ont été allégées pour éviter une géométrie excessive ; l'immeuble utilise des biseaux simplifiés. Cette vérification ne remplace pas une mesure des performances sur la machine du joueur.
