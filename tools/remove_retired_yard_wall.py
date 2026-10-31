from pathlib import Path
p=Path('src/world/shop_room.gd')
s=p.read_text(encoding='utf-8')
a=s.index('\t# mur du fond en planches sombres')
b=s.index('\tpreload("res://src/world/surface_remodel.gd").courtyard',a)
s=s[:a]+'\t# The neighboring service house and the opaque shed now enclose this yard.\n'+s[b:]
p.write_text(s,encoding='utf-8')
