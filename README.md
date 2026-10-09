# Zig Matrix

A terminal-based Matrix-style digital rain effect implemented in Zig ⚡.

It features configurable ASCII rain with customizable colors, gradients, symbols, movement modes, orientations, and rendering options.

> **Warning:** This program has been tested on modern terminals (Windows Terminal 1.23.13503.0). Older terminals may exhibit slow rendering or display issues when using RGB color mode. For better performance, consider using ANSI mode, or VOID mode for maximum speed.

---

## Features

* Configurable rain effect with adjustable:

  * Drop length
  * Rain color
  * Rain gradient
  * ASCII symbol set
  * Matrix mode
  * Matrix orientation
  * Color mode
  * Frame delay
  * Random seed
* Vertical and horizontal matrix orientations.
* Debug mode for displaying internal states such as memory usage, seed, and matrix dimensions.
* Automatic adaptation to terminal window resizing.
* Cross-platform signal handling for clean exit (Windows / Unix).

---

## Build & Run

### Requirements

* Zig compiler (tested on 0.15.1)

### Build

```sh
zig build
```

### Run

```sh
zig-out/bin/zig-matrix [options]
```

---

## Dynamic Matrix Size

The matrix automatically adapts to the size of your terminal window.

* The number of rows and columns is detected at runtime.
* If you resize the terminal while the program is running, the matrix adjusts to the new dimensions.
* The matrix orientation determines how the terminal dimensions are mapped to the rendered matrix.
* This ensures the rain effect always fills the visible area of the terminal.

---

## Command Line Options

The `zig-matrix` program supports several command line options to customize the Matrix rain effect.

| Option | Description | Default | Values |
|--------|-------------|---------|--------|
| `-h`, `--help` | Show the help message | — | — |
| `-v`, `--version` | Show project's version | — | — |
| `-d` | Enable debug mode | Off | — |
| `-s` | Random seed | Current timestamp in ms | Any unsigned integer |
| `-ms` | Frame delay in milliseconds | 50 | Any unsigned integer |
| `-l` | Drop length | 0.4 × matrix height | Any unsigned integer |
| `-tc` | Theme color | green | white, black, red, green, blue, yellow, cyan, magenta, orange, purple, gray, pink, brown, aqua, navy, teal, neon_pink, neon_green, neon_blue, neon_yellow, neon_orange, neon_purple, neon_cyan, neon_red |
| `-tg` | Theme gradient | default | default, linear, circular |
| `-ts` | Theme symbol | default | default, binary, latin, latin_upper, latin_lower, digits, symbols, hex, base64, blocks, extended, katana, fade, matrix, code, sci_fi, runes, math, arcane, telemetry, cyrillic, cyrillic_upper, cyrillic_lower, greek, greek_upper, greek_lower, arabic, devanagari |
| `-mm` | Matrix mode | rain | rain, wave, wall |
| `-cm` | Color mode | rgb | rgb, ansi, none |
| `-o` | Matrix orientation | vertical | vertical, horizontal |

---

## Recommended Terminal Setup

For the most immersive experience, a **black terminal background** is recommended. This provides better contrast and ensures the color and symbol themes are displayed as intended.

---

## Examples

### Run with default settings

```sh
zig-out/bin/zig-matrix
```

### Run in debug mode

```sh
zig-out/bin/zig-matrix -d
```

### Use a specific ASCII symbol set

```sh
zig-out/bin/zig-matrix -ts binary
```

### Set a custom rain color

```sh
zig-out/bin/zig-matrix -tc neon_blue
```

### Set a custom rain gradient

```sh
zig-out/bin/zig-matrix -tg circular
```

### Use a specific matrix mode

```sh
zig-out/bin/zig-matrix -mm wave
```

### Render the matrix horizontally

```sh
zig-out/bin/zig-matrix -o horizontal
```

### Use ANSI color mode

```sh
zig-out/bin/zig-matrix -cm ANSI
```

### Combine multiple options

```sh
zig-out/bin/zig-matrix -tc neon_green -tg circular -ts binary -mm wave -o horizontal
```

---

## Debug Mode

When enabled (`-d`), the program prints additional runtime information, including:

* Project name and version
* Memory usage (persistent & scratch)
* Execution parameters:

  * Frame delay
  * ASCII symbol mode
  * Rain color
  * Rain gradient
  * Matrix mode
  * Matrix orientation
  * Color mode
* Random seed
* Matrix dimensions

---

## Signal Handling

The program provides cross-platform signal handling for graceful shutdown.

* **Windows:** Uses `SetConsoleCtrlHandler` to intercept `CTRL+C`.
* **Unix/Linux:** Captures `SIGINT` (`Ctrl+C`).

Both implementations ensure:

* The console is cleaned up.
* The cursor is shown again.
* The program exits gracefully.
