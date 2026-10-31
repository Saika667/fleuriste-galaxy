# Six personnages — deuxième série de références

Modèles 3D éditables construits depuis les six planches jointes, sauvegardées dans `art/concepts/cast_v2`. Les quatre premières références sont des aliens, les deux dernières sont humaines. Les identifiants sont descriptifs, sans noms propres inventés.

| Modèle | Caractéristiques reconstruites | Squelette |
|---|---|---|
| `reptile_mecano` | Peau orange, crête rouge, long museau et cou, queue recourbée, salopette, ceinture avec outils et radio, pieds griffus, clé tenue en main | 19 os |
| `cyclope_roche` | Grand corps gris, plaques rocheuses en relief, œil unique, grosses mains et pieds, champignons sur les épaules avec tiges et lamelles | 17 os |
| `mantide` | Tête verte, deux yeux, mandibules, deux antennes, quatre bras articulés, épines, abdomen segmenté et pieds fourchus | 24 os |
| `gel_bleu` | Enveloppe bleue transparente, deux yeux, bouche ouverte, crête et membres mous, noyau rose, organes et vaisseaux internes, bulles et reflets | 18 os |
| `aventurier` | Cheveux bruns ébouriffés, tempes grises, barbe courte, veste olive à col relevé, mains dans les poches, cargo, bottes, radio et panneaux lumineux | 17 os |
| `heroine` | Queue-de-cheval brune, veste bordeaux courte, crop top noir, pantalon cargo, bottes, épaulières et bracelet cyan, geste de la main en V | 17 os |

## Fichiers

Pour chaque identifiant :

- `art/blender/<identifiant>.blend` : pièces séparées et squelette, source éditable.
- `art/blender/<identifiant>_toon.blend` : matériaux et contours de présentation.
- `assets/models/characters/<identifiant>_toon.glb` : export chargé dans Godot.
- `assets/models/characters/<identifiant>_toon.json` : rapport de géométrie et d'export.
- `out/blender/<identifiant>_front.png`, `_back.png`, `_three_quarter.png` : contrôle Blender.
- `out/blender/<identifiant>_in_game.png` : capture réelle dans la boutique, face à gauche et dos à droite.

## Intégration

Les six modèles figurent dans les pools de passants et de visiteurs, sous `extra_<identifiant>`. Le contrôleur utilise un squelette distinct par instance, avec les capsules et les vitesses propres aux silhouettes. Les membres supplémentaires de la mantide, la queue du reptilien et le noyau pulsant du gel ont leur animation propre. Les mains dans les poches, la clé et le geste en V conservent leur pose pendant la marche.

Le gel utilise une enveloppe GLB `alphaMode: BLEND`, avec une opacité de 46 %. Ses volumes extérieurs sont fusionnés en une seule peau, fermée et lissée, afin de supprimer les surfaces internes aux raccords entre membres. Les poids du squelette sont transférés et interpolés depuis les volumes d'origine. Les organes sont de véritables volumes internes. Les autres matériaux sont unlit ; les contours sont des coques inversées. Ne pas ajouter une seconde passe de contours sur ces modèles.

Révision du 27 octobre : volumes des deltoïdes, biceps, avant-bras, quadriceps et mollets du cyclope accentués, plis anatomiques projetés sur ces surfaces, pieds moins larges avec talon et trois orteils arrondis. La coiffure de l'aventurier utilise une silhouette plus compacte, des mèches pointues asymétriques et une mèche frontale déportée. Deux petites mèches supplémentaires encadrent chaque tempe, juste au-dessus des oreilles.

## Portée

Les volumes et les proportions sont interprétés depuis les vues dessinées ; la fidélité 1:1 n'est pas validée. Les expressions faciales restent fixes. Pas de textures UV, de morph targets, de LOD ni de clips dans les GLB : les animations sont pilotées dans Godot. Les maillages de présentation doivent être optimisés pour une grande foule ou une cible mobile. La transparence du gel peut présenter des limites de tri selon les objets visibles derrière lui.

## Régénération et contrôle

```powershell
tools/blender/run.ps1 -Script tools/blender/characters/cast_v2.py -ScriptArgs reptile_mecano
```

Remplacer le dernier argument par l'identifiant souhaité. Le script partage les primitives de `remaining_cast.py` ; il ne régénère que le modèle demandé. Réimporter les ressources dans Godot après génération. Une régénération remplace les sources Blender : conserver les retouches durables dans le script.

`tools/blender/validate_cast_v2.gd` vérifie les six imports, leurs catégories, les os, les skins, les matériaux, la transparence du gel, le noyau pulsant, les poses des mains et les animations. Il charge également les onze modèles précédents pour contrôler leur coexistence. Rapport : `out/blender/cast_v2_validation.json`.

`scenes/shop/shot_cast.tscn`, avec l'identifiant puis `pair`, montre les deux côtés d'un personnage dans la vraie scène de jeu. La scène de capture masque les plantes suspendues et les particules de poussière pour dégager les modèles ; la partie normale conserve son décor.
