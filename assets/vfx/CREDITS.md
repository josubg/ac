# Créditos de recursos VFX/SFX

## Sonidos (`assets/vfx/sfx/`)

Todos son grabaciones **CC0 1.0** (dominio público: uso libre, también comercial,
sin atribución obligatoria). Se apuntan igualmente para poder comprobarlos o
bajar el original. Los de Freesound son las previsualizaciones HQ que la web
sirve sin cuenta. Se han recortado y pasado a mono con ffmpeg, se han
normalizado a -20 LUFS de sonoridad momentánea máxima (pico real ≤ -1 dBTP; los
transitorios quedan por debajo, limitados por el pico) y se han codificado a
Ogg Vorbis con oggenc. La mezcla relativa está en las llamadas a `Juice.sfx`
(ver `docs/vfx/propuesta_juice.md`, sección 7).

| Fichero | Uso en el juego | Original | Autor | Licencia | Página |
|---|---|---|---|---|---|
| `seal.ogg` | sello de lacre que se estampa | Wax seal (primer golpe, 0,27-0,72 s) | Cerise_Virtuelle | CC0 | https://freesound.org/people/Cerise_Virtuelle/sounds/759526/ |
| `crack.ogg` | el lacre se rompe | twig snap classic.wav | martian | CC0 | https://freesound.org/people/martian/sounds/251464/ |
| `paper.ogg` | pergamino, cartas | page turn sound effect (0,1-0,9 s) | stumpbutt | CC0 | https://freesound.org/people/stumpbutt/sounds/431871/ |
| `thud.ogg` | golpe sordo (fracaso, portazo) | Book Dropping 1.wav | LightDJ | CC0 | https://freesound.org/people/LightDJ/sounds/267481/ |
| `chime.ogg` | campanilla de éxito | bell2.wav (2 s) | Tairblenn | CC0 | https://freesound.org/people/Tairblenn/sounds/549897/ |
| `bell.ogg` | campana de iglesia (domingos, donaciones) | BELL.wav (filtro paso bajo 3,5 kHz, más lejana) | kgeshev | CC0 | https://freesound.org/people/kgeshev/sounds/378799/ |
| `toll.ogg` | campana grave de aviso (umbrales, derrota) | Bell.ogg (primer toque, 0-2,15 s) | egomassive | CC0 | https://freesound.org/people/egomassive/sounds/536731/ |
| `coin.ogg` | monedas | `handleCoins2.ogg` de RPG Audio | Kenney | CC0 | https://kenney.nl/assets/rpg-audio |
| `click.ogg` | clic de botón (muy bajo) | `metalClick.ogg` de RPG Audio (primer clic) | Kenney | CC0 | https://kenney.nl/assets/rpg-audio |

Para cambiar un sonido basta con sustituir el fichero con el mismo nombre
(`.ogg`, `.wav` o `.mp3`; ver `scripts/fx/juice_sfx.gd`) y actualizar esta tabla.

## Código propio (sin dependencias externas)

| Recurso | Dónde | Autoría / licencia |
|---|---|---|
| Texturas de partículas `soft`, `spark`, `coin`, `shard` | `scripts/fx/juice_particles.gd` (Image generada en tiempo de ejecución) | Código propio del proyecto. Se pueden sustituir por `res://assets/vfx/particles/<nombre>.png`. |
| Shaders `map_post`, `ink_transition`, `vignette` | `scripts/fx/*.gdshader` | Código propio del proyecto. |

Al añadir cualquier recurso de terceros, registrar aquí: fichero, autor, URL exacta y licencia.
