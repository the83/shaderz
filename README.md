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

## Shaders

| File | Description |
|---|---|
| `horiz_ballblazer.glsl` | Ballblazer-style arena — checkered floor, random objects, 4 color palettes |
| `horiz_ballblazer_bit.glsl` | Ballblazer with 1-bit Bayer dithering and ink/paper color pairs |
| `horiz_ballblazer_wet.glsl` | Ballblazer with animated water surface and Fresnel reflections |
| `horiz_phantasy.glsl` | Phantasy Star–style dungeon raycaster with brick-textured walls/floor/ceiling |
| `horiz_phantasy_bit.glsl` | Phantasy dungeon with 1-bit Bayer dithering and ink/paper color pairs |
| `vert_ballblazer.glsl` | `horiz_ballblazer` rotated 90° |
| `vert_ballblazer_bit.glsl` | `horiz_ballblazer_bit` rotated 90° |
| `vert_ballblazer_wet.glsl` | `horiz_ballblazer_wet` rotated 90° |
| `vert_phantasy.glsl` | `horiz_phantasy` rotated 90° |
| `vert_phantasy_bit.glsl` | `horiz_phantasy_bit` rotated 90° |

## Adding shaders

Drop any `.glsl` file into `shaders/`. It will appear in the sidebar immediately (no restart needed).

## Deploying to recurBOY

The recurBOY expects `.frag` files in its `PATTERN` directory. The build step copies shaders from `shaders/` into `build/`, renaming `.glsl` to `.frag`:

```
make build
```

To build and deploy to a recurBOY connected via USB:

```
make deploy
```

This scps all `.frag` files to `pi@raspberrypi.local:PATTERN/` in a single transfer. Edit the Makefile if your host or path differs.
