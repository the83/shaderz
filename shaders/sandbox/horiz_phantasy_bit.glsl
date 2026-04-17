// Phantasy Star dungeon — 1-bit dithered variant
//
// Same maze raycaster as phantasy.glsl but rendered with
// 4x4 Bayer ordered dithering and ink/paper color pairs.
//
// u_x0: movement speed
// u_x1: brick size (0 = small bricks, 1 = large bricks)
// u_x2: ink/paper color theme
// u_x3: overall speed

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

float h1v(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float h1f(float n) { return fract(sin(n) * 43758.5453); }

bool isWall(vec2 cell) {
    vec2  c  = floor(cell);
    float ex = mod(c.x, 2.0);
    float ey = mod(c.y, 2.0);
    if (ex > 0.5 && ey > 0.5) return true;   // corner post
    if (ex < 0.5 && ey < 0.5) return false;  // junction
    return h1v(c) > 0.45;                     // passage: 45% open, 55% wall
}

float castRay(vec2 pos, vec2 dir,
              out float side, out vec2 hitCell, out float wallX) {
    vec2 mapPos    = floor(pos);
    vec2 deltaDist = abs(1.0 / dir);
    vec2 stepDir   = sign(dir);
    vec2 sideDist;
    sideDist.x = dir.x < 0.0 ? (pos.x - mapPos.x)*deltaDist.x
                              : (mapPos.x + 1.0 - pos.x)*deltaDist.x;
    sideDist.y = dir.y < 0.0 ? (pos.y - mapPos.y)*deltaDist.y
                              : (mapPos.y + 1.0 - pos.y)*deltaDist.y;
    side = 0.0; hitCell = mapPos;
    for (int i = 0; i < 64; i++) {
        if (sideDist.x < sideDist.y) { sideDist.x += deltaDist.x; mapPos.x += stepDir.x; side = 0.0; }
        else                          { sideDist.y += deltaDist.y; mapPos.y += stepDir.y; side = 1.0; }
        if (isWall(mapPos)) { hitCell = mapPos; break; }
    }
    float perp;
    if (side == 0.0) { perp = (mapPos.x - pos.x + (1.0-stepDir.x)*0.5)/dir.x; wallX = fract(pos.y + perp*dir.y); }
    else             { perp = (mapPos.y - pos.y + (1.0-stepDir.y)*0.5)/dir.y; wallX = fract(pos.x + perp*dir.x); }
    return max(perp, 0.01);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float speed     = u_x3 * 2.0;
    float tm        = u_time * speed;
    float moveSpeed = 1.0 + u_x0 * 3.0;
    float stepDur   = 2.0 / moveSpeed;

    float loopSteps = mod(tm / stepDur, 300.0);
    int   numSteps  = int(loopSteps);
    float frac      = fract(loopSteps);

    // Scan for a starting junction with >= 2 open exits
    vec2 startCell = vec2(4.0, 4.0);
    for (int si = 0; si < 50; si++) {
        vec2 sc = vec2(float(si / 5 * 2), float(si - si / 5 * 5) * 2.0);
        int cnt = 0;
        if (!isWall(sc + vec2( 1.0, 0.0))) cnt++;
        if (!isWall(sc + vec2(-1.0, 0.0))) cnt++;
        if (!isWall(sc + vec2( 0.0, 1.0))) cnt++;
        if (!isWall(sc + vec2( 0.0,-1.0))) cnt++;
        if (cnt >= 3) { startCell = sc; break; }
    }

    // Find an initial open direction
    vec2 initDir = vec2(1.0, 0.0);
    for (int k = 0; k < 4; k++) {
        if (!isWall(startCell + initDir)) break;
        initDir = vec2(-initDir.y, initDir.x);
    }

    vec2 pos         = startCell;
    vec2 dir         = initDir;
    vec2 cameFromDir = -initDir;  // pretend we arrived from behind
    vec2 prevPos     = pos;
    vec2 prevDir     = dir;
    bool wasMove     = true;
    bool justMoved   = true;      // prevents consecutive voluntary turns

    for (int i = 0; i < 300; i++) {
        if (i >= numSteps) break;

        prevPos = pos;
        prevDir = dir;

        vec2 rightDir = vec2( dir.y, -dir.x);
        vec2 leftDir  = vec2(-dir.y,  dir.x);

        // Exclude direction we arrived from
        bool canFwd   = !isWall(pos + dir)      && dot(dir,      cameFromDir) < 0.5;
        bool canRight = !isWall(pos + rightDir) && dot(rightDir, cameFromDir) < 0.5;
        bool canLeft  = !isWall(pos + leftDir)  && dot(leftDir,  cameFromDir) < 0.5;

        float jh    = h1v(pos * 0.5);
        bool  prefR = jh > 0.5;
        float rnd   = h1f(float(i) * 11.3 + 7.7);

        vec2 newDir;
        bool moved;

        if (!canFwd && !canRight && !canLeft) {
            // Dead end: 180° turn, mark dead-end side so next step escapes
            cameFromDir = dir;
            newDir = -dir;
            moved  = false;

        } else if (!canFwd) {
            // Blocked ahead: forced turn
            if      (canRight && canLeft) newDir = prefR ? rightDir : leftDir;
            else if (canRight)            newDir = rightDir;
            else                          newDir = leftDir;
            moved = false;

        } else if (justMoved && (canRight || canLeft) && rnd < 0.3) {
            // Voluntary turn — only if we just moved (prevents spinning)
            if      (canRight && canLeft) newDir = prefR ? rightDir : leftDir;
            else if (canRight)            newDir = rightDir;
            else                          newDir = leftDir;
            moved = false;

        } else {
            // Go straight
            newDir = dir;
            moved  = true;
        }

        dir = newDir;
        if (moved) {
            pos        += dir * 2.0;
            cameFromDir = -dir;
        }
        justMoved = moved;
        wasMove   = moved;
    }

    // Smooth animation
    float ef = smoothstep(0.0, 1.0, frac);
    vec2 camPos, camDir;
    if (wasMove) {
        camPos = mix(prevPos + 0.5, pos + 0.5, ef);
        // Interpolate direction (handles turn-and-move smoothly)
        float a0 = atan(prevDir.y, prevDir.x);
        float a1 = atan(dir.y,     dir.x);
        float da = a1 - a0;
        if (da >  3.14159) da -= 6.28318;
        if (da < -3.14159) da += 6.28318;
        camDir = vec2(cos(a0 + da * ef), sin(a0 + da * ef));
    } else {
        camPos = pos + vec2(0.5);
        float a0 = atan(prevDir.y, prevDir.x);
        float a1 = atan(dir.y,     dir.x);
        float da = a1 - a0;
        if (da >  3.14159) da -= 6.28318;
        if (da < -3.14159) da += 6.28318;
        camDir = vec2(cos(a0 + da * ef), sin(a0 + da * ef));
    }

    // Ray for this pixel column (~67° FOV)
    vec2 camRight = vec2(-camDir.y, camDir.x);
    vec2 rayDir   = normalize(camDir + camRight * (uv.x * 2.0 - 1.0) * 0.66);

    float side, wallX;
    vec2  hitCell;
    float dist = castRay(camPos, rayDir, side, hitCell, wallX);

    float wallHalf = 0.5 / dist;
    float sy       = uv.y - 0.5;

    // --- Brick pattern helper ---
    #define BRICK_MORTAR(bx, by) max( \
        smoothstep(0.42, 0.48, abs(fract(bx) - 0.5)), \
        smoothstep(0.40, 0.48, abs(fract(by) - 0.5))  \
    )

    // --- Brick scale ---
    float brickRows = mix(16.0, 4.0, u_x1);
    float brickCols = mix(10.0, 3.0, u_x1);
    float floorScale = mix(6.0, 1.5, u_x1);

    // --- Scene luminance ---
    float luma;

    if (abs(sy) < wallHalf) {
        // WALL
        float shade = 1.0 / (1.0 + dist * 0.35);
        if (side == 0.0) shade *= 0.78;

        float wy = sy / wallHalf;
        float by = (wy * 0.5 + 0.5) * brickRows;
        float bRow = floor(by);
        float bx = wallX * brickCols + mod(bRow, 2.0) * 0.5;

        float mortar = BRICK_MORTAR(bx, by);
        luma = shade * (1.0 - mortar * 0.85);
        luma = mix(luma, 0.0, clamp(dist / 18.0, 0.0, 1.0));

    } else {
        // FLOOR / CEILING
        float floorPerp = 0.5 / abs(sy);
        float cosA = dot(rayDir, camDir);
        float floorTrue = floorPerp / max(cosA, 0.01);
        vec2 fp = camPos + rayDir * floorTrue;

        float shade = 1.0 / (1.0 + floorPerp * 0.35);
        if (sy < 0.0) shade *= 0.65;

        float by = fp.y * floorScale;
        float bRow = floor(by);
        float bx = fp.x * floorScale + mod(bRow, 2.0) * 0.5;

        float mortar = BRICK_MORTAR(bx, by);
        luma = shade * (1.0 - mortar * 0.85);
        luma = mix(luma, 0.0, clamp(floorPerp / 18.0, 0.0, 1.0));
    }

    // --- 4×4 Bayer ordered dither ---
    vec2 p = mod(floor(gl_FragCoord.xy), 4.0);
    vec4 r0 = vec4( 0.0, 8.0, 2.0,10.0) / 16.0;
    vec4 r1 = vec4(12.0, 4.0,14.0, 6.0) / 16.0;
    vec4 r2 = vec4( 3.0,11.0, 1.0, 9.0) / 16.0;
    vec4 r3 = vec4(15.0, 7.0,13.0, 5.0) / 16.0;
    vec4 row = p.y<1.0 ? r0 : p.y<2.0 ? r1 : p.y<3.0 ? r2 : r3;
    float threshold = p.x<1.0 ? row.x : p.x<2.0 ? row.y : p.x<3.0 ? row.z : row.w;

    float bit = step(threshold, luma);

    // --- Ink/paper color pairs (u_x2 cycles 4 themes) ---
    float pf = fract(u_x2) * 4.0, pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));
    vec3 ink0=vec3(0.0), ink1=vec3(0.0), ink2=vec3(0.0), ink3=vec3(0.05,0.05,0.18);
    vec3 pap0=vec3(1.0), pap1=vec3(0.15,0.95,0.25), pap2=vec3(1.0,0.72,0.0), pap3=vec3(0.55,0.75,1.0);
    #define PLERP(a0,a1,a2,a3) (pi<0.5?mix(a0,a1,pt):pi<1.5?mix(a1,a2,pt):pi<2.5?mix(a2,a3,pt):mix(a3,a0,pt))
    vec3 ink   = PLERP(ink0,ink1,ink2,ink3);
    vec3 paper = PLERP(pap0,pap1,pap2,pap3);

    // CRT scanlines
    vec3 out_color = mix(ink, paper, bit);
    out_color *= mod(gl_FragCoord.y, 2.0) < 1.0 ? 0.82 : 1.0;

    gl_FragColor = vec4(out_color, 1.0);
}
