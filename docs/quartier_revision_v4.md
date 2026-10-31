# Quartier, sous-sol et animaux — 30 octobre 2026

## Version à tester

`build/windows/Fleuriste-quartier-revise.exe` contient les ressources intégrées. La galerie `out/quartier_v4_review/index.html` présente les captures du jeu et les cinq nouvelles planches des animaux.

Les sauvegardes restent compatibles. Le bouton **Se décoincer** du menu Pause reste disponible. Les essais automatiques utilisent des parties isolées et ne remplacent pas la sauvegarde du joueur.

## Rue et implantation

- Les anciens bâtiments cubiques, leurs devantures violettes et les anciens lampadaires ne sont plus construits. Les lampes détaillées sont orientées vers la chaussée.
- La ruelle fait environ 8,5 m de large : chaussée de 5,2 m et deux trottoirs de 1,65 m. Elle descend sur 29 m, rejoint la rue principale et comporte un STOP. Les hautes rambardes latérales sont supprimées.
- La maison d’angle est repositionnée ; la remise occupe son propre volume de 3,4 × 3,4 m contre le shop, avec mur mitoyen à X = 13,4 m. La boutique entière n’a pas été déplacée : cette implantation conserve ses interactions et libère la remise.
- La remise est une pièce creuse, couverte, avec porte depuis la boutique, étagères de rangement et outils. Son enveloppe reste présente avant l’achat de l’amélioration.
- La façade du fleuriste reçoit soubassements, pilastres, corniches, fenêtres à volets, descentes d’eau et toiture. Les façades arrière des maisons ont des ouvertures, portes de jardin et gouttières en volume.
- La place basse reçoit des places de stationnement contiguës, des trottoirs, des arbres et des jardins avec clôtures variées. Des immeubles masquent les limites arrière et latérales.
- Trois variantes d’arbres : branches, feuillage en petites touffes, bordure creuse, terre, fleurs et feuilles mortes. Les arbres de la rue sont placés au centre des trottoirs.

## Surfaces et accès

Les anciens trottoirs étaient superposés à leur remplacement. Ils sont retirés. Le pavage utilise désormais une surface continue avec joints filtrés par le shader, sans centaines de minces pavés superposés. Le sol du jardin est découpé sous la serre ; le sol de la place ne recouvre plus le sol du sous-sol. Les petites surfaces humides superposées au sol intérieur sont supprimées.

Les murs du shop utilisent des boîtes planes jointives plutôt que des blocs arrondis. Les gradients des lambris sont supprimés ; le papier peint est découpé autour de la nouvelle porte de remise.

L’escalier du sous-sol fait 1,1 m de large pour 4,2 m de recul et 4,2 m de dénivelé. Sa collision utilise une rampe et un palier horizontal distinct : entrée et sortie latérales fonctionnent dans les deux sens. L’entrée haute comporte des murs et une porte articulée. La circulation conserve la même scène, sans chargement.

La serre est rapprochée du bord du toit du sous-sol. Le parapet arrière est interrompu sur toute sa largeur. La façade extérieure du sous-sol reçoit des encadrements, corniches, fenêtres et descentes d’eau. Un caisson ferme l’espace au-dessus du rideau métallique.

## Personnages, animaux et sous-sol

- Tous les corps visibles des clients et passants utilisent les personnages issus des planches. Les identités économiques, les dialogues et les rôles des clients sont conservés ; les anciennes silhouettes procédurales sont remplacées à l’affichage. Les visiteurs du sous-sol utilisent également les personnages validés.
- Notaire : branches de lunettes, mèches latérales, col de chemise, nœud de cravate, revers et coutures du costume.
- Squelette : carpes, métacarpes, doigts de longueurs différentes, pouces séparés, sacrum triangulaire et petites vertèbres du coccyx.
- Champignons : colonies plus petites, pieds courbés, chapeaux et lamelles.
- Chat, pigeon, araignée, papillon et luciole : nouvelles planches avec vues multiples, modèles GLB articulés et sources Blender. Les mouvements ambiants existants utilisent ces nouveaux modèles.

Les planches animales sont des images créées avec l’outil intégré **image_gen**. Les prompts exacts accompagnent les images dans `art/concepts/animals/`. Les captures de la galerie proviennent de Godot et ne sont pas des rendus générés par IA. Les gros plans animaux utilisent un plateau de présentation dans le moteur ; leurs instances ambiantes conservent leur taille normale dans le jeu.

## Filtres à charbon

Les filtres sont des cartouches clipsées sous les deux bouches centrales du plafond. Le terminal au sol est retiré de l’affichage et des collisions. L’amélioration s’ouvre en interagissant directement avec une bouche.

Les deux références correspondantes du catalogue utilisent désormais le modèle de cartouche. En mode placement, elles s’alignent sur une bouche ; les emplacements au sol et l’occupation d’une même bouche par deux cartouches achetées sont refusés. Une pose active le filtre réel du système d’odeur. Le rendu évite de superposer la cartouche achetée et celle du socket.

## Vérifications

- Suite du cœur du jeu : 6 507 assertions.
- Parcours physique : sous-sol → palier → shop → sous-sol, puis escalier de l’étage ; essais en boutique vide et meublée.
- Marche réelle : rue → ruelle → place basse → retour à la rue, sept étapes sans téléportation pendant le parcours.
- Vérifications supplémentaires : modèles validés, contrats des visiteurs, cinq animaux articulés, branches des lunettes et placement des cartouches.
- Exécutable exporté lancé depuis un autre répertoire, en mode sans écran puis avec rendu Vulkan.

Les résultats détaillés et les journaux de cette version portent le préfixe `out/quartier_v4_`. Les contrôles automatiques valident les accès et les interactions testés ; la galerie permet de juger séparément la direction artistique.
