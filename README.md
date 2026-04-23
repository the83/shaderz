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
| `horiz_cube.glsl` | Rotating 3D cube — per-axis rotation control, colored faces, analytical ray-box intersection |
| `horiz_cube_outline.glsl` | Rotating 3D cube — white faces, black outlines |
| `horiz_pixel_noise.glsl` | Filtered noise texture — H/V coherence control, density from starfield to snow |
| `horiz_color_noise.glsl` | Chromatic noise — independent RGB channels with color fringing and VHS-style interference |
| `horiz_palette_noise.glsl` | Palette noise — 3 layered noise channels with priority compositing, 16 palettes (RGB first) |
| `horiz_triangle_noise.glsl` | Triangle noise — rotated grid layers (0°/60°/-60°) with priority compositing, 16 palettes |
| `horiz_julia.glsl` | Julia set fractal — animated c-parameter orbit with 13 palettes, bipolar speed |
| `horiz_spirograph.glsl` | Spirograph — glowing hypotrochoid curves, additive distance field rendering |
| `horiz_spirograph_pen.glsl` | Spirograph pen — analytical pen-line hypotrochoid using law-of-cosines decomposition |
| `horiz_lissajous.glsl` | Lissajous figures — analytical arcsin-based rendering, a/b frequency control |
| `horiz_sierpinski.glsl` | Sierpiński triangle — iterated subdivision with tiled kaleidoscope mirroring |
| `horiz_sphere_spiral.glsl` | Spherical spiral — loxodrome on a rotating sphere, analytical θ≈a·φ check |
| `horiz_doyle.glsl` | Doyle spiral — circle packing via log-polar grid, no loop |

### `shaders/recurboy/` — simplified shaders for recurBOY (Pi GPU)

| File | Description |
|---|---|
| `horiz_ballblazer.glsl` | Checkered floor, sky, 4 spheres, camera sway |
| `horiz_ballblazer_bit.glsl` | Ballblazer with 1-bit dithering |
| `horiz_phantasy.glsl` | Dungeon raycaster with fake navigation |
| `horiz_cube.glsl` | Rotating 3D cube — per-axis rotation, analytical intersection, no loops |
| `horiz_cube_outline.glsl` | Rotating 3D cube — white faces, black outlines |
| `horiz_pixel_noise.glsl` | Filtered noise texture — H/V coherence control, density from starfield to snow |
| `horiz_color_noise.glsl` | Chromatic noise — independent RGB channels with color fringing |
| `horiz_palette_noise.glsl` | Palette noise — 3 layered noise channels with priority compositing, 8 palettes (RGB first) |
| `horiz_triangle_noise.glsl` | Triangle noise — rotated grid layers with priority compositing, 8 palettes |
| `horiz_julia.glsl` | Julia set fractal — 24-iteration escape-time with Lissajous c-orbit, 13 palettes |
| `horiz_spirograph.glsl` | Spirograph — glowing hypotrochoid via 12-point additive distance field |
| `horiz_spirograph_pen.glsl` | Spirograph pen — analytical pen-line rendering, no sample loop |
| `horiz_lissajous.glsl` | Lissajous figures — analytical arcsin-based rendering, 8-branch check |
| `horiz_sierpinski.glsl` | Sierpiński triangle — branchless subdivision, tiled kaleidoscope, no trig in loop |
| `horiz_sphere_spiral.glsl` | Spherical spiral — loxodrome on rotating sphere, front/back face rendering |
| `horiz_doyle.glsl` | Doyle spiral — log-polar circle packing, 4 unrolled cell checks, no loop |
| `horiz_brakhage.glsl` | Brakhage — layered paint swirls with randomized warp, palette refresh, no FBM |
| `vert_*` | Rotated 90° versions of the above (where applicable) |

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

**Note:** The recurBOY's GLSL ES compiler does not support `bool`, `inout`, or `break`. The `shaders/recurboy/` shaders are simplified for the Pi's GPU (shorter loops, no unsupported features).
