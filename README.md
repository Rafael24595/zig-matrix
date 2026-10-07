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
| `-tc` | Theme color | Green | White, Black, Red, Green, Blue, Yellow, Cyan, Magenta, Orange, Purple, Gray, Pink, Brown, Aqua, Navy, Teal, NeonPink, NeonGreen, NeonBlue, NeonYellow, NeonOrange, NeonPurple, NeonCyan, NeonRed |
| `-tg` | Theme gradient | Default | Default, Linear, Circular |
| `-ts` | Theme symbol | Default | Default, Binary, Latin, LatinUpper, LatinLower, Digits, Symbols, Hex, Base64, Blocks, Extended, Katana, Fade, Matrix, Code, SciFi, Runes, Math, Arcane, Telemetry, Cyrillic, CyrillicUpper, CyrillicLower, Greek, GreekUpper, GreekLower, Arabic, Devanagari |
| `-mm` | Matrix mode | Rain | Rain, Wave, Wall |
| `-cm` | Color mode | RGB | RGB, ANSI, VOID |
| `-o` | Matrix orientation | Vertical | Vertical, Horizontal |

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
zig-out/bin/zig-matrix -ts Binary
```

### Set a custom rain color

```sh
zig-out/bin/zig-matrix -tc NeonBlue
```

### Set a custom rain gradient

```sh
zig-out/bin/zig-matrix -tg Circular
```

### Use a specific matrix mode

```sh
zig-out/bin/zig-matrix -mm Wave
```

### Render the matrix horizontally

```sh
zig-out/bin/zig-matrix -o Horizontal
```

### Use ANSI color mode

```sh
zig-out/bin/zig-matrix -cm ANSI
```

### Combine multiple options

```sh
zig-out/bin/zig-matrix -tc NeonGreen -tg Circular -ts Binary -mm Wave -o Horizontal
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
