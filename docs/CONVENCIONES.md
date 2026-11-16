# Convenciones del código de Cuatro Cortes

## Idioma

- **Textos que ve el jugador:** nunca en el código ni en las escenas. Se escriben como keys en
  `resources/i18n/rosetta.csv` (columnas `keys,es,en`). `tools/check_i18n.gd` lo comprueba.
- **Identificadores nuevos (variables, funciones, señales, nodos, ficheros):** en inglés.
- **Identificadores que ya existen en castellano** (`rey`, `clero`, `nobleza`, `descontento`, `riqueza`,
  `titulo`, `mision`, `cura`, `malechor`...): se mantienen. Son vocabulario del juego y coinciden con
  las columnas de `missions_v2.csv` y `buildings.txt`. Renombrarlos a la vez obligaría a cambiar
  datos, escenas y scripts de golpe sin ganar nada para el jugador.
- **Comentarios:** en castellano.

## Nombres

- **Ficheros:** `snake_case` (`mission_window.tscn`, `agent.gd`), como recomienda la guía de estilo de Godot.
- **Nodos de escena:** `PascalCase` y con nombre que diga qué son (`TopBar`, `InfluencePanel`, `Paca`), nunca
  `HBoxContainer2`.
- **Clases (`class_name`):** `PascalCase`.

## Trazas

- `DebugLog.log(...)` en lugar de `print(...)`: solo escribe en builds de depuración.
