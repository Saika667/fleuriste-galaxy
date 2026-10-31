# Modèles du catalogue 07 à 13

Les sept propositions validées de `art/concepts/shop/items_07_13.html` sont réalisées en géométrie native Blender, exportées en GLB puis intégrées au shop.

| N° | Élément | Modèle |
| --- | --- | --- |
| 07 | Vase en verre cannelé et ruban, roses | `vase_rose` |
| 08 | Lampe articulée, base, interrupteur et câble | `task_lamp` |
| 09 | Vitrine réfrigérée rétro, trois étagères, portes vitrées, poignées et thermostat | `flower_fridge` |
| 10 | Vase à lys ivoire, bord évasé et feuilles en relief | `vase_lily` |
| 11 | Vase à tournesols jaune, médaillon et pied ocre | `vase_sunflower` |
| 12 | Vase à lavande violet octogonal, bandes et emblème | `vase_lavender` |
| 13 | Vase à coquelicots en terre cuite, bande corail et reliefs | `vase_poppy` |

GLB : `assets/models/shop/`. Sources Blender : `art/blender/shop/`. Les cinq vases existent séparément et en versions complètes avec fleurs (`*_flowers`). Les fleurs sont les modèles natifs déjà utilisés par le jeu, avec leurs variantes autorisées. Les tournesols, la lavande et les coquelicots gardent leurs couleurs d'origine.

La génération est reproductible avec :

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/blender/shop_items_07_13.py
```

`shop_vase_visual.gd` remplace les cinq anciens types de contenants dans les appels du constructeur standard, en conservant la variété et la quantité demandées. `workbench_visual.gd` utilise la nouvelle lampe et le vase à roses. `fridge_visual.gd` remplace l'ancienne vitrine et préserve ses six emplacements de bouquets, son éclairage froid et l'interaction existante de rangement. Les charnières de la lampe et les portes de la vitrine sont modélisées ; aucune nouvelle animation ou interaction d'ouverture n'a été ajoutée.

Les captures dans `out/items_07_13_review/` proviennent du moteur Godot, dans la boutique. Pour les vues détaillées des vases, les accessoires de l'établi sont temporairement masqués et les cinq vases y sont alignés dans une session de démonstration en mémoire. La disposition de production de l'établi reste inchangée. Aucune sauvegarde joueur n'est écrite. Les assertions de capture vérifient la présence des meubles, les six emplacements de la vitrine et son invite d'interaction.
