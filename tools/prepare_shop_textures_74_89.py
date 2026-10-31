"""Extract flat illustrations from approved orthographic sheet panels for UV mapping."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/concepts/shop'
OUT=ROOT/'assets/textures/shop'
OUT.mkdir(parents=True,exist_ok=True)
SPECS=[
('74_hatch_rug_sheet.png','hatch_rug_weave',(84,151,476,503)),
('81_framed_flower_0_sheet.png','framed_rose_painting',(166,205,322,420)),
('82_framed_flower_1_sheet.png','framed_sunflower_painting',(144,185,323,425)),
('83_framed_flower_2_sheet.png','framed_xeno_painting',(143,180,317,422)),
('84_book_0_sheet.png','botany_cover',(159,153,571,388)),
('85_book_1_sheet.png','flowers_guide_cover',(141,160,443,407)),
('86_book_2_sheet.png','strange_plants_cover',(160,145,481,406)),
]
for sheet,name,rect in SPECS:
    with Image.open(ART/sheet) as im:
        assert im.size==(1536,1024)
        im.crop(rect).convert('RGB').save(OUT/(name+'.png'))
print('Seven approved flat artwork textures extracted.')
