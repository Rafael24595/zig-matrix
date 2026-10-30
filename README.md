# Zig Matrix

A configurable, terminal-based Matrix-style digital rain effect written in Zig. ⚡

Customize the rain with different symbol sets, colors, gradients, movement modes, and rendering orientations.

> **Terminal compatibility:** The project has been tested with Windows Terminal 1.23.13503.0. Rendering performance and character display may vary across terminal emulators. If RGB rendering is slow, try `ansi` mode; use `none` mode when color output is unnecessary. Keyboard input and character rendering may vary across terminal emulators.

## Features

- **Configurable rain:** Adjust drop length, frame delay, and random seed.
- **Color customization:** Choose from a variety of colors and gradient modes.
- **Symbol themes:** Select from character sets including binary, digits, Latin, Greek, Cyrillic, runes, and more.
- **Rendering modes:** Choose between `rain`, `wave`, and `wall`.
- **Flexible orientation:** Render vertically or horizontally.
- **Matrix flux:** Toggle the rendering flow direction between normal and reverse.
- **Multiple color modes:** Use RGB, ANSI, or no color.
- **Dynamic terminal sizing:** Adapt the matrix to terminal dimensions and handle window resizing.
- **Rain control:** Toggle the rain animation on and off, allowing active drops to finish their current cycles before stopping.
- **Debug mode:** Inspect runtime parameters, matrix dimensions, and memory usage.
- **Console cleanup:** Handle Ctrl+C and restore the terminal state during normal shutdown.

## Requirements

- Zig compiler 0.15.1 (tested version)
- A terminal emulator with ANSI escape-sequence support

## Build

Build the project using Zig:

```sh
zig build
```

For an optimized release build, use `ReleaseFast`:

```sh
zig build -Doptimize=ReleaseFast
```

The optimized build prioritizes runtime performance over debug-friendly behavior.

## Run

Launch the executable:

```sh
zig-out/bin/zig-matrix
```

Display the available command-line options:

```sh
zig-out/bin/zig-matrix --help
```

## Command-Line Options

| Option | Description | Default |
|---|---|---|
| `-h`, `--help` | Display the help message | — |
| `-v`, `--version` | Display the project version | — |
| `-d` | Enable debug output | Disabled |
| `-s` | Set the random seed | Current timestamp in milliseconds |
| `-ms` | Set the frame delay in milliseconds |  `55` ms on Windows; `65` ms on other platforms |
| `-l` | Set the drop length | `0.4 × matrix height` |
| `-tc` | Set the theme color | `green` |
| `-tg` | Set the theme gradient | `default` |
| `-ts` | Set the symbol theme | `default` |
| `-mm` | Set the matrix rendering mode | `rain` |
| `-cm` | Set the color mode | `rgb` |
| `-o` | Set the matrix orientation | `vertical` |
| `-f` | Set the matrix flux direction | `normal` |

### Available values

**Color (`-tc`)**

`white`, `black`, `red`, `green`, `green_dark`, `green_medium`, `green_bright`, `green_olive`, `green_moss`, `blue`, `yellow`, `cyan`, `magenta`, `orange`, `purple`, `deep_purple`, `hot_purple`, `gray`, `gray_dark`, `gray_light`, `pink`, `brown`, `aqua`, `navy`, `teal`, `lavender`, `pale_lavender`, `violet`, `lime`, `coral`, `gold`, `neon_pink`, `neon_green`, `neon_blue`, `neon_yellow`, `neon_orange`, `neon_purple`, `neon_cyan`, `neon_red`

**Gradient (`-tg`)**

`default`, `linear`, `circular`

**Symbol theme (`-ts`)**

`default`, `binary`, `latin`, `latin_upper`, `latin_lower`, `digits`, `symbols`, `hex`, `base64`, `blocks`, `extended`, `katana`, `fade`, `matrix`, `code`, `sci_fi`, `runes`, `math`, `arcane`, `telemetry`, `cyrillic`, `cyrillic_upper`, `cyrillic_lower`, `greek`, `greek_upper`, `greek_lower`, `arabic`, `devanagari`, `matrix_soup`

**Matrix mode (`-mm`)**

`rain`, `wave`, `wall`

**Color mode (`-cm`)**

`rgb`, `ansi`, `unfo`

**Orientation (`-o`)**

`vertical`, `horizontal`

**Matrix flux (`-f`)**

`normal`, `reverse`

## Examples

Run with the default configuration:

```sh
zig-out/bin/zig-matrix
```

Enable debug output:

```sh
zig-out/bin/zig-matrix -d
```

Use binary symbols:

```sh
zig-out/bin/zig-matrix -ts binary
```

Change the rain color:

```sh
zig-out/bin/zig-matrix -tc neon_blue
```

Apply a circular gradient:

```sh
zig-out/bin/zig-matrix -tg circular
```

Use wave mode:

```sh
zig-out/bin/zig-matrix -mm wave
```

Render horizontally:

```sh
zig-out/bin/zig-matrix -o horizontal
```

Disable color output:

```sh
zig-out/bin/zig-matrix -cm none
```

Combine multiple options:

```sh
zig-out/bin/zig-matrix -tc neon_green -tg circular -ts binary -mm wave -o horizontal
```

## Terminal Recommendations

A black terminal background is recommended for the intended Matrix-style appearance and good contrast.

RGB rendering may perform differently depending on the terminal emulator. If performance is an issue, try ANSI color mode or disable colors entirely.

## Debug Mode

Enable debug output with `-d` to inspect runtime information, including:

- Project name and version
- Persistent and scratch memory usage
- Frames per second (FPS)
- Frame delay in milliseconds
- Random seed
- Symbol theme and color configuration
- Gradient, matrix rendering mode, and flux direction
- Matrix orientation and dimensions

## Interactive Controls

The simulation accepts keyboard input while running.

| Key | Action |
|---|---|
| `p`, `Space` | Toggle pause and resume. The current frame remains visible while paused. |
| `s` | Toggle rain on and off. Active drops finish their current animation cycle before stopping. |
| `f` | Toggle the matrix flux direction between normal and reverse. |
| `+` | Increase the frame delay by 10 ms, up to 3000 ms. |
| `-` | Decrease the frame delay by 10 ms, down to 0 ms. |
| `q`, `Ctrl+C` | Request a clean exit. |

Input is processed on a separate thread, allowing the render loop to continue while waiting for key presses. Runtime flags use atomic operations to coordinate input and rendering.

The rain toggle provides a graceful way to stop and resume the animation. When disabled, each active column finishes its current animation cycle before stopping. When enabled again, the rain resumes. Unlike pausing, which freezes the current frame immediately, toggling the rain off allows pending animation cycles to complete.

The flux toggle inverts the rendering direction of the matrix in real-time, switching instantly between normal and reverse flows without restarting the application.

## Shutdown and Signal Handling

The application installs a signal handler and requests shutdown when an interrupt is received. During normal shutdown, deferred cleanup routines attempt to restore raw input mode and disable ANSI input, restore cursor visibility, and clear terminal output.

A custom panic handler also attempts to restore terminal settings before delegating to Zig's default panic handler. Recovery is best-effort and may not prevent terminal state from being left partially modified, especially if a panic occurs on another thread while rendering is in progress.

Exact behavior may depend on the operating system, terminal emulator, and how the process terminates.