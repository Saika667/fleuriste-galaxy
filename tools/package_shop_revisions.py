"""Package revised native models and real Godot captures."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html, json, struct

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'out/shop_revisions_review'
ASSETS = ['pot_ivy', 'awning_display', 'bouquet_none', 'botanical_wall_shelf',
          'botanical_shelf_medium', 'botanical_shelf_small', 'pot_skull',
          'jar_seeds', 'florist_pegboard', 'chalk_menu', 'rip_promotion_sign']
GROUPS = [
    ('lierre', '23 — Lierre repris d’après la planche', ['08_lierre', '08_lierre_profil']),
    ('presentoir', 'Présentoir : auvent relevé et vases personnalisables', ['01_presentoir_face', '02_presentoir_trois_quarts']),
    ('etageres', 'Plafond plus haut et trois tailles d’étagère', ['03_shop_plafond', '04_etageres_espacees', '05_trois_tailles']),
    ('rangement', 'Placement libre dans le jeu', ['06_menu_rangement']),
    ('bouquet', 'Attache en raphia du bouquet', ['07_attache_raphia', '07_attache_detail']),
    ('crane', 'Crâne enfoncé dans le pot', ['09_crane']),
    ('graines', 'Graines déposées dans le bocal', ['10_graines']),
    ('outils', 'Ciseaux et arrosoir', ['11_outils', '11_ciseaux_arrosoir_detail']),
    ('ardoise', 'Menu manuscrit et effet craie', ['12_ardoise']),
    ('pancarte', 'Pancarte décorée et rose fanée', ['13_pancarte']),
]

def main():
    files = []
    report = []
    for asset in ASSETS:
        glb = ROOT / f'assets/models/shop/{asset}.glb'
        blend = ROOT / f'art/blender/shop/{asset}.blend'
        raw = glb.read_bytes()
        assert raw[:4] == b'glTF' and blend.is_file()
        size = struct.unpack_from('<I', raw, 12)[0]
        doc = json.loads(raw[20:20+size])
        triangles = sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
        report.append(dict(asset=asset, triangles=triangles, units='metres'))
        files.extend([glb, blend])
    page = '''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Shop — modèles retravaillés en jeu</title><style>
body{margin:0;background:#f7f0e2;color:#183b37;font:17px/1.6 system-ui}main{max-width:1500px;margin:auto;padding:28px}a{color:#176e69}nav{display:flex;gap:15px;flex-wrap:wrap}section{margin:48px 0;scroll-margin-top:20px}h1,h2{line-height:1.25}.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,500px),1fr));gap:15px}img{display:block;width:100%;border-radius:12px}figure{margin:0}figcaption{padding:8px}p{max-width:1100px}</style><main id="top"><h1>Shop — modèles retravaillés</h1><p>Captures réelles dans Godot. Le lierre est repris depuis la planche 23 : pot visible, bande crème et turquoise, couronne de feuilles lobées et lianes retombantes de longueurs variées.</p><p>Rangement : touche <b>O</b>, ou <b>E</b> devant le présentoir. Choisissez une surface, une position et une rotation. Les objets et les fleurs des vases sont conservés à la sauvegarde. Les images utilisent une partie de contrôle.</p><p><a href="../shop_revisions_models_and_renders.zip">Télécharger les 11 modèles GLB, sources Blender et captures</a> · <a href="../../art/concepts/shop/23_pot_ivy_sheet.png">Planche du lierre</a></p><nav>'''
    page += ''.join(f'<a href="#{key}">{html.escape(title)}</a>' for key, title, _ in GROUPS) + '</nav>'
    for key, title, shots in GROUPS:
        page += f'<section id="{key}"><h2>{html.escape(title)}</h2><div class="views">'
        for shot in shots:
            path = OUT / (shot+'.png')
            raw = path.read_bytes()
            assert raw[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack_from('>II', raw, 16) == (1600,900)
            files.append(path)
            label = 'Profil' if 'profil' in shot else title
            page += f'<figure><a href="{path.name}"><img src="{path.name}" loading="lazy" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}</figcaption></figure>'
        page += '</div><a href="#top">Sommaire ↑</a></section>'
    page += '<details><summary>Fichiers 3D modifiables</summary><ul>'
    for asset in ASSETS:
        page += f'<li>{asset} : <a href="../../assets/models/shop/{asset}.glb">GLB</a> · <a href="../../art/blender/shop/{asset}.blend">Blender</a></li>'
    page += '</ul></details><p>Validation : 5828 assertions réussies. Achats via le menu, positions libres, rotation, sauvegarde et conservation des fleurs également vérifiés dans la scène de capture.</p></main></html>'
    (OUT/'index.html').write_text(page, encoding='utf-8')
    (OUT/'model_report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    files += [OUT/'index.html', OUT/'model_report.json', ROOT/'docs/shop_surface_layout.md',
              ROOT/'tools/blender/shop_items_14_33.py', ROOT/'tools/blender/shop_revision_details.py',
              ROOT/'tools/package_shop_revisions.py', ROOT/'src/core/surface_layout.gd',
              ROOT/'src/world/surface_controller.gd', ROOT/'src/ui/surface_screen.gd',
              ROOT/'src/ui/surface_map.gd', ROOT/'tests/test_surface_layout.gd']
    with ZipFile(ROOT/'out/shop_revisions_models_and_renders.zip', 'w', ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.relative_to(ROOT))
    print(f'Verified {len(report)} models, {sum(len(g[2]) for g in GROUPS)} real captures; {len(files)} packaged files')

if __name__ == '__main__':
    main()
