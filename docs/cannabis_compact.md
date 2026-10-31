# Plante compacte cartoon

Modèle statique interprété depuis `art/concepts/cannabis/01_compacte.png` : pot ouvert en terre cuite, terre en retrait, tige ramifiée, cinq grappes florales, trente-six feuilles palmées à sept folioles dentelées et nervures, accents orange en géométrie. Les branches avant et arrière et les quatre feuilles intermédiaires sont complétées par six petites ramifications de trois feuilles chacune, réparties sur plusieurs hauteurs et en profondeur. Dimensions en mètres, origine sous le pot, Y vertical et face +Z. Hauteur totale proche de 0,91 m. Les vues dessinées sont harmonisées pour former un objet cohérent en volume.

Sources éditables : `art/blender/plants/cannabis_compact.blend`, version consolidée avec contours `cannabis_compact_toon.blend`. Export : `assets/models/plants/cannabis_compact_toon.glb`. Couleurs unies unlit, contours par coque inversée, pas de texture photographique.

La scène réutilisable `scenes/props/cannabis_compact.tscn` contient l'asset. `scenes/shop/shot_cannabis.tscn` le présente sur un socle dans la boutique réelle, avec la caméra de face, de dos ou du dessus selon l'argument `front`, `back`, `top`. Le HUD est masqué uniquement dans la présentation. Ce prop ne remplace pas les anciennes plantes de la cave et n'ajoute pas de simulation de croissance ou d'achat.

Régénération : Blender `--background --python tools/blender/cannabis_compact.py`, puis réimport Godot. La génération vérifie les dimensions et les transformations après consolidation. Le rapport JSON voisin du GLB indique le budget de triangles avec contours, en un maillage et treize surfaces ; aucun LOD, rig ou animation. Une simplification est nécessaire avant son affichage en grande quantité.
