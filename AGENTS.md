# AGENTS.md

## Project overview

GLSL shader sandbox for developing shaders for the [recurBOY](https://github.com/cyberboy666/recurBOY) video synth (Raspberry Pi eurorack module). Includes a local WebGL preview with hot reload and a build/deploy pipeline for the recurBOY hardware.

## Architecture

- `server.js` — Node.js HTTP server with SSE file watching for hot reload
- `index.html` — WebGL canvas, shader selector sidebar (grouped by directory), param sliders
- `shaders/sandbox/` — full-featured shaders for desktop WebGL preview
- `shaders/recurboy/` — simplified `_lite` shaders that run on recurBOY's Pi GPU
- `recurboy_header.glsl` — prepended during build; maps recurBOY uniforms to our names via `#define`
- `build/` — generated `.frag` files for deployment (gitignored)

## Shader conventions

All shaders use the same uniform interface:

```glsl
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0, u_x1, u_x2, u_x3;  // params 0.0-1.0
```

- `u_x3` is the **speed/animation knob** — always assign speed to this param
- In the sandbox, `u_x3` is bipolar (-1.0 to 1.0); on the recurBOY hardware, `fparams` is **0.0 to 1.0**
- For `_lite` shaders, always add a base offset to speed so animation runs even when the knob is at minimum (e.g. `float speed = 0.3 + u_x3 * 1.5;` not `float speed = u_x3 * 1.5;`)

- `horiz_` prefix: standard landscape orientation
- `vert_` prefix: rotated 90 degrees (UV swapped, aspect inverted, scanlines on x instead of y)
- `_bit` suffix: 1-bit Bayer dithered variant with ink/paper color pairs
- `_wet` suffix: water surface variant (sandbox only, too heavy for Pi)
- `_lite` suffix: recurBOY-compatible (lives in `shaders/recurboy/`)

## recurBOY Pi GPU constraints

The VideoCore IV GPU is extremely limited. The `_lite` shaders must follow these rules:

- **No `bool` type** — use `float` with 0.0/1.0 and comparisons like `> 0.5`
- **No `break` statements** — use guard flags (`if (hit < 0.5) { ... }`)
- **No `inout` parameters** — use global variables instead
- **No division by zero** — clamp ray directions: `abs(x) < 0.001 ? 0.001 : x`
- **No per-pixel navigation loops** — even 10 iterations with `isWall()` freezes the GPU. Use fake camera paths (hash-based, no wall checking)
- **Max 4 `checkCell` calls** for object intersection (6 causes black screen)
- **No boxes or pyramids** — only sphere intersection is cheap enough
- **No sphere animation** — even one extra `sin()` per sphere is too much
- **`mediump float` precision** — wrap large coordinates with `mod()` to stay small
- **Y-axis is inverted** — use `u_resolution.y - gl_FragCoord.y`
- **Params at 0 cause blank screens** — use `mix(0.05, 0.95, param)` or ensure defaults are visible
- **Files must be synced** — `ssh pi 'sync'` after `scp` or files are lost on power cycle
- **Overwriting existing files may fail silently** — use new filenames when iterating

## Build and deploy

```sh
make build    # builds shaders/recurboy/*.glsl -> build/*.frag
make deploy   # wipes Pi PATTERN/, uploads .frag files, runs sync
```

The build step prepends `recurboy_header.glsl` and strips `uniform float u_*` / `uniform vec2 u_*` declarations from our source files. The header uses `#define` macros (not global variables) to alias recurBOY's `tres`/`fparams`/`ftime`/`itime` to our uniform names.

## Testing on recurBOY

When iterating on a shader for the Pi:
1. Always use a **new filename** for each iteration — the Pi caches files and may not pick up overwrites
2. Prefix test shaders with `a_` so they sort to the top of the recurBOY's menu
3. Build test shaders directly into `build/` using `cat recurboy_header.glsl > build/name.frag` followed by the shader code
4. Always run `ssh pi@raspberrypi.local 'sync'` after uploading
5. Power cycle the recurBOY between tests
