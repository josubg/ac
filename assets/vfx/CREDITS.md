# Créditos de recursos VFX/SFX

## Recursos incluidos

Ninguno de terceros. Todos los sonidos y texturas de partículas del sistema
`Juice` se **generan por código** al arrancar (la primera vez que se usan):

| Recurso | Dónde se genera | Autoría / licencia |
|---|---|---|
| Sonidos `seal`, `crack`, `paper`, `coin`, `click`, `thud`, `chime`, `bell`, `toll` | `scripts/fx/juice_sfx.gd` (síntesis aditiva y ruido filtrado, AudioStreamWAV 22 050 Hz mono) | Código propio del proyecto. Sin dependencias externas. |
| Texturas de partículas `soft`, `spark`, `coin`, `shard` | `scripts/fx/juice_particles.gd` (Image generada en tiempo de ejecución) | Código propio del proyecto. Sin dependencias externas. |
| Shader de viñeta | `scripts/fx/vignette.gdshader` | Código propio del proyecto. |

Motivo: la descarga automática desde Kenney no estaba disponible en esta
sesión, y la síntesis tiene ventajas para la build web (cero bytes de
assets, nada que importar, sin atribuciones que mantener).

## Cómo sustituirlos por grabaciones o texturas

Sin tocar código:

- **Sonidos**: poner `res://assets/vfx/sfx/<nombre>.ogg` (o `.wav`/`.mp3`) con
  el mismo nombre (`seal.ogg`, `bell.ogg`…). `JuiceSfx.get_stream()` usa el
  fichero si existe.
- **Texturas**: poner `res://assets/vfx/particles/<nombre>.png` (`spark.png`,
  `shard.png`, `soft.png`, `coin.png`).

Fuentes recomendadas (CC0, descarga manual desde la web oficial):

| Pack | Autor | URL | Licencia | Uso sugerido |
|---|---|---|---|---|
| RPG Audio | Kenney | https://kenney.nl/assets/rpg-audio | CC0 1.0 | `bookFlip*` → `paper`; `handleCoins` → `coin`; `cloth*` → arrastrar agentes |
| Interface Sounds | Kenney | https://kenney.nl/assets/interface-sounds | CC0 1.0 | `click` |
| Impact Sounds | Kenney | https://kenney.nl/assets/impact-sounds | CC0 1.0 | `thud`, `seal` |
| Particle Pack | Kenney | https://kenney.nl/assets/particle-pack | CC0 1.0 | `spark`, `soft` |

Al añadir cualquiera, registrar aquí: fichero, autor, URL exacta y licencia.
