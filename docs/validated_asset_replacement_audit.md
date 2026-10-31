# Audit des remplacements validés

Cette passe vérifie les chemins réellement utilisés dans le jeu, y compris l’achat et le déplacement des meubles. Elle complète la collection de surface existante.

| Ensemble | Éléments | Correction |
|---|---|---|
| Mobilier acheté ou déplacé | Banc, parasol, bac de culture et composteur | Modèles natifs, y compris le chemin de construction utilisé par l’achat et le déplacement. |
| Variantes de contenants | Vases bleu et vert, seaux Soldes funèbres et Mordent un peu | Suppression des anciens contenants simplifiés ; fleurs natives et contenus séparés. |
| Plante verte générique | Ancien petit pot à feuilles en ellipsoïdes | Réutilisation à petite échelle de la plante verte validée. |
| Annexe et étage | Deux fenêtres et deux suspensions | Encadrements modelés, moulures, croisillons, appuis et quincaillerie ; suspensions validées. |
| Balcon et palier | Sol, six rambardes du balcon, deux du palier, trois jardinières, deux lanternes | Modèles de la collection validée ; nouvelles fleurs natives et suppression des doublons. |
| Chevalet extérieur | Cadre et décor, état ouvert/fermé et file | Cadre botanique modelé ; inscriptions et nombre toujours pilotés par le jeu. |
| Jardinières de façades | Anciens bouquets de sphères | Remplacement par les fleurs cartoon natives déjà créées. |
| Bureaux des employés | Ancienne géométrie masquée sous les modèles nouveaux | Suppression du doublon ; noms et statut des employés conservés. |

## Livrables

Cinq GLB et cinq sources Blender complémentaires : garden_bench, workshop_window, pavement_board, bucket_clearance, bucket_biting, dans assets/models/completion et art/blender/completion. Les autres remplacements réutilisent les modèles des bibliothèques surface, shop, cellar et flowers. Le banc, les fenêtres et le chevalet sont des compléments suivant la palette botanique validée ; les deux seaux suivent le modèle validé des seaux fleuris.

Les dix types de mobilier connus du catalogue passent par des GLB natifs. Les contenus des vases et des seaux restent séparés de leur contenant. Les emprises, interdictions de chevauchement et données de sauvegarde existantes restent pilotées par les systèmes de placement du jeu.

## Validation

6 302 tests réussis, zéro échec. Dix-huit contrôles ciblés réussis : dix constructeurs de mobilier, deux variantes de vases, deux seaux avec sept fleurs, achat/placement du banc et du parasol, panneau dynamique et deux fenêtres natives conservées après fusion des maillages. La vérification des interactions de surface confirme les 18 surfaces, les portes, l’ouverture du stock et de l’atelier, puis l’achat et le déplacement d’un vase sur une étagère de remise.

Sept captures en situation et onze présentations isolées face/dos proviennent du véritable jeu Godot. La session de contrôle utilise user://review_validated_replacements.json, distincte de la sauvegarde normale. Les avertissements de ressources au terme du lanceur de tests existaient déjà ; aucun échec de test ni erreur de script dans les exécutions finales.

## Limites de cette passe

Les murs, sols et volumes structurels conservés sont ceux du plan approuvé. Les quatre extensions galerie, entrepôt, salon et ambassade restent des devantures avec leurs bonus existants ; aucun nouvel intérieur n’a été validé. La rue conserve ses véhicules et personnages d’ambiance hors des planches de cette collection.

## Reproduction

Blender : tools/blender/completion_collection.py. Puis import Godot, scène scenes/shop/shot_completion.tscn, et tools/package_validated_replacements.py. Contrôles d’interaction : scenes/shop/shot_surface_remodel.tscn avec l’argument utilisateur checks_only. Galerie : out/validated_replacements_review/index.html.
