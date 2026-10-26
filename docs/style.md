# Charte graphique (provisoire, à respecter par tous)

Ton : cartoon, macabre, absurde. Charme d'abord, lisibilité ensuite. Pas de réalisme.

## Rendu 3D
- Formes simples et arrondies (primitives Godot : boîtes biseautées, capsules, sphères), pas de textures photo : couleurs unies + léger dégradé.
- Contour/lueur : `StandardMaterial3D` avec `rim` activé, ou un second mesh inversé noir pour le contour (outline) sur les objets interactifs.
- Éclairage : un `DirectionalLight3D` chaud le jour, des `OmniLight3D` colorées la nuit ; `WorldEnvironment` avec glow léger, SSAO faible, tonemap Filmic.
- Échelle : 1 unité = 1 m. Caméra première personne à 1,6 m. FOV 70.

## Palette (hex)
- Jour boutique : fond crème #FFF1D6, bois #C98B5B, vert feuille #5FB36B, rose pétale #FF7FA8, jaune soleil #FFD24A.
- Nuit/cave : violet nuit #2A1B3D, violet profond #44285F, vert toxique #7CFF6B, fumée verte #A6FF9A, os #EDE6D3, sang cartoon #D63A4A.
- Interface : encre #2B1E33, papier #FFF6E5, accent fleuriste #FF7FA8, accent clandestin #7CFF6B, alerte #FFB020.

## Interface
- Panneaux arrondis (rayon 14 px), ombre portée douce, bordure 3 px encre. Police : celle de Godot par défaut en attendant mieux, mais avec tailles ≥ 18 px à 1080p.
- Deux soldes toujours visibles : pétale rose (boutique), feuille toxique (clandestin). Icônes simples dessinées en code (`draw_*`) ou en `Label` émoji-libre.
- Jamais de jauge de suspicion. Indiquer clairement si le temps est arrêté (bandeau « Temps arrêté »).

## Technique
- Les noms de scènes/scripts en anglais snake_case, les textes joueur en français.
- La logique vient de `Game` (autoload, voir docs/api-core.md). Les scènes ne dupliquent jamais la logique.
