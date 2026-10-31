"""Build contact sheets for visual QA without altering the reference originals."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parents[1]/'art/concepts/cellar'
jobs=json.loads((p/'prompts.json').read_text(encoding='utf-8'))['jobs']
fs=[p/j['output'] for j in jobs if (p/j['output']).exists()];out=p/'qa';out.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for k in range(0,len(fs),8):
    im=Image.new('RGB',(2400,900),'#fff6e5');d=ImageDraw.Draw(im)
    for i,f in enumerate(fs[k:k+8]):
        with Image.open(f) as a:
            a=a.convert('RGB');a.thumbnail((600,400))
            x=i%4*600;y=i//4*450;im.paste(a,(x,y));d.text((x+8,y+404),f.stem[:40],font=font,fill='black')
    im.save(out/f'contact_{k//8+1:02d}.jpg',quality=95)
print(f'{len(fs)} saved sheets inspected by file; {len(list(out.glob("*.jpg")))} QA contact pages.')
