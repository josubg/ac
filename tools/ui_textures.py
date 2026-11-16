#!/usr/bin/env python3
"""Genera las texturas de interfaz de Cuatro Cortes a partir de escaneos CC0.

Fuentes (assets/ui/textures/src, CC0 de ambientCG.com):
  Paper006_1K-JPG_Color.jpg  -> pergamino
  Paper005_1K-JPG_Color.jpg  -> arrugas / manchas de envejecimiento
  Leather026_1K-JPG_Color.jpg -> cuero de las barras del despacho

Uso:  python3 tools/ui_textures.py
Requiere Pillow y numpy. Salida en assets/ui/textures/.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets/ui/textures/src")
OUT = os.path.join(ROOT, "assets/ui/textures")

# Paleta (ver docs/ui/DISENO.md)
PERGAMINO = (224, 203, 156)
TINTA = (43, 27, 18)
LACRE = (126, 26, 22)
ORO = (168, 132, 58)
NOGAL = (34, 22, 15)

random.seed(1640)
np.random.seed(1640)


def load(name):
    return np.asarray(Image.open(os.path.join(SRC, name)).convert("RGB")).astype(np.float32) / 255.0


def smooth_noise(w, h, scale, octaves=3):
    """Ruido suave (value noise) en [0,1]."""
    acc = np.zeros((h, w), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        s = max(2, int(scale / (2 ** o)))
        small = np.random.rand(h // s + 2, w // s + 2).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((w + 2 * s, h + 2 * s), Image.BICUBIC)
        acc += amp * (np.asarray(img).astype(np.float32)[s:s + h, s:s + w] / 255.0)
        tot += amp
        amp *= 0.5
    acc /= tot
    return (acc - acc.min()) / (acc.max() - acc.min() + 1e-6)


def parchment_base(w, h, ox=0, oy=0, tone=PERGAMINO):
    """Pergamino: grano del escaneo + manchas de edad, entonado a la paleta."""
    paper = load("Paper006_1K-JPG_Color.jpg")
    crumple = load("Paper005_1K-JPG_Color.jpg")
    reps_y, reps_x = h // 1024 + 2, w // 1024 + 2
    paper = np.tile(paper, (reps_y, reps_x, 1))[oy:oy + h, ox:ox + w]
    crumple = np.tile(crumple, (reps_y, reps_x, 1))[oy:oy + h, ox:ox + w]
    lum = paper.mean(axis=2)
    lum = (lum - lum.mean()) / (lum.std() + 1e-6)
    cr = crumple.mean(axis=2)
    cr = (cr - cr.mean()) / (cr.std() + 1e-6)
    stains = smooth_noise(w, h, 180, 4)
    base = np.array(tone, np.float32) / 255.0
    shade = 1.0 + 0.035 * lum + 0.03 * cr - 0.10 * (stains - 0.5)
    rgb = base[None, None, :] * shade[..., None]
    # Las manchas viran hacia ocre tostado
    tint = np.array([0.80, 0.66, 0.44], np.float32)
    k = np.clip((stains - 0.55) * 0.5, 0, 0.18)[..., None]
    rgb = rgb * (1 - k) + tint * k
    return np.clip(rgb, 0, 1)


def edge_distance(w, h):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    return np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))


def deckle_alpha(w, h, inset, rough):
    """Borde barbado irregular: alfa 0 fuera, 1 dentro."""
    d = edge_distance(w, h)
    n = smooth_noise(w, h, 10, 3)
    n2 = smooth_noise(w, h, 3, 2)
    thr = inset + rough * (0.65 * n + 0.35 * n2)
    return np.clip((d - thr) / 1.6, 0, 1)


def burn(rgb, w, h, width, strength):
    d = edge_distance(w, h)
    n = smooth_noise(w, h, 40, 3)
    t = np.clip(1 - d / (width * (0.75 + 0.5 * n)), 0, 1) ** 1.8
    dark = np.array([0.36, 0.22, 0.11], np.float32)
    return rgb * (1 - strength * t[..., None]) + dark * (strength * t[..., None]) * 0.6


def to_img(rgb, alpha=None):
    a = np.ones(rgb.shape[:2], np.float32) if alpha is None else alpha
    arr = np.dstack([rgb, a])
    return Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8))


def draw_overlay(size, fn, ss=4):
    """Dibuja con supermuestreo para trazos limpios y devuelve RGBA."""
    w, h = size
    big = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    fn(ImageDraw.Draw(big), ss)
    return big.resize((w, h), Image.LANCZOS)


def lozenge(d, cx, cy, r, color, ss):
    d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=color)


def gilt_frame(w, h, inset, ss, double=True, corners=True, color=ORO):
    def fn(d, s):
        c = color + (235,)
        i = inset * s
        lw = int(2.2 * s)
        d.rectangle([i, i, w * s - i, h * s - i], outline=c, width=lw)
        if double:
            j = i + 6 * s
            d.rectangle([j, j, w * s - j, h * s - j], outline=color + (170,), width=int(1 * s))
        if corners:
            for (cx, cy) in [(i, i), (w * s - i, i), (i, h * s - i), (w * s - i, h * s - i)]:
                lozenge(d, cx, cy, 9 * s, c, s)
                lozenge(d, cx, cy, 4 * s, LACRE + (255,), s)
            # Florones en el centro de cada lado
            for (cx, cy) in [(w * s / 2, i), (w * s / 2, h * s - i), (i, h * s / 2), (w * s - i, h * s / 2)]:
                lozenge(d, cx, cy, 6 * s, c, s)
    return draw_overlay((w, h), fn, ss)


def parchment_panel(path, w, h, inset_deckle, rough, burn_w, frame_inset, double=True, corners=True, ox=0, oy=0):
    rgb = parchment_base(w, h, ox, oy)
    rgb = burn(rgb, w, h, burn_w, 0.7)
    alpha = deckle_alpha(w, h, inset_deckle, rough)
    img = to_img(rgb, alpha)
    if frame_inset:
        img = Image.alpha_composite(img, gilt_frame(w, h, frame_inset, 4, double, corners))
    img.save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT), img.size)


def leather_strip(path, w, h, rule_at):
    lea = load("Leather026_1K-JPG_Color.jpg")
    lea = np.tile(lea, (h // 1024 + 1, w // 1024 + 1, 1))[:h, :w]
    lum = lea.mean(axis=2)
    lum = (lum - lum.mean()) / (lum.std() + 1e-6)
    base = np.array(NOGAL, np.float32) / 255.0
    lum = np.asarray(Image.fromarray(((lum + 4) * 30).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 30 - 4
    rgb = base * (1.0 + 0.12 * lum[..., None])
    # Ligera luz central (cuero repujado)
    yy = np.linspace(-1, 1, h)[:, None]
    rgb *= (1.08 - 0.12 * yy ** 2)[..., None]
    img = to_img(np.clip(rgb, 0, 1))

    def fn(d, s):
        c = ORO + (230,)
        if rule_at == "bottom":
            y1, y2 = (h - 7) * s, (h - 3) * s
        else:
            y1, y2 = 6 * s, 2 * s
        d.line([(0, y1), (w * s, y1)], fill=c, width=int(2 * s))
        d.line([(0, y2), (w * s, y2)], fill=ORO + (150,), width=int(1 * s))
    img = Image.alpha_composite(img, draw_overlay((w, h), fn, 2))
    img.save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT), img.size)


def wax_button(path, w, h, top, bottom, rim, highlight, alpha=1.0, noise=0.05):
    """Botón de lacre: cera con degradado, bisel y brillo superior."""
    ss = 4
    W, H = w * ss, h * ss
    r = 9 * ss
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([2 * ss, 2 * ss, W - 2 * ss, H - 2 * ss], r, fill=255)
    yy = np.linspace(0, 1, H)[:, None]
    grad = np.array(top, np.float32) / 255 * (1 - yy[..., None]) + np.array(bottom, np.float32) / 255 * yy[..., None]
    grad = np.repeat(grad, W, axis=1)
    n = smooth_noise(W, H, 24 * ss, 3)
    grad *= (1 + noise * (n - 0.5) * 2)[..., None]
    img = to_img(np.clip(grad, 0, 1))
    img.putalpha(mask)

    def fn(d, s):
        d.rounded_rectangle([2 * s, 2 * s, W - 2 * s, H - 2 * s], r, outline=rim + (255,), width=int(1.6 * s))
        d.rounded_rectangle([4 * s, 4 * s, W - 4 * s, H - 4 * s], r - 2 * s, outline=highlight + (110,), width=int(1 * s))
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fn(ImageDraw.Draw(over), ss)
    img = Image.alpha_composite(img, over).resize((w, h), Image.LANCZOS)
    if alpha < 1:
        a = np.asarray(img.getchannel("A")).astype(np.float32) * alpha
        img.putalpha(Image.fromarray(a.astype(np.uint8)))
    img.save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT), img.size)


def vignette(path, size=512):
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32) / (size - 1) * 2 - 1
    r = np.sqrt(xx ** 2 + yy ** 2) / math.sqrt(2)
    a = np.clip((r - 0.35) / 0.65, 0, 1) ** 1.6 * 0.92
    rgb = np.ones((size, size, 3), np.float32) * (np.array(NOGAL, np.float32) / 255 * 0.5)
    to_img(rgb, a).save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT))


def gilt_molding(path, size, thick, shadow):
    """Marco dorado tallado: perfil con bocel, escocia y junquillo, luz desde arriba-izquierda."""
    ss = 2
    S = size * ss
    T = thick * ss
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    dl, dr, dt, db = xx, S - 1 - xx, yy, S - 1 - yy
    d = np.minimum(np.minimum(dl, dr), np.minimum(dt, db))
    u = np.clip(d / T, 0, 1.0001)  # 0 = borde exterior, 1 = borde interior
    # Perfil de luminancia a lo ancho de la moldura
    prof = np.interp(u, [0, .06, .16, .30, .42, .52, .60, .70, .78, .88, .95, 1.0],
                        [.15, .55, .95, .75, .45, .25, .55, .90, .60, .35, .70, .20])
    # Iluminación: lados superior/izquierdo más claros, inferior/derecho más oscuros
    side = np.select([d == dt, d == dl, d == db], [1.15, 1.05, 0.72], 0.82)
    n = smooth_noise(S, S, 6 * ss, 3)
    lum = np.clip(prof * side * (0.9 + 0.2 * n), 0, 1.2)
    dark = np.array([0.20, 0.12, 0.05]); mid = np.array([0.66, 0.50, 0.22]); hi = np.array([0.98, 0.88, 0.62])
    l = lum[..., None]
    rgb = np.where(l < 0.6, dark + (mid - dark) * (l / 0.6), mid + (hi - mid) * np.clip((l - 0.6) / 0.5, 0, 1))
    a = (u < 1.0).astype(np.float32)
    # Sombra interior que cae sobre el retrato
    inner = np.clip((d - T) / (shadow * ss), 0, 1)
    sh_a = (1 - inner) ** 2 * 0.65 * (d >= T)
    # Rosetas en las esquinas (bollones dorados)
    rr = T * 0.62
    for cx, cy in [(T / 2, T / 2), (S - T / 2, T / 2), (T / 2, S - T / 2), (S - T / 2, S - T / 2)]:
        dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / rr
        boss = dist < 1
        bl = np.clip(1.05 - 0.6 * dist - 0.35 * ((yy - cy) + (xx - cx)) / rr, 0.1, 1.3)
        bl = bl * (1 - 0.5 * np.exp(-((dist - 0.55) ** 2) / 0.004))
        bl3 = bl[..., None]
        brgb = np.where(bl3 < 0.6, dark + (mid - dark) * (bl3 / 0.6), mid + (hi - mid) * np.clip((bl3 - 0.6) / 0.5, 0, 1))
        rgb = np.where(boss[..., None], brgb, rgb)
        a = np.maximum(a, boss.astype(np.float32))
    rgb = np.where(a[..., None] > 0, rgb, 0.0)
    alpha = np.maximum(a, sh_a)
    img = to_img(np.clip(rgb, 0, 1), alpha).resize((size, size), Image.LANCZOS)
    img.save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT))


def wax_disc(path, size):
    """Tirador de deslizador: gota de lacre con brillo."""
    ss = 4
    S = size * ss
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    c = S / 2
    n = smooth_noise(S, S, 4 * ss, 2)
    ang = np.arctan2(yy - c, xx - c)
    r = np.sqrt((xx - c) ** 2 + (yy - c) ** 2) / (c * 0.92 * (1 + 0.05 * np.sin(ang * 7) + 0.03 * (n - .5)))
    a = np.clip((1 - r) * S / 6, 0, 1)
    shade = np.clip(1.0 - 0.55 * ((yy - c * 0.6) / S) - 0.35 * r ** 3, 0.3, 1.3)
    base = np.array([0.55, 0.11, 0.09])
    rgb = base * shade[..., None]
    hl = np.exp(-(((xx - c * 0.75) ** 2 + (yy - c * 0.65) ** 2) / (2 * (S * 0.12) ** 2)))
    rgb = rgb + hl[..., None] * np.array([0.45, 0.30, 0.25])
    # sello: anillo interior
    ring = np.exp(-((r - 0.55) ** 2) / (2 * 0.03 ** 2)) * 0.35
    rgb = rgb * (1 - ring[..., None])
    to_img(np.clip(rgb, 0, 1), a).resize((size, size), Image.LANCZOS).save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT))


def checkbox(path, size, checked):
    def fn(d, s):
        m = 3 * s
        d.rounded_rectangle([m, m, size * s - m, size * s - m], 4 * s, outline=TINTA + (230,), width=int(2 * s),
                            fill=(LACRE + (255,)) if checked else (TINTA + (18,)))
        if checked:
            pts = [(size * s * .26, size * s * .52), (size * s * .43, size * s * .70), (size * s * .76, size * s * .30)]
            d.line(pts, fill=PERGAMINO + (255,), width=int(3.2 * s), joint="curve")
    draw_overlay((size, size), fn, 4).save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT))


def speech_tail(path, w, h):
    """Cola del bocadillo: cuña de pergamino que apunta abajo a la izquierda, con filete dorado."""
    rgb = parchment_base(w, h, 200, 300)
    pts = [(w, h * 0.05), (0, h), (w, h * 0.62)]
    mask = Image.new("L", (w * 4, h * 4), 0)
    ImageDraw.Draw(mask).polygon([(x * 4, y * 4) for x, y in pts], fill=255)
    mask = mask.resize((w, h), Image.LANCZOS)
    img = to_img(rgb)
    img.putalpha(mask)

    def fn(d, s):
        c = ORO + (235,)
        d.line([(pts[0][0] * s, pts[0][1] * s), (pts[1][0] * s, pts[1][1] * s)], fill=c, width=int(2.2 * s))
        d.line([(pts[1][0] * s, pts[1][1] * s), (pts[2][0] * s, pts[2][1] * s)], fill=c, width=int(2.2 * s))
    img = Image.alpha_composite(img, draw_overlay((w, h), fn, 4))
    img.save(path, optimize=True)
    print("ok", os.path.relpath(path, ROOT))


def main():
    os.makedirs(OUT, exist_ok=True)
    o = lambda n: os.path.join(OUT, n)
    # Carta grande (ventanas de misión, créditos, tutorial, edificio)
    parchment_panel(o("pergamino_carta.png"), 1024, 1024, 4, 9, 64, 28)
    # Cartela pequeña (fecha, fichas, mensajes cortos)
    parchment_panel(o("pergamino_cartela.png"), 256, 128, 2, 4, 22, 9, double=False, corners=False, ox=300, oy=200)
    # Ficha sin marco (filas de propiedades)
    parchment_panel(o("pergamino_ficha.png"), 256, 256, 1, 3, 26, 0, ox=600, oy=500)
    # Bandas de cuero del despacho
    leather_strip(o("cuero_superior.png"), 1024, 96, "bottom")
    leather_strip(o("cuero_inferior.png"), 1024, 224, "top")
    # Botones de lacre
    wax_button(o("boton_lacre.png"), 96, 48, (150, 38, 31), (104, 22, 18), (52, 10, 8), (214, 120, 100))
    wax_button(o("boton_lacre_hover.png"), 96, 48, (176, 50, 40), (124, 28, 22), (52, 10, 8), (236, 150, 120))
    wax_button(o("boton_lacre_pulsado.png"), 96, 48, (96, 20, 16), (128, 30, 24), (40, 8, 6), (150, 70, 60))
    wax_button(o("boton_lacre_inactivo.png"), 96, 48, (128, 108, 92), (100, 84, 72), (70, 58, 50), (170, 150, 130), alpha=0.75, noise=0.03)
    vignette(o("vineta.png"))
    gilt_molding(o("marco_dorado.png"), 128, 15, 9)
    wax_disc(o("tirador_lacre.png"), 40)
    wax_disc(o("tirador_lacre_hover.png"), 44)
    speech_tail(o("cola_bocadillo.png"), 90, 70)
    checkbox(o("casilla.png"), 46, False)
    checkbox(o("casilla_marcada.png"), 46, True)


if __name__ == "__main__":
    main()
