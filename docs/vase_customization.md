# SMEGLI, ruban et compositions libres

La vitrine porte maintenant **SMEGLI**, en lettres crème épaisses et légèrement en relief sur le bandeau rose. Le lettrage utilise les contours d'Arial Bold convertis en géométrie dans Blender, avec un espacement accru ; aucun fichier de police n'est nécessaire au jeu.

Les deux pans du ruban du vase en verre sont orientés vers le bas et suivent l'extérieur de la panse, avec deux pointes découpées. Ils ne traversent plus le verre et ne forment plus un V oblique inversé.

## Utilisation en jeu

- Viser un vase de décoration et appuyer sur **E**, ou ouvrir le bouton **Vases / V** du HUD.
- Choisir le vase dans la liste, puis les quantités de chaque fleur possédée. Le dessin du contenant ne limite pas les espèces : un vase jaune peut recevoir des lys, un vase violet des tournesols, etc.
- Cliquer sur **Placer les fleurs**. Un vase accepte jusqu'à 12 tiges, avec mélanges libres.
- **Vider le vase et récupérer les tiges** remet les fleurs au stock. Les réservations des employés restent protégées.

Les compositions sont sauvegardées avec la qualité, le coût et la fraîcheur des tiges. Elles suivent le vase quand son meuble est déplacé ou tourné. Retirer le meuble restitue ses tiges. Les fleurs continuent à vieillir ; les vases de la vitrine utilisent le froid et sa capacité existante. Les tiges disposées dans les vases restent comptabilisées dans la capacité du stock.

Les vases décoratifs éditables démarrent vides en l'absence d'une composition sauvegardée ; les fleurs n'apparaissent pas gratuitement. Les indicateurs de stock associés à une variété et les accessoires portés par les personnages gardent leur rôle automatique.

## Implémentation et vérifications

- `src/core/vase_arrangements.gd` : modifications atomiques sur une copie d'inventaire, contrôle des quantités/réservations/capacités, vieillissement et sérialisation.
- `src/world/vase_controller.gd` : identifiants stables par meuble et position locale, collisions d'interaction sans obstacle physique, rafraîchissement des compositions, exclusion des aperçus de placement.
- `src/ui/vase_screen.gd` : choix du vase et des mélanges, intégré au système modal et à la pause du HUD.
- `tools/blender/shop_items_07_13.py` : modèles source SMEGLI et ruban corrigés.
- Tests complets : **5 786 vérifications réussies, 0 échec**, dont les nouveaux tests de conservation, d'échec atomique, de réservations, de vieillissement, de sauvegarde et de retrait du meuble. Le runner signale encore des ressources allouées à sa fermeture ; aucun échec de test.
- La scène `scenes/shop/shot_vase_customization.tscn` exerce l'interaction E, le bouton de validation du vrai menu et le maintien de la composition après déplacement du meuble. Les quatre captures sont réalisées dans Godot, sans modifier les sauvegardes joueur. Les cinq vases sont alignés uniquement pour la démonstration.
