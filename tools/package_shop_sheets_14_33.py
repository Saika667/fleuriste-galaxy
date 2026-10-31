"""Package the twenty illustrated shop references (14–33), without changing game assets."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "art/concepts/shop"
MANIFEST = ART / "items_14_33_prompts.json"

def main():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    jobs = manifest["jobs"]
    assert len(jobs) == 20 and [j["number"] for j in jobs] == list(range(14, 34))
    sources = ART / "items_14_33_generation_results.json"
    if sources.exists():
        for result in json.loads(sources.read_text(encoding="utf-8")):
            dest = ART / result["output"]
            original = Path(result["source"])
            if not dest.exists():
                shutil.copy2(original, dest)
    for job in jobs:
        path = ART / job["output"]
        assert path.is_file() and path.stat().st_size > 10000, f"Missing sheet: {path}"
        assert path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n", f"Not PNG: {path}"
    page = """<!doctype html>
<html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shop — Planches 14 à 33</title>
<style>
:root{color-scheme:light}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f8f3e8;color:#183837;font:17px/1.6 system-ui}main{max-width:1560px;margin:auto;padding:32px 24px}h1{line-height:1.2}a{color:#147775}p{max-width:1100px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}.card{display:block;background:#fffaf0;border:1px solid #d9c8aa;padding:8px;border-radius:12px;text-decoration:none;font-weight:650}.card img{width:100%;aspect-ratio:1.5;object-fit:contain;border-radius:7px}.sheet{margin:48px 0;scroll-margin-top:20px}.sheet img{display:block;width:100%;height:auto;border-radius:14px;border:1px solid #deceb3}.sheet h2{font-size:23px}.back{float:right;font-size:15px;font-weight:400}input{font:inherit;background:#fffaf0;border:1px solid #b8a588;padding:10px 15px;border-radius:9px;width:min(100%,560px);margin:16px 0 22px}.muted{color:#687773}.top{position:fixed;right:18px;bottom:18px;background:#146e69;color:white;padding:8px 18px;border-radius:30px;text-decoration:none}a:focus-visible,input:focus-visible{outline:3px solid #db9a30}
[hidden]{display:none!important}
</style><main id="top"><h1>Shop — 20 nouveaux designs</h1>
<p>Items <strong>14 à 33</strong> du catalogue. Une planche cartoon par élément avec vues complémentaires, détails de construction et palette pour préparer la modélisation 3D.</p>
<p>Les contenants et les fleurs sont des composants séparés : les compositions illustrées sont des exemples. Les emballages accueillent les fleurs choisies par le joueur. Les cotes indiquées sont des repères de conception à confirmer lors de la modélisation.</p>
<p><a href="../../../out/shop_items_14_33_reference_sheets.zip">Télécharger les 20 planches et les prompts (ZIP)</a> · <a href="items_07_13.html">Planches 07–13</a> · <a href="index.html">Planches 01–06</a> · <a href="../../../out/shop_catalog/index.html">Catalogue du jeu</a></p>
<label for="search">Rechercher un élément</label><br><input id="search" type="search" placeholder="Numéro, vase, bocal, plante…">
<nav class="grid" aria-label="Les vingt planches">
"""
    for j in jobs:
        title = f'{j["number"]:02d} — {j["title_fr"]}'
        safe = html.escape(title)
        page += f'<a class="card" data-search="{safe.lower()}" href="#item-{j["number"]}"><img src="{j["output"]}" loading="lazy" alt=""><span>{safe}</span></a>'
    page += '</nav>'
    for j in jobs:
        title = html.escape(f'{j["number"]:02d} — {j["title_fr"]}')
        page += f'<section class="sheet" id="item-{j["number"]}"><h2>{title}<a class="back" href="#top">Retour aux planches ↑</a></h2><a href="{j["output"]}" target="_blank"><img src="{j["output"]}" loading="lazy" alt="Planche de référence : {title}"></a></section>'
    page += """<p class="muted">Illustrations produites avec l’outil intégré image_gen. <a href="items_14_33_prompts.json">Prompts et références</a>. Ces planches sont des propositions de design ; les modèles du jeu restent à réaliser.</p></main><a class="top" href="#top">↑ Sommaire</a><script>
document.querySelector('#search').addEventListener('input',e=>{const q=e.target.value.toLocaleLowerCase('fr');document.querySelectorAll('.card').forEach(c=>c.hidden=!c.dataset.search.includes(q));});
</script></html>"""
    gallery = ART / "items_14_33.html"
    gallery.write_text(page, encoding="utf-8")
    package = ROOT / "out/shop_items_14_33_reference_sheets.zip"
    with ZipFile(package, "w", ZIP_DEFLATED) as z:
        for p in [gallery, MANIFEST] + [ART / j["output"] for j in jobs]:
            z.write(p, p.name)
        z.writestr("LISEZ-MOI.txt", "20 planches de design — items 14 à 33.\nOuvrir items_14_33.html ou chaque PNG.\nGénération : outil intégré image_gen.\nLes modèles 3D ne sont pas inclus.\n")
    print(f"VERIFIED: {len(jobs)} PNG sheets; gallery: {gallery}; ZIP: {package.stat().st_size:,} bytes")

if __name__ == "__main__":
    main()

