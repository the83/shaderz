// Rotating 3D cube — white faces, black outlines — lite for recurBOY (vertical)
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

float safeInv(float x) {
    float ax = abs(x);
    float safe = ax < 0.001 ? 0.001 : ax;
    float s = sign(x) < -0.5 ? -1.0 : 1.0;
    return s / safe;
}

void main(void) {
    vec2 fragFlip = vec2(gl_FragCoord.y, u_resolution.x - gl_FragCoord.x);
    vec2 res = u_resolution.yx;
    vec2 p = vec2(
        (2.0 * fragFlip.x - res.x) / res.y,
        (2.0 * fragFlip.y - res.y) / res.y
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

    vec3 inv = vec3(safeInv(rrd.x), safeInv(rrd.y), safeInv(rrd.z));
    vec3 t1 = (-boxSize - rro) * inv;
    vec3 t2 = ( boxSize - rro) * inv;
    vec3 mn = min(t1, t2);
    vec3 mx = max(t1, t2);
    float enter = max(max(mn.x, mn.y), mn.z);
    float exit  = min(min(mx.x, mx.y), mx.z);

    float isHit = step(enter, exit) * step(0.0, exit);
    vec3 hitPos = rro + rrd * enter;

    vec3 ad = abs(hitPos) - boxSize;
    vec3 sn = sign(hitPos);
    float xDom = step(ad.y, ad.x) * step(ad.z, ad.x);
    float yDom = step(ad.x, ad.y) * step(ad.z, ad.y) * (1.0 - xDom);
    vec3 n = xDom * vec3(sn.x, 0.0, 0.0)
           + yDom * vec3(0.0, sn.y, 0.0)
           + (1.0 - xDom - yDom) * vec3(0.0, 0.0, sn.z);

    vec3 d = abs(hitPos) / boxSize;
    vec3 e = smoothstep(1.0 - 0.06, 1.0 - 0.018, d);
    vec3 an = abs(n);
    e *= vec3(1.0) - an;
    float edge = 1.0 - min(e.x + e.y + e.z, 1.0);

    float col = edge * isHit;
    gl_FragColor = vec4(col, col, col, 1.0);
}
