# Variantes de couleur

Six fleurs ont quatre palettes chacune : leur palette d'origine et trois nouvelles. Les données sont dans `data/flower_variants.json`.

| Fleur | Palettes |
|---|---|
| Rose | Rouge, ivoire, rose, violette |
| Tulipe | Rose, rouge, jaune, violette |
| Lys | Ivoire, rose, orange, lilas |
| Fleur xéno | Vert acide, cyan, corail, violette |
| Orchidée mordeuse | Rose, violette, orange, bleue |
| Pleurelune | Violette, bleue, rose, ivoire |

Tournesol, lavande, marguerite et coquelicot n'ont pas de variante supplémentaire. Les feuilles, tiges, contours, yeux, dents, étamines et goutte restent inchangés ; seuls les rôles de matériaux explicitement listés sont recolorés.

`FlowerVisual.create(variety, variant)` permet de choisir une palette par identifiant. Les vases et bouquets alternent de façon déterministe entre les palettes disponibles, séparément pour chaque variété. Ces déclinaisons sont cosmétiques : la couleur logique utilisée pour les commandes, les prix et les déblocages reste dans `data/flowers.json`. Il n'y a pas de nouveau stock ni de nouvelle ligne d'achat par palette.

Les matériaux sont partagés entre exemplaires d'une même palette et copiés pour le vieillissement. La validation `tools/blender/validate_flower_variants.gd` contrôle les 28 palettes autorisées, les détails protégés, le cycle et l'isolation des matériaux pendant le vieillissement. Rapport : `out/blender/flower_variants_validation.json`.

`tools/blender/package_flower_variants.py` exporte 18 GLB supplémentaires dans `assets/models/flowers/variants`. Ils reprennent exactement les données géométriques des modèles de base et changent uniquement les facteurs de couleur des matériaux concernés. Les Blender de base restent les sources éditables.

Pour les six captures de quatre fleurs dans la boutique réelle, ouvrir `scenes/shop/shot_flower.tscn` dans Godot avec `-- variant_batch <dossier absolu>`. Les aperçus assemblés sont des recadrages des captures, sans retouche du contenu.
