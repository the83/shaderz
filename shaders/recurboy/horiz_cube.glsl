// Rotating 3D cube — lite version for recurBOY
// Analytical ray-box intersection, no loops
//
// u_x0: X-axis rotation speed (0.5 = stopped, 0 = reverse, 1 = forward)
// u_x1: Y-axis rotation speed (0.5 = stopped, 0 = reverse, 1 = forward)
// u_x2: Z-axis rotation speed (0.5 = stopped, 0 = reverse, 1 = forward)
// u_x3: overall speed

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

mat3 transpose3(mat3 m) {
    return mat3(
        m[0][0], m[1][0], m[2][0],
        m[0][1], m[1][1], m[2][1],
        m[0][2], m[1][2], m[2][2]
    );
}

mat3 rotX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);
}

mat3 rotY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}

mat3 rotZ(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);
}

// Safe inverse — clamp away from zero to avoid Pi GPU crash
float safeInv(float x) {
    float ax = abs(x);
    float sx = sign(x);
    // if abs(x) < 0.001, clamp to 0.001 with same sign
    // sign(0) = 0, so force positive in that case
    float safe = ax < 0.001 ? 0.001 : ax;
    float s = sx < -0.5 ? -1.0 : 1.0;
    return s / safe;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
    vec2 p = vec2(
        (2.0 * gl_FragCoord.x - u_resolution.x) / u_resolution.y,
        (u_resolution.y - 2.0 * gl_FragCoord.y) / u_resolution.y
    );

    float speed = 0.3 + u_x3 * 1.5;
    float t = u_time * speed;

    float rx = (u_x0 - 0.5) * 4.0 * t;
    float ry = (u_x1 - 0.5) * 4.0 * t;
    float rz = (u_x2 - 0.5) * 4.0 * t;

    mat3 rot = rotZ(rz) * rotY(ry) * rotX(rx);

    vec3 ro = vec3(0.0, 0.0, 4.0);
    vec3 rd = normalize(vec3(p, -1.8));

    vec3 rro = rot * ro;
    vec3 rrd = rot * rd;

    float boxSize = 0.8;

    // Ray-box intersection with safe inverse
    vec3 inv = vec3(safeInv(rrd.x), safeInv(rrd.y), safeInv(rrd.z));
    vec3 t1 = (-boxSize - rro) * inv;
    vec3 t2 = ( boxSize - rro) * inv;
    vec3 mn = min(t1, t2);
    vec3 mx = max(t1, t2);
    float enter = max(max(mn.x, mn.y), mn.z);
    float exit  = min(min(mx.x, mx.y), mx.z);

    // Background
    vec3 bg = vec3(0.0);

    // Miss — use bg
    float isHit = step(enter, exit) * step(0.0, exit);
    vec3 hitPos = rro + rrd * enter;

    // Normal: find dominant axis
    vec3 ad = abs(hitPos) - boxSize;
    vec3 sn = sign(hitPos);
    vec3 n = vec3(0.0, 0.0, sn.z);
    // step(ad.y, ad.x) is 1 when ad.x >= ad.y
    float xDom = step(ad.y, ad.x) * step(ad.z, ad.x);
    float yDom = step(ad.x, ad.y) * step(ad.z, ad.y) * (1.0 - xDom);
    n = xDom * vec3(sn.x, 0.0, 0.0)
      + yDom * vec3(0.0, sn.y, 0.0)
      + (1.0 - xDom - yDom) * vec3(0.0, 0.0, sn.z);

    // Face colors
    vec3 an = abs(n);
    vec3 faceCol = an.x * vec3(0.9, 0.25, 0.2)
                 + an.y * vec3(0.2, 0.8, 0.3)
                 + an.z * vec3(0.2, 0.4, 0.95);

    // Simple lighting
    vec3 worldN = transpose3(rot) * n;
    vec3 lightDir = normalize(vec3(0.5, 0.8, 1.0));
    float diff = max(dot(worldN, lightDir), 0.0);

    vec3 col = faceCol * (0.25 + diff * 0.75);
    col = mix(bg, col, isHit);

    gl_FragColor = vec4(col, 1.0);
}
