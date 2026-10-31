# Révision du quartier — 30 octobre 2026

## Rue et place basse

- Lampadaires en fonte à base moulurée, fût cannelé, col de cygne et lanterne ; rapprochés des bordures. Même dallage et mêmes bordures sur les deux trottoirs.
- Entrées avec moulures, pilastres, imposte, poignées, boîte aux lettres et numéro. Volets à lames inclinées, montants et ferrures. Architecture reprise dans les maisons voisines et le long de la pente, avec des couleurs variées.
- Boulangerie : vitrine à montants, pains visibles derrière le verre, lettrage doré, bandeau BOULANGERIE lisible, auvent rayé, lambrequin et supports ; enseigne suspendue supplémentaire.
- Arbres et bancs ajoutés sur les trottoirs. Passants humains intermittents sur le côté opposé ; certains traversent le passage piéton. Les voitures cèdent le passage.
- Bouche d’égout en fonte détaillée déplacée sur la chaussée, près de la ruelle et hors du passage piéton.
- Place basse agrandie : stationnement, maisons sur plusieurs côtés, jardins arrière clôturés et grande poubelle municipale utilisable. L’égout précédemment intérieur y est déplacé, avec ses animations d’arrivée conservées.
- Raccord de la pente à un palier plat élargi ; façades en volume et maison de service haute pour fermer le vide près de la remise. Ancien mur plat et graffiti retirés.
- Poubelles avec couvercle, poignée, roues, nervures et symbole de recyclage, sans inscription « poubelle ».
- Voiture de police noire et blanche, portes blanches, poignées, séparations, écussons, antenne, marquage POLICE et rampe lumineuse bleue et rouge. Fréquence toujours liée aux indices de suspicion.

## Déplacements et aménagement

- Escalier intérieur du sous-sol : 28 marches, rampe de collision continue, parois latérales, ouverture réelle du mur et du plafond et découpe du plancher de la boutique. Aucun changement de scène sur cet accès.
- Un bac d’origine a été décalé hors de ce nouveau passage. L’étage et son escalier sont visibles avant achat ; la montée reste verrouillée par l’histoire et fonctionne après déblocage.
- Boutique ouverte sur les 30 m² de l’annexe, soit environ 110 m² au sol. Les équipements de l’extension restent désactivés avant leur déblocage.
- Suppression des raccords arrondis visibles entre pans de mur ; papier peint découpé autour de la porte du jardin ; jambage rapproché de l’encadrement et décoration déplacée hors de l’ouverture.
- Remise avec parois opaques et toit complet incliné. Portes articulées et étagères accessibles conservées.
- Jardin porté à environ 435 m², allées conservées, plantations irrégulières et suppression des bacs bloquants. Les touffes utilisent exactement la même fonction de couleur que le sol. Composteur déplacé au jardin et remplacé par un modèle à lattes ventilées, couvercle, ferrures, trappe et symbole de recyclage.
- Saut avec Espace, uniquement quand le joueur est au sol et actif.
- Port simultané de deux cartons pleins et cinq vides ; empilement visible, ouverture du dernier, dépôt sur le véritable support visé et recyclage groupé. La grande poubelle peut aussi supprimer un meuble acheté en cours de déplacement.
- Placement vérifié dans le volume 3D : un meuble peut passer sous une étagère haute ; une intersection réelle reste refusée. Réservation de la cage d’escalier et des accès.
- Aperçu légèrement teinté vert ou rouge, restauré après annulation. Barre horizontale avec pictogrammes d’angle droit et de rotation, R 90°, T 180°, molette, clic et Échap. Explication détaillée affichée une fois et mémorisée dans la progression.

## Sous-sol et interfaces

- Squelette refait : cavités orbitales creusées, nez, mandibule, dents, clavicule, côtes courbes, sternum, vertèbres, bassin ajouré, sacrum/coccyx et os distincts des bras, mains, jambes et pieds.
- Champignons refaits avec pieds courbes, chapeaux bombés, rebords, lamelles radiales et taches. Les achats du catalogue réutilisent les nouveaux modèles.
- Plafond revêtu comme les murs, sans ancien plafond blanc ni poutres en bois. Deux bouches filtrantes au centre, réseau métallique transversal et longitudinal, éclairage par doubles tubes au plafond. Anciennes lanternes et ampoules suspendues retirées.
- Rideau métallique remontant au-dessus de toute l’ouverture du comptoir.
- Module horaire compact avec soleil/lune, heure, jour, phase et progression.
- Notaire : référence créée par l’outil intégré `image_gen`, source `art/concepts/notary/notary_sheet.png`, prompt intégral `art/concepts/notary/prompt.txt`. Modèle éditable `art/blender/district/notary.blend`, export `assets/models/district/notary.glb`. Le dialogue affiche ce véritable modèle 3D dans un SubViewport transparent.

## Livrables et validation

- Exécutable autonome : `build/windows/Fleuriste-30-octobre.exe`, ressources incorporées.
- Galerie de 24 captures réelles : `out/district_revision_review/index.html`.
- Sources Blender et GLB de huit nouveaux modèles dans `art/blender/district` et `assets/models/district`, quatre modèles d’architecture détaillés réexportés.
- 6 507 assertions de la suite principale : zéro échec (`out/district_core_final.log`).
- Vérifications ciblées avec déplacement physique, saut, limites de port, recyclage, étagères, progression de l’étage et passage piéton : boutique vide et boutique meublée (`out/district_traversal_checks.json` et `out/district_traversal_furnished_checks.json`).
- Sept étapes de marche sur la pente à l’aller et au retour (`out/district_walk_final.log`).
- Exécutable lancé depuis le dossier temporaire, vérification des onze extensions, 257 références fournisseur, commandes, pose et sous-sol persistant : `out/district_windows_smoke_engine.log`.
- Même vérification dans la version Windows avec rendu Vulkan sur RTX 3070 Laptop, terminée avec succès : `out/district_windows_graphics.log`.

Les tests emploient un profil de données isolé dans `.runtime/appdata` et ne modifient pas la sauvegarde du joueur. La compatibilité de déplacement est contrôlée sur une boutique meublée générée, sans présumer la disposition exacte de chaque sauvegarde existante.
