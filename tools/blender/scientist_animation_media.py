"""Create an inline GIF and review frames from Godot's MJPEG AVI recording."""
from io import BytesIO
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[2]
out=root/"out/blender"
raw=(out/"scientist_animations.avi").read_bytes()
frames=[]
offset=0
while True:
    start=raw.find(b"\xff\xd8\xff",offset)
    if start<0:
        break
    end=raw.find(b"\xff\xd9",start)+2
    if end<2:
        break
    frames.append((start,end))
    offset=end
assert len(frames)>=330,len(frames)

def frame(index):
    a,b=frames[index]
    return Image.open(BytesIO(raw[a:b])).convert("RGB")

for name,index in [("idle",45),("walk",120),("profile",180),("return",300)]:
    frame(index).save(out/f"scientist_animation_{name}.png")
palette=frame(120).resize((960,540)).quantize(colors=128)
images=[]
# Skip startup frames; keep the original playback speed (one frame in three).
for i in range(6,len(frames),3):
    im=frame(i).resize((960,540),Image.Resampling.LANCZOS)
    images.append(im.quantize(palette=palette,dither=Image.Dither.NONE))
images[0].save(out/"scientist_animations.gif",save_all=True,append_images=images[1:],
               duration=100,loop=0,optimize=True,disposal=1)
print(f"AVI: {len(frames)} frames; GIF: {len(images)} frames")
