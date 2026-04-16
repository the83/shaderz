// Phantasy Star style dungeon — grid-locked raycaster with branching maze
//
// Maze structure:
//   even,even cells  = junctions (always open)
//   odd,odd cells    = corner posts (always wall)
//   one-odd cells    = passages (45% open, 55% wall)
//
// Navigation tracks cameFromDir to avoid backtracking.
// justMoved flag prevents consecutive turns (no spinning).
//
// u_x0: movement speed
// u_x1: brick size (0 = small bricks, 1 = large bricks)
// u_x2: dungeon color theme
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
    vec2 rawUV = gl_FragCoord.xy / u_resolution;
    vec2 uv    = vec2(rawUV.y, 1.0 - rawUV.x);

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

    // --- Palette (monochromatic dungeon themes) ---
    float pf = fract(u_x2) * 4.0, pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));
    vec3 wh0=vec3(0.30,0.50,0.85), wh1=vec3(0.85,0.40,0.18),
         wh2=vec3(0.30,0.75,0.35), wh3=vec3(0.65,0.25,0.80);
    vec3 cf0=vec3(0.03,0.05,0.12), cf1=vec3(0.10,0.04,0.02),
         cf2=vec3(0.03,0.10,0.05), cf3=vec3(0.08,0.03,0.10);
    #define PLERP(a0,a1,a2,a3) (pi<0.5?mix(a0,a1,pt):pi<1.5?mix(a1,a2,pt):pi<2.5?mix(a2,a3,pt):mix(a3,a0,pt))
    vec3 wallHue = PLERP(wh0,wh1,wh2,wh3);
    vec3 cfCol   = PLERP(cf0,cf1,cf2,cf3);

    // --- Running bond brick pattern helper ---
    // Returns mortar intensity (0 = brick face, 1 = mortar line)
    // bx, by = brick-space coordinates; running bond offsets every other row
    #define BRICK_MORTAR(bx, by) max( \
        smoothstep(0.42, 0.48, abs(fract(bx) - 0.5)), \
        smoothstep(0.40, 0.48, abs(fract(by) - 0.5))  \
    )

    // --- Rendering ---
    // Brick scale: u_x1=0 → small bricks, u_x1=1 → large bricks
    float brickRows = mix(16.0, 4.0, u_x1);   // rows per wall face
    float brickCols = mix(10.0, 3.0, u_x1);  // columns per wall cell
    float floorScale = mix(6.0, 1.5, u_x1);  // bricks per world unit on floor/ceiling

    vec3 color;

    if (abs(sy) < wallHalf) {
        // ===== WALL =====
        float shade = 1.0 / (1.0 + dist * 0.35);
        if (side == 0.0) shade *= 0.78;

        float wy = sy / wallHalf;
        float by = (wy * 0.5 + 0.5) * brickRows;
        float bRow = floor(by);
        float bx = wallX * brickCols + mod(bRow, 2.0) * 0.5;

        float mortar = BRICK_MORTAR(bx, by);
        vec3 brickCol = wallHue * shade;
        color = mix(brickCol, brickCol * 0.15, mortar);
        color = mix(color, cfCol, clamp(dist / 18.0, 0.0, 1.0));

    } else {
        // ===== FLOOR / CEILING =====
        float floorPerp = 0.5 / abs(sy);
        float cosA = dot(rayDir, camDir);  // both unit vectors
        float floorTrue = floorPerp / max(cosA, 0.01);
        vec2 fp = camPos + rayDir * floorTrue;

        float shade = 1.0 / (1.0 + floorPerp * 0.35);
        if (sy < 0.0) shade *= 0.65;  // floor darker than ceiling

        // Same brick pattern, world-space
        float by = fp.y * floorScale;
        float bRow = floor(by);
        float bx = fp.x * floorScale + mod(bRow, 2.0) * 0.5;

        float mortar = BRICK_MORTAR(bx, by);
        vec3 brickCol = wallHue * shade;
        color = mix(brickCol, brickCol * 0.15, mortar);
        color = mix(color, cfCol, clamp(floorPerp / 18.0, 0.0, 1.0));
    }

    gl_FragColor = vec4(color, 1.0);
}
