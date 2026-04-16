// Phantasy Star dungeon — lite 1-bit dithered version for recurBOY
// Fake navigation (no wall-aware pathfinding — too heavy for Pi GPU)
// Camera snakes through junction grid with hash-based turns
//
// u_x0: movement speed
// u_x1: brick size (0 = small, 1 = large)
// u_x2: ink/paper color theme
// u_x3: (unused)

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

float h1v(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }

float isWall(vec2 cell) {
    vec2 c = floor(cell);
    float ex = mod(c.x, 2.0);
    float ey = mod(c.y, 2.0);
    if (ex > 0.5 && ey > 0.5) return 1.0;
    if (ex < 0.5 && ey < 0.5) return 0.0;
    return step(0.45, h1v(c));
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float brickRows = mix(16.0, 4.0, u_x1);
    float brickCols = mix(10.0, 3.0, u_x1);
    float floorScale = mix(6.0, 1.5, u_x1);

    float speed = 0.5 + u_x0 * 2.0;
    float tm = u_time * speed;

    // Fake navigation: snake through junction grid
    float segment = floor(tm * 0.5);
    float segFrac = fract(tm * 0.5);
    float ef = smoothstep(0.0, 1.0, segFrac);

    float dirHash = fract(sin(segment * 73.137) * 43758.5453);
    float axis = mod(segment, 2.0);
    float dirSign = dirHash > 0.5 ? 1.0 : -1.0;

    // Accumulate position from previous segments
    vec2 pos = vec2(4.0, 4.0);
    for (int s = 0; s < 30; s++) {
        if (float(s) < segment) {
            float dh = fract(sin(float(s) * 73.137) * 43758.5453);
            float ds = dh > 0.5 ? 2.0 : -2.0;
            if (mod(float(s), 2.0) < 0.5) { pos.y += ds; }
            else { pos.x += ds; }
        }
    }

    // Current segment movement
    vec2 moveDir;
    if (axis < 0.5) { moveDir = vec2(0.0, dirSign); }
    else { moveDir = vec2(dirSign, 0.0); }
    vec2 camPos = pos + moveDir * 2.0 * ef + vec2(0.5);

    // Smooth camera rotation
    float prevSeg = segment - 1.0;
    float prevHash = fract(sin(prevSeg * 73.137) * 43758.5453);
    float prevAxis = mod(prevSeg, 2.0);
    float prevSign = prevHash > 0.5 ? 1.0 : -1.0;
    vec2 prevMoveDir;
    if (prevAxis < 0.5) { prevMoveDir = vec2(0.0, prevSign); }
    else { prevMoveDir = vec2(prevSign, 0.0); }

    float a0 = atan(prevMoveDir.y, prevMoveDir.x);
    float a1 = atan(moveDir.y, moveDir.x);
    float da = a1 - a0;
    if (da > 3.14159) da -= 6.28318;
    if (da < -3.14159) da += 6.28318;
    float turnEf = smoothstep(0.0, 0.3, segFrac);
    vec2 camDir = vec2(cos(a0 + da * turnEf), sin(a0 + da * turnEf));

    // DDA raycaster
    vec2 camRight = vec2(-camDir.y, camDir.x);
    vec2 rawDir = normalize(camDir + camRight * (uv.x * 2.0 - 1.0) * 0.66);
    vec2 rayDir = vec2(
        abs(rawDir.x) < 0.001 ? 0.001 : rawDir.x,
        abs(rawDir.y) < 0.001 ? 0.001 : rawDir.y
    );

    vec2 mapPos = floor(camPos);
    vec2 deltaDist = abs(1.0 / rayDir);
    vec2 stepDir = sign(rayDir);
    vec2 sideDist;
    sideDist.x = rayDir.x < 0.0 ? (camPos.x - mapPos.x) * deltaDist.x : (mapPos.x + 1.0 - camPos.x) * deltaDist.x;
    sideDist.y = rayDir.y < 0.0 ? (camPos.y - mapPos.y) * deltaDist.y : (mapPos.y + 1.0 - camPos.y) * deltaDist.y;
    float side = 0.0;
    float wallX = 0.0;
    float hit = 0.0;
    for (int i = 0; i < 12; i++) {
        if (hit < 0.5) {
            if (sideDist.x < sideDist.y) { sideDist.x += deltaDist.x; mapPos.x += stepDir.x; side = 0.0; }
            else { sideDist.y += deltaDist.y; mapPos.y += stepDir.y; side = 1.0; }
            if (isWall(mapPos) > 0.5) { hit = 1.0; }
        }
    }

    float perp;
    if (side < 0.5) { perp = (mapPos.x - camPos.x + (1.0 - stepDir.x) * 0.5) / rayDir.x; wallX = fract(camPos.y + perp * rayDir.y); }
    else { perp = (mapPos.y - camPos.y + (1.0 - stepDir.y) * 0.5) / rayDir.y; wallX = fract(camPos.x + perp * rayDir.x); }
    perp = max(perp, 0.01);

    float wallHalf = 0.5 / perp;
    float sy = uv.y - 0.5;
    float shade = 1.0 / (1.0 + perp * 0.35);
    if (side < 0.5) shade *= 0.78;

    // Scene luminance
    float luma;
    if (abs(sy) < wallHalf) {
        float wy = sy / wallHalf;
        float by = (wy * 0.5 + 0.5) * brickRows;
        float bRow = floor(by);
        float bx = wallX * brickCols + mod(bRow, 2.0) * 0.5;
        float mortar = max(smoothstep(0.42, 0.48, abs(fract(bx) - 0.5)), smoothstep(0.40, 0.48, abs(fract(by) - 0.5)));
        luma = shade * (1.0 - mortar * 0.85);
        luma = mix(luma, 0.0, clamp(perp / 18.0, 0.0, 1.0));
    } else {
        float floorPerp = 0.5 / abs(sy);
        float cosA = dot(rayDir, camDir);
        float floorTrue = floorPerp / max(cosA, 0.01);
        vec2 fp = camPos + rayDir * floorTrue;
        float fshade = 1.0 / (1.0 + floorPerp * 0.35);
        if (sy < 0.0) fshade *= 0.65;
        float by = fp.y * floorScale;
        float bRow = floor(by);
        float bx = fp.x * floorScale + mod(bRow, 2.0) * 0.5;
        float mortar = max(smoothstep(0.42, 0.48, abs(fract(bx) - 0.5)), smoothstep(0.40, 0.48, abs(fract(by) - 0.5)));
        luma = fshade * (1.0 - mortar * 0.85);
        luma = mix(luma, 0.0, clamp(floorPerp / 18.0, 0.0, 1.0));
    }

    // 4x4 Bayer dither
    vec2 p = mod(floor(gl_FragCoord.xy), 4.0);
    vec4 r0 = vec4( 0.0, 8.0, 2.0,10.0) / 16.0;
    vec4 r1 = vec4(12.0, 4.0,14.0, 6.0) / 16.0;
    vec4 r2 = vec4( 3.0,11.0, 1.0, 9.0) / 16.0;
    vec4 r3 = vec4(15.0, 7.0,13.0, 5.0) / 16.0;
    vec4 row = p.y<1.0 ? r0 : p.y<2.0 ? r1 : p.y<3.0 ? r2 : r3;
    float threshold = p.x<1.0 ? row.x : p.x<2.0 ? row.y : p.x<3.0 ? row.z : row.w;
    float bit = step(threshold, luma);

    // Ink/paper color pairs
    float pf = fract(u_x2) * 4.0;
    float pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));
    vec3 ink0=vec3(0.0), ink1=vec3(0.0), ink2=vec3(0.0), ink3=vec3(0.05,0.05,0.18);
    vec3 pap0=vec3(1.0), pap1=vec3(0.15,0.95,0.25), pap2=vec3(1.0,0.72,0.0), pap3=vec3(0.55,0.75,1.0);
    vec3 ink = pi<0.5 ? mix(ink0,ink1,pt) : pi<1.5 ? mix(ink1,ink2,pt) : pi<2.5 ? mix(ink2,ink3,pt) : mix(ink3,ink0,pt);
    vec3 paper = pi<0.5 ? mix(pap0,pap1,pt) : pi<1.5 ? mix(pap1,pap2,pt) : pi<2.5 ? mix(pap2,pap3,pt) : mix(pap3,pap0,pt);

    vec3 out_color = mix(ink, paper, bit);
    out_color *= mod(gl_FragCoord.y, 2.0) < 1.0 ? 0.82 : 1.0;
    gl_FragColor = vec4(out_color, 1.0);
}
