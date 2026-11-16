# Compone resources/villa_olivares.png a partir de dos ilustraciones del propio juego:
# el patio porticado de mercado.png con el parterre de jardin.png, sin el rótulo de la puerta.
# Uso: python3 tools/villa_olivares.py <carpeta de salida> <raíz del proyecto>
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = sys.argv[1]
ROOT = sys.argv[2]
POLY = [(70, 245), (250, 152), (440, 245), (445, 252), (258, 378), (70, 262)]
GATE = [(124, 281), (131, 275), (158, 270), (192, 304), (192, 352), (124, 352)]
m = Image.open(ROOT + '/resources/mercado.png').convert('RGBA')
j = Image.open(ROOT + '/resources/jardin.png').convert('RGBA')
layer = Image.new('RGBA', m.size, (0, 0, 0, 0))
layer.alpha_composite(j, (0, 8))
mask = Image.new('L', m.size, 0)
d = ImageDraw.Draw(mask)
d.polygon(POLY, fill=255)
d.polygon(GATE, fill=0)
mask = mask.filter(ImageFilter.GaussianBlur(1.0))
out = m.copy()
out.paste(layer, (0, 0), Image.composite(layer.getchannel('A'), Image.new('L', m.size, 0), mask))

# Borrar las letras del friso: píxeles oscuros en la banda del rótulo
a = np.array(out).astype(float)
band = Image.new('L', m.size, 0)
ImageDraw.Draw(band).polygon([(138, 283), (146, 282), (178, 303), (176, 312), (138, 292)], fill=255)
band = np.array(band) > 0
lum = a[..., :3].mean(2)
txt = band & (lum < 150)
txt = np.array(Image.fromarray((txt * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))) > 0
known = ~txt
for _ in range(12):
    acc = np.zeros_like(a)
    cnt = np.zeros(a.shape[:2])
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            sh = np.roll(np.roll(a, dy, 0), dx, 1)
            kn = np.roll(np.roll(known, dy, 0), dx, 1)
            acc += sh * kn[..., None]
            cnt += kn
    fill = (~known) & (cnt > 0)
    a[fill] = acc[fill] / cnt[fill][:, None]
    known = known | fill
out = Image.fromarray(a.clip(0, 255).astype(np.uint8), 'RGBA')
out.save(S + '/villa_olivares.png')
big = out.resize((1000, 1000), Image.LANCZOS)
bg = Image.new('RGBA', big.size, (255, 255, 255, 255))
bg.alpha_composite(big)
bg.save(S + '/villa_view.png')
z = out.crop((100, 250, 220, 380)).resize((480, 520), Image.LANCZOS)
bz = Image.new('RGBA', z.size, (255, 255, 255, 255))
bz.alpha_composite(z)
bz.save(S + '/villa_puerta.png')
