# Zig Matrix

A terminal-based Matrix-style digital rain effect implemented in Zig ⚡.  
It features configurable ASCII rain with customizable colors, movement modes, and an optional debug display.


---

## Features

- Configurable rain effect with adjustable:
  - Drop length
  - Rain color
  - Rain gradient
  - ASCII mode
  - Matrix mode
  - Frame delay
- Debug mode for displaying internal states such as memory usage and seed.
- Cross-platform signal handling for clean exit (Windows / Unix).

---

## Build & Run

### Requirements
- Zig compiler (Tested on 0.16.0-dev.393+dd4be26f5)

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

The matrix adapts automatically to the size of your terminal window.  

- The number of columns and rows is detected at runtime.  
- If you resize the terminal while the program is running, the matrix will adjust to the new dimensions.  
- This ensures the rain effect always fills the visible area of the terminal.

## Command Line Options

The `zig-matrix` program supports several command line options to customize the matrix rain effect.

| Option | Description | Default | Values |
|--------|-------------|---------|--------|
| `-h`, `--help` | Show the help message | — | — |
| `-v`, `--version` | Show project's version | — | — |
| `-d` | Enable debug mode | Off | — |
| `-s` | Random seed | Current timestamp in ms | Any unsigned integer |
| `-ms` | Frame delay in milliseconds | 50 | Any unsigned integer |
| `-l` | Drop length | 10 | Any unsigned integer |
| `-c` | Rain color | Green | White, Black, Red, Green, Blue, Yellow, Cyan, Magenta, Orange, Purple, Gray, Pink, Brown, Aqua, Navy, Teal, NeonPink, NeonGreen, NeonBlue, NeonYellow, NeonOrange, NeonPurple, NeonCyan, NeonRed |
| `-g` | Rain gradient | Default | Default, Linear, Circular |
| `-r` | ASCII mode | Default | Default, Binary, Letters, Uppercase, Lowercase, Digits, Symbols, Hex, Base64, Fade |
| `-m` | Matrix mode | Rain | Rain, Wave, Wall |

---

### Examples
#### Run with default settings:

```sh
  zig-out/bin/zig-matrix
```

#### Run in debug mode:
```sh
  zig-out/bin/zig-matrix -d
```

#### Use a specific ASCII mode:
```sh
  zig-out/bin/zig-matrix -r Binary
```

#### Set custom rain color:
```sh
  zig-out/bin/zig-matrix -c NeonBlue
```

#### Set custom rain gradient:
```sh
  zig-out/bin/zig-matrix -g Circular
```

#### Use a specific rain mode:
```sh
  zig-out/bin/zig-matrix -m Wave
```

---

## Debug Mode

When enabled (-d), the program will print additional runtime information:
- Project name and version
- Memory usage (persistent & scratch)
- Execution parameters (speed, ASCII mode, rain color, rain gradient, matrix mode)
- Random seed and matrix dimensions

---

## Signal Handling

- Windows: Uses SetConsoleCtrlHandler for intercepting CTRL+C.
- Unix/Linux: Captures SIGINT (Ctrl+C).
- Both ensure:
  - Cleaning the console
  - Showing the cursor again
  - Graceful shutdown

---
