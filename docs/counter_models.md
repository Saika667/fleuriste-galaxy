# Comptoir et accessoires natifs

Quatre modèles Blender distincts, intégrés au constructeur normal du mobilier :

- `assets/models/shop/counter_cabinet.glb` : 3,04 × 1,04 × 0,98 m, façade rose à sept nervures crème, médaillon floral, moulures, détails laiton, trois panneaux arrière fermés.
- `assets/models/shop/cash_register.glb` : clavier numérique 12 touches et 4 fonctions, écran, ticket, poignée, serrure et tiroir séparé avec cloisons intérieures.
- `assets/models/shop/counter_bell.glb` : base, dôme doré et poussoir solidaire.
- `assets/models/shop/candy_jar.glb` : verre creux ouvert et quatorze bonbons en os.

Les sources éditables sont dans `art/blender/shop/`. Génération reproductible avec Blender 5.1 :

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/blender/shop_counter.py
```

`src/world/counter_visual.gd` assemble les quatre GLB, oriente la caisse vers le personnel et conserve les deux emplacements de bouquets. `furniture_factory.gd` utilise cet assemblage à chaque création du comptoir, y compris après chargement d'une partie existante. L'interaction habituelle du comptoir et les collisions sont conservées. Le tiroir est modélisé séparément ; son ouverture n'est pas encore une action jouable.

Les captures de `out/counter_review/` proviennent de la scène principale Godot, avec la fusion statique normale activée. La scène `scenes/shop/shot_counter.tscn` prépare une session de démonstration en mémoire, sans écrire de sauvegarde joueur. Les fleurs présentes sur le comptoir sont les bouquets natifs du jeu.

Références : planches validées `01_counter_sheet_v2.png`, `02_cash_register_sheet_v2.png`, `03_counter_bell_sheet.png` et `04_candy_jar_sheet.png` dans `art/concepts/shop/`.
