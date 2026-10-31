# Items 34 à 53 : modèles natifs dans le shop

20 sources Blender dans `art/blender/shop`, exportées en GLB dans `assets/models/shop`. Production : `tools/blender/shop_items_34_53.py`. Les objets remplacent leurs anciens visuels dans `shop_decor.gd` et `shop_room.gd` ; les étagères de 4,20 m et 3,00 m utilisent maintenant leurs propres supports, sans étirer le modèle de 5,60 m.

Les fleurs des seaux, cageots et jardinières sont assemblées séparément en Godot avec les modèles floraux existants. Les GLB de contenants sont fournis sans les compositions d'exemple. Les bulbes, crânes et plateaux de jeunes plants restent des composants distincts dans les sources Blender.

Les deux gradins offrent chacun trois surfaces éditables via O. Leurs clés comprennent modèle, position et niveau pour éviter tout mélange de rangement entre gradins. Les vases restent personnalisables via V et conservent leur composition lorsqu'ils sont déplacés ou sauvegardés.

La plante carnivore suit la planche 46 révisée : dents triangulaires fixées à chaque mâchoire. Les pivots `head`, `jaw_up` et `jaw_dn` survivent à la fusion des maillages statiques. Le mouvement est piloté en jeu par le système d'animation du shop. Le GLB conserve les pivots ; il n'inclut pas de clip d'animation précalculé.

La plante suspendue conserve son crochet et ses trois cordons. Une rallonge relie le crochet au plafond de 5,20 m dans la boutique, pour maintenir la plante à une hauteur visible.

## Contrôle

Suite complète : 5878 assertions réussies, zéro échec. Nouveaux contrôles : chargement des 20 modèles, séparation fleurs/contenants, conservation des mâchoires après fusion, ouverture/fermeture, identifiants distincts des surfaces des gradins. Le lanceur de tests signale toujours des ressources utilisées à la fermeture.

La scène `scenes/shop/shot_items_34_53.tscn` produit 49 captures réelles du viewport : face/dos des 20 modèles, deux vues du shop, trois vues de dessus, deux détails des étagères et deux détails de la plante carnivore. Les accessoires sont temporairement présentés pour examen dans une partie de contrôle indépendante de la sauvegarde du joueur.

Galerie : `out/items_34_53_review/index.html`. Archive : `out/shop_items_34_53_models_and_renders.zip`.
