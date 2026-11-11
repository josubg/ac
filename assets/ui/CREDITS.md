# Créditos de recursos de interfaz

Todos los recursos de `assets/ui/` tienen licencia libre y verificable. Se descargaron el 11/11/2026 desde la fuente oficial indicada.

## Tipografías (SIL Open Font License 1.1)

Cada carpeta incluye su `OFL.txt`.

| Archivo | Familia | Autor | Fuente |
|---|---|---|---|
| `fonts/imfellenglishsc/IMFeENsc28P.ttf` | IM Fell English SC | Igino Marini | https://github.com/google/fonts/tree/main/ofl/imfellenglishsc |
| `fonts/imfellenglish/IMFeENrm28P.ttf`, `IMFeENit28P.ttf` | IM Fell English (redonda y cursiva) | Igino Marini | https://github.com/google/fonts/tree/main/ofl/imfellenglish |
| `fonts/ebgaramond/EBGaramond-VF.ttf` | EB Garamond (variable) | The EB Garamond Project Authors (Georg Duffner, Octavio Pardo) | https://github.com/google/fonts/tree/main/ofl/ebgaramond |
| `fonts/unifrakturmaguntia/UnifrakturMaguntia-Book.ttf` | UnifrakturMaguntia | j. 'mach' wust, Peter Wiegel | https://github.com/google/fonts/tree/main/ofl/unifrakturmaguntia |

## Iconos (CC BY 3.0, requieren atribución)

De game-icons.net (https://game-icons.net), licencia https://creativecommons.org/licenses/by/3.0/. Se usan en blanco y se tiñen en Godot (`self_modulate`). La atribución figura en los créditos del juego (menú, Créditos).

| Archivo | Autor | URL |
|---|---|---|
| `icons/crown.svg` | Lorc | https://game-icons.net/1x1/lorc/crown.html |
| `icons/crested-helmet.svg` | Lorc | https://game-icons.net/1x1/lorc/crested-helmet.html |
| `icons/sands-of-time.svg` | Lorc | https://game-icons.net/1x1/lorc/sands-of-time.html |
| `icons/quill-ink.svg` | Lorc | https://game-icons.net/1x1/lorc/quill-ink.html |
| `icons/wax-seal.svg` | Lorc | https://game-icons.net/1x1/lorc/wax-seal.html |
| `icons/church.svg` | Delapouite | https://game-icons.net/1x1/delapouite/church.html |
| `icons/pitchfork.svg` | Delapouite | https://game-icons.net/1x1/delapouite/pitchfork.html |
| `icons/two-coins.svg` | Delapouite | https://game-icons.net/1x1/delapouite/two-coins.html |
| `icons/family-house.svg` | Delapouite | https://game-icons.net/1x1/delapouite/family-house.html |
| `icons/fleur-de-lys.svg` | Delapouite | https://game-icons.net/1x1/delapouite/fleur-de-lys.html |

## Texturas (CC0, dominio público)

Escaneos de ambientCG (https://ambientcg.com, licencia https://docs.ambientcg.com/license/). Los originales están en `textures/src/` (con `.gdignore`, no se importan ni se exportan).

| Original | URL |
|---|---|
| `textures/src/Paper006_1K-JPG_Color.jpg` | https://ambientcg.com/view?id=Paper006 |
| `textures/src/Paper005_1K-JPG_Color.jpg` | https://ambientcg.com/view?id=Paper005 |
| `textures/src/Leather026_1K-JPG_Color.jpg` | https://ambientcg.com/view?id=Leather026 |

Las texturas finales de `textures/*.png` (pergamino, cuero, botones de lacre, viñeta) se generan a partir de esos escaneos con `tools/ui_textures.py`; son obra derivada propia del proyecto.
