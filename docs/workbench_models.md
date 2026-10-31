# Établi de fleuriste

Modèle réalisé d'après les planches validées 05 et 06 (v2), en style cartoon.

- Dimensions du meuble : 2,98 m × 0,98 m, plateau à 0,97 m.
- Plateau et supports arrondis, dos plein, étagère inférieure vide à 0,28 m.
- Accessoires séparés : tapis quadrillé, ciseaux avec poignées creuses et deux lames, rouleau kraft creux, bobine rose, vase cyan et lampe.
- Trois roses natives du jeu (rouge, rose, ivoire).

Les GLB sont dans `assets/models/shop/workbench*.glb`, les sources éditables dans `art/blender/shop/workbench*.blend`. `workbench_assembled` est une version complète transportable ; les autres fichiers permettent d'éditer chaque élément séparément.

Génération reproductible :

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/blender/shop_workbench.py
```

L'intégration normale passe par `src/world/workbench_visual.gd` et `furniture_factory.gd`. Les anciens pots décoratifs fixes et les deux rouleaux sous la table ont été retirés. L'interaction existante « Travailler à l'établi », les dimensions de collision et l'éclairage nocturne de la lampe sont conservés. Quatre ancres de stockage distinctes des emplacements de bouquets sont préparées ; le dépôt et la récupération de pots par le joueur ne sont pas encore implémentés.

Les cinq images de `out/workbench_review/` sont des captures réelles du shop dans Godot, avec la fusion statique normale. La scène `scenes/shop/shot_workbench.tscn` vérifie la présence de l'établi, l'invite d'interaction et les quatre ancres, puis prépare les captures en mémoire sans modifier les sauvegardes.
