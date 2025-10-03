# Zig Matrix

A terminal-based matrix digital rain effect implemented in Zig ⚡.
It provides configurable ASCII rain with support for colors, modes, and debugging options.

---

## Features

- Configurable rain effect with adjustable:
  - Drop length
  - Rain color
  - ASCII mode
  - Matrix mode
  - Frame delay
- Debug mode for displaying internal states such as memory usage and seed.
- Cross-platform signal handling for clean exit (Windows / Unix).
- Custom allocator tracing for monitoring memory usage.

---

## Build & Run

### Requirements
- Zig compiler (Tested on 0.16.0-dev.393+dd4be26f5)

### Build
zig build

### Run
zig-out/bin/zig-matrix [options]

---

## Command Line Options

Usage: zig-matrix   [options]
  -h, --help        Show this help message
  -v, --version     Show project's version
  -d                Enable debug mode (default: off)
  -s  <number>      Random seed (default: current timestamp in ms)
  -ms <number>      Frame delay in ms (default: 50)
  -l <number>       Drop length (default: 10)
  -c  <color>       Rain color (default: Green)
                      (use "help" to list available colors)
  -r  <mode>        ASCII mode (default: Default)
                      (use "help" to list available modes)
  -m  <mode>        Matrix mode (default: Rain)
                      (use "help" to list available modes)

### Examples
#### Run with default settings:

```zig
  zig-out/bin/zig-matrix
```

#### Run in debug mode:
```zig
  zig-out/bin/zig-matrix -d
```

#### Set custom rain color:
```zig
  zig-out/bin/zig-matrix -c NeonBlue
```

#### Use a specific ASCII mode:
```zig
  zig-out/bin/zig-matrix -r Binary
```

---

## Debug Mode

When enabled (-d), the program will print additional runtime information:
- Project name and version
- Memory usage (persistent & scratch)
- Execution parameters (speed, ASCII mode, rain color, matrix mode)
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

## License

MIT License (add your actual license if different).
