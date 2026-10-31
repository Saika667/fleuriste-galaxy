# Corrections — crâne, horloge et panneaux 69–72

- **Crâne :** les deux sphères des pommettes sont supprimées. Les reliefs zygomatiques sont sculptés directement dans une surface crânienne continue, subdivisée avant de creuser les orbites. Composition de sept petites fleurs (roses, marguerites, lys), avec sommets autour de 27,5–29,5 cm au lieu de 43 cm ; douze branches de feuilles dépassent de la couronne. Les fleurs restent séparées du contenant.
- **Horloge :** boîtier vert profond, cadran vert pâle, filets menthe, graduations et chiffres vert foncé, trotteuse verte. Les aiguilles restent liées à l’heure du jeu.
- **Enseigne :** police Cooper Black convertie en maillages natifs sur les deux faces, pour un rendu indépendant des polices installées chez le joueur. OUVERT reste vert, FERMÉ reste rouge. Un panneau articulé se retourne de 180° ; une chaîne continue à maillons entrelacés relie ses deux œillets à un crochet central et à une fixation sur le vitrage. La chaîne reste fixe pendant le retournement du panneau.
- **Fixation et interaction :** l’enseigne est enfant du vantail de la porte d’entrée, devant sa vitre côté intérieur ; elle accompagne donc l’ouverture de la porte. Son interaction est accessible depuis le shop. Retourner le panneau en préparation ouvre la boutique ; le retourner pendant l’ouverture ferme la journée et passe au bilan, dans le cycle existant. La transition du bilan vers la nuit est conservée.
- **File d’attente :** les deux lignes EN FILE et ATTENTE sont roses, en gras et agrandies. Le nombre est toujours dynamique.

La galerie `out/items_69_72_revisions_review/index.html` contient des captures réelles dans Godot, y compris depuis la rue et depuis le shop. Le GIF de retournement est assemblé exclusivement à partir d’images de la scène du jeu. Les vues individuelles sont prises de jour pour apprécier les couleurs ; les images du test de fermeture suivent le passage réel au bilan et son éclairage de fin de journée.

Les quatre vues correspondantes sont aussi actualisées dans la galerie des modèles 54–73. Les planches antérieures restent des références de la version initiale ; les présentes corrections priment pour les modèles 3D.

Validation : 5 960 assertions réussies, zéro échec lors de la suite complète, plus contrôle en jeu des actions réelles d’ouverture/fermeture, de la couleur rouge de FERMÉ, de la chaîne indépendante et du lien avec le vantail. Les avertissements de libération de ressources du runner et le message du test de sauvegarde volontairement corrompue sont préexistants.

Régénération : `tools/blender/shop_items_54_73.py -- shelf_flowered_skull botanical_clock botanical_open_sign botanical_queue_sign`, import Godot, scène `scenes/shop/shot_items_69_72_revisions.tscn`, puis `tools/package_shop_items_69_72_revisions.py`.
