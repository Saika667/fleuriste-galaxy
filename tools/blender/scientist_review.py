"""Assemble unretouched reference/render comparisons for visual review."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps

root=Path(__file__).resolve().parents[2]
out=root/"out/blender"
font=ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf",23)
small=ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf",19)
plate=Image.new("RGB",(1600,1000),"#faf9f5")
draw=ImageDraw.Draw(plate)
draw.text((35,20),"Savant — références et reconstruction 3D",font=font,fill="#242623")
items=[(root/"art/ref/old_scientist/front.png","Référence : face"),
       (out/"sci_v2_front.png","Modèle : face"),
       (root/"art/ref/old_scientist/three_quarter.png","Référence : trois quarts"),
       (out/"sci_v2_imported_three_quarter.png","GLB réimporté : trois quarts")]
for i,(path,label) in enumerate(items):
    im=Image.open(path).convert("RGB")
    mask=im.convert("L").point(lambda value:255 if value<215 else 0)
    bounds=mask.getbbox()
    if bounds:
        im=im.crop(bounds)
    im=ImageOps.contain(im,(355,790),Image.Resampling.LANCZOS)
    x=i*400+(400-im.width)//2
    plate.paste(im,(x,105+(790-im.height)//2))
    draw.text((i*400+22,65),label,font=small,fill="#363a33")
    if i:
        draw.line((i*400,65,i*400,925),fill="#d4d5ce",width=1)
draw.text((35,944),"Comparaison visuelle : fidélité 1:1 non atteinte. Les références et les rendus sont recadrés à hauteur égale.",
          font=small,fill="#53584d")
plate.save(out/"sci_v2_review.png")
print(out/"sci_v2_review.png")
