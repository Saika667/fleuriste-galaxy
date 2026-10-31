# Rose cartoon

Référence : `art/concepts/flowers/rose_cartoon.png`. Source éditable : `art/blender/flowers/rose.blend`. Version avec contours : `art/blender/flowers/rose_toon.blend`. Asset Godot : `assets/models/flowers/rose_toon.glb`.

La fleur est construite avec six pétales extérieurs courbes, trois pétales intérieurs, un cœur fermé et une spirale en relief, cinq sépales, deux feuilles dentelées et trois épines. Couleurs unies unlit et contours géométriques. Origine au pied de la tige, dimensions en mètres, face vers +Z. Pas de textures, de rig ni de LOD ; modèle de présentation à optimiser avant une utilisation en très grande quantité.

Les vases de stock identifiés comme roses et les roses des bouquets utilisent cet asset. Les neuf autres variétés ont désormais leurs propres modèles, décrits dans `docs/flowers_models.md`. La rotation et le brunissement des roses suivent la fraîcheur du bouquet, sans modifier les matériaux partagés de l'asset.

Régénération : Blender en arrière-plan avec `--python tools/blender/rose.py`, puis réimport Godot. `scenes/shop/shot_flower.tscn` instancie la boutique réelle et une rose sur un socle de présentation ; arguments `front`, `back` et `top`. Le HUD et le viseur sont masqués uniquement pour ces captures. Les images sont dans `out/blender/rose_<vue>_in_game.png`.
