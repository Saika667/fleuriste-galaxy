# Transitions animées des six plantes

Le composant réutilisable `scenes/props/cannabis_growth.tscn` anime les trois modèles de chaque famille : petite pousse, croissance, adulte. Son script `src/world/cannabis_growth_actor.gd` accepte `configure("cannabis_compact")` ou une autre famille existante, `set_growth(progress)` entre 0 et 1 et `animate_to_stage(stage, duration)` pour les stades 0, 1, 2. Le signal `stage_reached` indique la fin du tween. La famille peut aussi être définie dans l'inspecteur.

Le pot est rendu une seule fois, à taille fixe. Les modèles de végétation sont séparés visuellement via les matériaux et les contours autour de la bordure du pot. La nouvelle végétation se déploie depuis la hauteur du terreau avec une interpolation douce. Une dissolution opaque par pixels raccorde les géométries distinctes ; il ne s'agit pas d'un morphing sommet à sommet. Une légère oscillation affecte la végétation pendant la démonstration.

La vidéo montre six séquences de huit secondes dans la boutique réelle, deux transitions chacune. Cette durée de démonstration est indépendante de la simulation : les cycles économiques et les plantations existantes de la cave ne sont pas modifiés par ce composant visuel. Les maillages restent ceux des modèles précédents ; ce composant n'ajoute pas d'animation squelettique aux fichiers GLB.

Vérification : `tools/check_cannabis_growth.gd` contrôle les trois états finaux, la stabilité du pot, les états intermédiaires et les vrais tweens pour les six familles. Lancer dans Godot avec `--script res://tools/check_cannabis_growth.gd`.

Enregistrement : scène `scenes/shop/shot_cannabis.tscn`, arguments `-- growth_animation`, options Godot `--fixed-fps 24 --write-movie <chemin AVI>`. Le résultat contient deux images de mise en place puis 1152 images d'animation. `tools/blender/cannabis_animation_media.py` prépare six GIF et trente images de contrôle ; `tools/blender/encode_cannabis_animation.py` encode la vidéo MP4 avec Blender. Les médias proviennent du viewport réel de Godot, sans génération d'images.
