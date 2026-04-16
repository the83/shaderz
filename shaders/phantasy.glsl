// gen-shader
// Phantasy Star style dungeon — grid-locked raycaster with branching maze
//
// Maze structure:
//   even,even cells  = junctions (always open)
//   odd,odd cells    = corner posts (always wall)
//   one-odd cells    = passages (35% wall, 65% open)
//
// Navigation tracks cameFromDir to avoid backtracking.
// Dead ends trigger a 180° turn; the camera then moves away.
//
// u_x0: movement speed
// u_x1: turn tendency at open intersections (0 = go straight, 1 = turn often)
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
    if (ex > 0.5 && ey > 0.5) return true;   // corner post — always wall
    if (ex < 0.5 && ey < 0.5) return false;  // junction   — always open
    return h1v(c) > 0.65;                     // passage: 35% wall, 65% open
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
    float moveSpeed = 1.0 + u_x0 * 3.0;    // cells/sec
    float stepDur   = 2.0 / moveSpeed;      // each step = 2 cells (junction→junction)

    // Loop every 300 steps so the shader never freezes
    float loopSteps = mod(tm / stepDur, 300.0);
    int   numSteps  = int(loopSteps);
    float frac      = fract(loopSteps);

    // Starting junction — must be even,even
    vec2 startCell = vec2(20.0, 20.0);

    // Find an initial open direction
    vec2 initDir = vec2(1.0, 0.0);
    for (int k = 0; k < 4; k++) {
        if (!isWall(startCell + initDir)) break;
        initDir = vec2(-initDir.y, initDir.x);
    }

    vec2 pos         = startCell;
    vec2 dir         = initDir;
    vec2 cameFromDir = vec2(0.0);   // no came-from constraint at start
    vec2 prevPos     = pos;
    vec2 prevDir     = dir;
    bool wasMove     = false;

    for (int i = 0; i < 300; i++) {
        if (i >= numSteps) break;

        prevPos = pos;
        prevDir = dir;

        vec2 rightDir = vec2( dir.y, -dir.x);
        vec2 leftDir  = vec2(-dir.y,  dir.x);

        // Exclude the direction we arrived from (dot > 0.5 = same hemisphere)
        bool canFwd   = !isWall(pos + dir)      && dot(dir,      cameFromDir) < 0.5;
        bool canRight = !isWall(pos + rightDir) && dot(rightDir, cameFromDir) < 0.5;
        bool canLeft  = !isWall(pos + leftDir)  && dot(leftDir,  cameFromDir) < 0.5;

        // Per-junction stable hash for preferred turn side
        float jh    = h1v(pos * 0.5);
        bool  prefR = jh > 0.5;

        // Per-step random for voluntary turns
        float rnd = h1f(float(i)*11.3 + 7.7);

        vec2 newDir;
        bool moved;

        if (!canFwd && !canRight && !canLeft) {
            // Dead end (or all exits back): 180° turn in place.
            // Mark dead-end side as cameFrom so next step goes back freely.
            cameFromDir = dir;
            newDir = -dir;
            moved  = false;

        } else if (!canFwd) {
            // Wall ahead: forced turn
            if      (canRight && canLeft) newDir = prefR ? rightDir : leftDir;
            else if (canRight)            newDir = rightDir;
            else                          newDir = leftDir;
            moved = false;  // animate turn

        } else if ((canRight || canLeft) && rnd < u_x1 * 0.7) {
            // Voluntary turn at open intersection
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
            cameFromDir = -dir;   // arrived from the opposite side
        }
        wasMove = moved;
    }

    // Smooth animation
    float ef = smoothstep(0.0, 1.0, frac);
    vec2 camPos, camDir;
    if (wasMove) {
        // Glide from previous junction to current junction
        camPos = mix(prevPos + 0.5, pos + 0.5, ef);
        camDir = dir;
    } else {
        // Rotate in place
        camPos = pos + vec2(0.5);
        float a0 = atan(prevDir.y, prevDir.x);
        float a1 = atan(dir.y,     dir.x);
        float da = a1 - a0;
        if (da >  3.14159) da -= 6.28318;
        if (da < -3.14159) da += 6.28318;
        camDir = vec2(cos(a0 + da*ef), sin(a0 + da*ef));
    }

    // Ray for this pixel column (~67° FOV)
    vec2 camRight = vec2(-camDir.y, camDir.x);
    vec2 rayDir   = normalize(camDir + camRight*(uv.x*2.0-1.0)*0.66);

    float side, wallX;
    vec2  hitCell;
    float dist = castRay(camPos, rayDir, side, hitCell, wallX);

    float wallHalf = 0.5 / dist;
    float sy       = uv.y - 0.5;

    // --- Palette ---
    float pf = fract(u_x2)*4.0, pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));
    vec3 wh0=vec3(0.22,0.38,0.85), wh1=vec3(0.85,0.30,0.10),
         wh2=vec3(0.10,0.65,0.25), wh3=vec3(0.68,0.15,0.85);
    vec3 cf0=vec3(0.02,0.02,0.08), cf1=vec3(0.08,0.02,0.01),
         cf2=vec3(0.01,0.05,0.02), cf3=vec3(0.05,0.01,0.08);
    #define PLERP(a0,a1,a2,a3) (pi<0.5?mix(a0,a1,pt):pi<1.5?mix(a1,a2,pt):pi<2.5?mix(a2,a3,pt):mix(a3,a0,pt))
    vec3 wallHue = PLERP(wh0,wh1,wh2,wh3);
    vec3 cfCol   = PLERP(cf0,cf1,cf2,cf3);

    // --- Shading ---
    vec3 color;
    if (abs(sy) < wallHalf) {
        // 5-band discrete depth shading
        float shade;
        if      (dist < 1.5)  shade = 1.00;
        else if (dist < 3.0)  shade = 0.60;
        else if (dist < 6.0)  shade = 0.34;
        else if (dist < 12.0) shade = 0.16;
        else                  shade = 0.07;
        if (side == 0.0) shade *= 0.72;   // E/W faces darker

        float wy     = sy / wallHalf;
        float panelU = fract(wallX*2.0)*2.0 - 1.0;
        float border = max(smoothstep(0.72,0.95,abs(panelU)),
                          smoothstep(0.72,0.95,abs(wy)));
        float mortar = step(0.46, fract(wy*4.0 + floor(wallX*2.0)*0.5));

        vec3 wc = wallHue * shade;
        wc = mix(wc, wc*0.28, border);
        wc *= 1.0 - mortar*0.18*shade;
        color = mix(wc, cfCol*0.5, clamp(dist/16.0, 0.0, 1.0));

    } else if (sy > 0.0) {
        float t = (sy - wallHalf) / max(0.5 - wallHalf, 0.001);
        color = cfCol * mix(0.50, 0.06, t);
    } else {
        float t = (-sy - wallHalf) / max(0.5 - wallHalf, 0.001);
        color = cfCol * mix(0.70, 0.10, t) * 0.60;
    }

    gl_FragColor = vec4(color, 1.0);
}
