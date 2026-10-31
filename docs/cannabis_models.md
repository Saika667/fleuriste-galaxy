# Six plantes cartoon 3D

Les cinq nouvelles plantes sont des props statiques reconstruits depuis les planches `art/concepts/cannabis/02_elancee.png` à `06_menthe_rose.png`. La compacte conserve son modèle précédent et ses deux branches exclusivement feuillues à l'avant et à l'arrière.

| Identifiant | Design |
|---|---|
| cannabis_compact | Terre cuite, cinq têtes vertes, deux branches feuillues supplémentaires |
| cannabis_elancee | Haute, feuilles étroites, pot turquoise à bord crème |
| cannabis_pourpre | Touffue, six têtes violettes, revers des feuilles pourpres, jardinière ivoire et prune |
| cannabis_eventail | Trois branches principales, feuilles jaune-vert, pot bas olive |
| cannabis_sauvage | Tige en S, asymétrie, feuillage vert bleuté, pot bordeaux |
| cannabis_menthe_rose | Création fictive vert menthe et rose, pot bleu arrondi |

Les branches sont réparties en profondeur, les feuilles ont une épaisseur et une nervure, les têtes sont sculptées en volumes superposés. Les pots sont ouverts avec une bordure intérieure et de la terre en retrait. Origine sous le pot, unités en mètres, Y vertical et face +Z. Les volumes interprètent les dessins ; les vues de référence ne sont pas des mesures exactes.

Révision du feuillage : chaque plante possède maintenant six petites ramifications feuillues, avec deux pétioles latéraux et une feuille terminale par ramification, soit dix-huit petites feuilles palmées ajoutées aux précédentes. Totaux : compacte 36, élancée 30, pourpre 35, éventail 29, sauvage 31 et menthe rose 34 feuilles palmées. Les ramifications alternent sur plusieurs hauteurs et en profondeur pour étoffer aussi le dos. Le nombre de têtes fleuries et la palette de chaque plante sont conservés.

Sources éditables : `art/blender/plants/<identifiant>.blend`. Versions consolidées avec contours : `<identifiant>_toon.blend`. Exports de jeu : `assets/models/plants/<identifiant>_toon.glb`. Les rapports JSON voisins indiquent dimensions, surfaces, triangles et nombre de têtes/feuilles. Chaque modèle utilise un maillage avec treize ou quatorze surfaces. Pas de LOD, rig ou animation ; une simplification sera nécessaire avant un affichage en grande quantité.

Six scènes réutilisables sont disponibles dans `scenes/props`. `src/world/cannabis_visual.gd` permet de les instancier par identifiant. Il s'agit de props de présentation ; les anciennes plantes et les mécanismes de la cave restent inchangés.

Régénération des cinq nouvelles plantes : Blender `--background --python tools/blender/cannabis_remaining.py`. Pour une sélection, ajouter `-- cannabis_pourpre cannabis_sauvage`. La compacte garde son script `tools/blender/cannabis_compact.py`. Réimporter ensuite dans Godot. Le générateur vérifie les dimensions et la conservation des transformations pendant la consolidation.

Présentation dans la boutique réelle : scène `scenes/shop/shot_cannabis.tscn`, arguments identifiant puis `front`, `back` ou `top`. Pour les dix-huit vues des six modèles en un lancement, arguments `-- plant_batch <dossier absolu>`. Le HUD, les suspensions et les particules sont masqués uniquement dans cette présentation. `tools/blender/package_cannabis.py` assemble les recadrages et les archives sans retoucher le contenu des captures.
