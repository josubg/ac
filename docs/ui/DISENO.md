# Diseño de la interfaz: «el despacho del Conde-Duque»

La interfaz es la mesa de trabajo de Olivares en 1640: bandas de **cuero nogal** arriba y abajo, el plano de Mancinelli en el centro y, encima, **cartas de pergamino** con el **lacre** clavado. Lo memorable es la carta lacrada; lo demás se queda sobrio.

## Paleta

| Nombre | Hex | Uso |
|---|---|---|
| Pergamino | `#E6D3A8` | Cartas y ventanas (siempre con textura, nunca plano) |
| Tinta de agalla | `#2B1B12` | Texto sobre pergamino |
| Lacre | `#7E1A16` | Acción principal, fracaso, peligro |
| Oro viejo | `#A8843A` / `#C9A65A` | Filetes, iconos y cifras del HUD (con moderación) |
| Nogal | `#22160F` | Cuero del HUD y fondo general (`default_clear_color`) |

Colores heráldicos de las barras: Rey oro `#B8913F`, Nobleza azul `#33548C`, Iglesia morado litúrgico `#6B3D73`, Descontento pardo `#805C38`. Todas viran a lacre `#9A2A22` al acercarse al peligro (`main.gd::_update_color`).

## Tipografía

- **IM Fell English SC**: títulos de carta, botones y rótulos del HUD. Tipos de imprenta del XVII; versalitas reales, no mayúsculas forzadas.
- **EB Garamond** (variable, peso 460): texto de misiones, edificios y créditos. Numerales de caja alta (`lnum`) en las barras.
- **IM Fell English cursiva**: lo que alguien *dice* (la monja, los sonetos finales) e indicaciones al jugador.
- **IM Fell French Canon**: rótulo del título y palabra final («Fin», «Desterrado»). Sin letra gótica: la UnifrakturMaguntia es de capitulares y no se lee en palabras enteras.

## Variaciones del tema

Todo está en `assets/ui/theme/cuatro_cortes.tres` (asignado en `project.godot`, `gui/theme/custom`). **No editar el `.tres` a mano**: se genera con `tools/build_theme.gd`.

| Variación | Base | Para |
|---|---|---|
| `PanelPergamino` | PanelContainer | Ventanas (misión, resolución, edificio, propiedades, créditos, monja) |
| `PanelCartela` / `PanelCartelaSimple` | PanelContainer / Panel | Cartela de la fecha y textos cortos |
| `PanelFicha` | PanelContainer | Fichas sin marco |
| `PanelCueroSuperior` / `PanelCueroInferior` | Panel / PanelContainer | Bandas del HUD |
| `PanelFichaAgente` | Panel | Ficha del agente al pasar el ratón |
| `Button` (por defecto) | — | Botón de lacre: acción principal |
| `BotonTinta` | Button | Secundario sobre pergamino («Cerrar») |
| `BotonCuero` | Button | Botones sobre el HUD |
| `BotonMenu` | Button | Menú principal |
| `TituloCarta`, `SubtituloCarta`, `NotaCarta`, `Voz` | Label | Texto sobre pergamino |
| `EtiquetaCuero`, `CifraCuero`, `NotaCuero`, `Fecha` | Label | Texto del HUD |
| `Soneto`, `TitularFinal` | Label | Pantallas de cierre |

Paneles y `PanelContainer` son transparentes por defecto: el pergamino se pide explícitamente con la variación.

## Herramientas

```bash
# Regenerar texturas (Pillow + numpy)
python3 tools/ui_textures.py
# Regenerar el tema
"/Applications/Godot 4.7.2.app/Contents/MacOS/Godot" --headless --path . --script res://tools/build_theme.gd
# Capturas de todas las pantallas
"/Applications/Godot 4.7.2.app/Contents/MacOS/Godot" --path . --resolution 1920x1080 --script res://tools/ui_capture.gd -- --out="$PWD/docs/ui/despues"
```

Capturas antes/después en `docs/ui/antes` y `docs/ui/despues`.
