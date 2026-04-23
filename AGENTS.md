# AGENTS.md

## Project overview

GLSL shader sandbox for developing shaders for the [recurBOY](https://github.com/cyberboy666/recurBOY) video synth (Raspberry Pi eurorack module). Includes a local WebGL preview with hot reload and a build/deploy pipeline for the recurBOY hardware.

## Architecture

- `server.js` — Node.js HTTP server with SSE file watching for hot reload
- `index.html` — WebGL canvas, shader selector sidebar (grouped by directory), param sliders
- `shaders/sandbox/` — full-featured shaders for desktop WebGL preview
- `shaders/recurboy/` — simplified shaders that run on recurBOY's Pi GPU
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
- For recurBOY shaders, always add a base offset to speed so animation runs even when the knob is at minimum (e.g. `float speed = 0.3 + u_x3 * 1.5;` not `float speed = u_x3 * 1.5;`)

- `horiz_` prefix: standard landscape orientation
- `vert_` prefix: rotated 90 degrees (UV swapped, aspect inverted, scanlines on x instead of y)
- `_bit` suffix: 1-bit Bayer dithered variant with ink/paper color pairs
- `_wet` suffix: water surface variant (sandbox only, too heavy for Pi)

## recurBOY Pi GPU constraints

The VideoCore IV GPU is extremely limited. Shaders in `shaders/recurboy/` must follow these rules:

- **No `bool` type** — use `float` with 0.0/1.0 and comparisons like `> 0.5`
- **No `break` statements** — use guard flags (`if (hit < 0.5) { ... }`)
- **No `inout` parameters** — use global variables instead
- **No `transpose()`** — GLSL ES 1.0 only; write manual helpers if needed
- **No division by zero** — clamp ray directions: `abs(x) < 0.001 ? 0.001 : x`
- **No cross-iteration state accumulation** — incremental rotation (mutating 4+ variables across loop iterations) causes black screen. Use direct cos/sin per iteration instead
- **No raymarching** — even 6 steps × 2 torus SDFs is too heavy. Avoid raymarched 3D entirely
- **Max ~12 loop iterations** — keep loop bodies simple (multiply-add, step, basic math). Trig calls inside loops are expensive; precompute outside when possible
- **Analytical per-pixel approaches work best** — spirograph pen (law-of-cosines), Lissajous (arcsin branches), and Sierpiński (iterated subdivision) all run well because they solve the curve equation per-pixel with minimal trig
- **`mediump float` precision** — wrap large coordinates with `mod()` to stay small. Values near 1.0 have precision ~0.001
- **Y-axis is inverted** — use `u_resolution.y - gl_FragCoord.y`
- **Files must be synced** — `ssh pi 'sync'` after `scp` or files are lost on power cycle

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
