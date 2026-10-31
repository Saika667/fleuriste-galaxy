# État des lieux de la map — base de refonte

Relevé effectué depuis les générateurs du jeu et captures réelles dans Godot. La session de référence affiche toutes les extensions avec le mobilier initial, sans charger ni réécrire une sauvegarde joueur. Ce document décrit l'existant ; aucune zone n'a été redessinée.

## Organisation générale

La boutique occupe le centre, avec sa façade et sa porte publique au sud du repère moteur (+Z). La terrasse se développe devant la partie ouest de la façade. Une porte sur le mur est donne dans la cour de service. La remise est adossée à ce mur, dans la partie sud de la cour. Le jardin se trouve au nord de la cour ; la serre s'étend à l'ouest du jardin, derrière la boutique. Le sous-sol est une scène distincte appelée par la trappe située vers le coin nord-ouest du shop.

L'annexe est à l'ouest du shop ; un escalier en colimaçon dessert l'étage, dont le sol est à Y = 3,4 m. Quatre modules supplémentaires de fin de partie apparaissent en façade de l'immeuble voisin à l'est : galerie, entrepôt, salon et ambassade. Ils sont inclus comme contexte sur le croquis et les vues générales.

## Dimensions et points à examiner

| Zone | Volume / emprise construite | Éléments actuels et sujets à retravailler |
|---|---|---|
| Shop | 10 × 8 m, grille 10 × 8 | Comptoir central, établi et étagères, frigo, vitrines, parquet/carrelage, suspensions. Clarifier les circuits client et service, les points focaux et l'intensité des couleurs. |
| Terrasse | Plateforme 8,3 × 3,25 m ; grille de placement 6 × 3 | Plancher, garde-corps fleuri, tables, sièges, parasols et guirlandes. Travailler la lecture de l'entrée et la relation avec le trottoir. |
| Sous-sol | Volume visuel 10 × 8 m, hauteur 3 m ; grille 8 × 6 | Escalier, quatre emplacements de bacs, comptoir, composteur, consoles, stockage et trappe d'égout. Préserver la circulation et la lisibilité malgré l'éclairage sombre et les effets lumineux. |
| Remise | Corps 1,14 × 2,70 m, hors débords de toit | Bloc fermé et collidable, porte, cadenas, petit rangement extérieur et outils. Aucun intérieur modélisé/jouable à ce stade ; une future pièce intérieure nécessiterait une vraie ouverture du volume. |
| Jardin | Pelouse ≈ 5,2 × 7 m ; grille orientée 6 × 4, soit 4 × 6 m dans le monde | Allée de dalles, massifs périphériques, haies et arrosoir. Remplacer les répétitions de fleurs simples, travailler les bordures et mieux définir les limites de la cour. |
| Serre | 4 × 4,25 m, hors petits débords | Ossature blanche, vitres, deux tables de pots, allée et porte vers le jardin. Revoir la silhouette du toit, le vitrage et le détail des cultures. |

Les dimensions de la géométrie et les grilles de placement ne coïncident pas toujours : le croquis utilise les emprises visuelles pour situer les zones et signale les différences dans ce tableau. Les portes et cheminements sont représentés de manière schématique. L'encart du sous-sol ne prétend pas superposer sa géométrie à celle du rez-de-chaussée.

## Captures

Seize PNG 1600 × 1000 : trois vues générales, deux angles par zone et une vue de l'annexe/escalier. Le HUD est masqué. Le shop est ouvert en coupe uniquement dans les deux vues aériennes signalées comme telles ; les vues de zone montrent le décor construit. Les captures de la remise montrent son extérieur. Le sous-sol est montré dans son état initial, avec ses emplacements de bacs.

Le dossier `out/map_design` contient le croquis PNG, sa version SVG éditable, les captures originales, la planche récapitulative `zones_apercu.jpg`, le manifeste des caméras `captures.json` et la galerie `index.html`. L'archive complète est `out/map_design_reference.zip`.

## Sources du relevé

- `src/world/shop_room.gd` : volume principal, rue, cour, trappe et portes.
- `src/world/shop_extensions.gd` : emprises de la terrasse, du jardin, de la serre, de la remise, de l'annexe et des extensions de façade.
- `src/cellar_view/cellar_view.gd` : dimensions locales et implantation des postes du sous-sol.
- `src/world/main.gd` : chargement séparé du sous-sol et retour au shop.
- `data/furniture.json` : grilles et cases d'accès.

Reproduction : lancer Godot sur `scenes/shop/shot_map_design.tscn -- map_design`, puis exécuter `tools/package_map_design.py` avec Python/Pillow. La scène de relevé ne sauvegarde pas la partie. Les médias ne proviennent pas d'un générateur d'images.
