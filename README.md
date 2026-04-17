# shaderz

A local GLSL shader sandbox for developing [recurBOY](https://github.com/cyberboy666/recurBOY) shaders.

Serves a WebGL preview in the browser with hot reload on file save. No in-browser editor — write shaders in your editor of choice and see them update live.

## Usage

```
make run
```

Then open [http://localhost:3000](http://localhost:3000).

## Interface

- **Sidebar** — click any `.glsl` file to load it
- **Sliders** — control `u_x0`–`u_x3` in real time
- **Status bar** — shows compile errors; previous shader keeps running on error
- **Hot reload** — any file saved in `shaders/` reloads automatically

## Shader uniforms

All shaders receive the standard recurBOY uniform interface:

| Uniform | Type | Description |
|---|---|---|
| `u_time` | `float` | elapsed seconds |
| `u_resolution` | `vec2` | canvas dimensions |
| `u_x0`–`u_x3` | `float` | user params, 0.0–1.0 |

Output via `gl_FragColor`. Required preamble is injected automatically:

```glsl
#ifdef GL_ES
  precision mediump float;
#endif
```

## Shader directories

Shaders are organized into two directories:

### `shaders/sandbox/` — full-featured shaders for desktop WebGL

| File | Description |
|---|---|
| `horiz_ballblazer.glsl` | Ballblazer-style arena — checkered floor, random objects, 4 color palettes |
| `horiz_ballblazer_bit.glsl` | Ballblazer with 1-bit Bayer dithering and ink/paper color pairs |
| `horiz_ballblazer_wet.glsl` | Ballblazer with animated water surface and Fresnel reflections |
| `horiz_phantasy.glsl` | Phantasy Star–style dungeon raycaster with brick-textured walls/floor/ceiling |
| `horiz_phantasy_bit.glsl` | Phantasy dungeon with 1-bit Bayer dithering and ink/paper color pairs |
| `horiz_fortress.glsl` | LZX Fortress clone — 3-bit digital pattern generator with 8 logic combinator modes and 16 color palettes |
| `vert_*` | Rotated 90° versions of the above |

### `shaders/recurboy/` — simplified shaders for recurBOY (Pi GPU)

| File | Description |
|---|---|
| `horiz_ballblazer_lite.glsl` | Checkered floor, sky, 4 spheres, camera sway |
| `horiz_ballblazer_bit_lite.glsl` | Ballblazer lite with 1-bit dithering |
| `horiz_phantasy_lite.glsl` | Dungeon raycaster with fake navigation |
| `horiz_phantasy_bit_lite.glsl` | Phantasy lite with 1-bit dithering |
| `horiz_fortress_lite.glsl` | LZX Fortress clone — 6 logic modes, 8 color palettes, FM + cross-modulation |
| `vert_*` | Rotated 90° versions of the above |

## Adding shaders

Drop any `.glsl` file into either `shaders/sandbox/` or `shaders/recurboy/`. It will appear in the sidebar immediately (no restart needed).

## Deploying to recurBOY

The recurBOY uses a different uniform interface (`tres`, `fparams`, `ftime`/`itime`) and expects `.frag` files. The build step processes only `shaders/recurboy/*.glsl`: it prepends `recurboy_header.glsl` (which aliases recurBOY uniforms to our names via `#define`), strips our uniform declarations, and renames `.glsl` to `.frag`.

```
make build
```

To build and deploy to a recurBOY connected via USB:

```
make deploy
```

This wipes the Pi's `PATTERN/` directory, scps all built `.frag` files, and runs `sync` to flush writes to the SD card (important — the Pi loses power on unplug, so unsynced files will be lost). Edit the Makefile if your host or path differs.

To avoid entering the Pi's password on every deploy, copy your SSH key:

```
ssh-copy-id pi@raspberrypi.local
```

**Note:** The recurBOY's GLSL ES compiler does not support `bool`, `inout`, or `break`. The `_lite` shader variants are simplified for the Pi's GPU (shorter loops, no unsupported features).
