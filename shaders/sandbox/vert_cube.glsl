// Rotating 3D cube — analytical ray-box intersection (vertical)
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

vec2 boxHit(vec3 ro, vec3 rd, vec3 size) {
    vec3 inv = 1.0 / rd;
    vec3 t1 = (-size - ro) * inv;
    vec3 t2 = ( size - ro) * inv;
    vec3 mn = min(t1, t2);
    vec3 mx = max(t1, t2);
    float enter = max(max(mn.x, mn.y), mn.z);
    float exit  = min(min(mx.x, mx.y), mx.z);
    return vec2(enter, exit);
}

vec3 boxNormal(vec3 p, vec3 size) {
    vec3 d = abs(p) - size;
    vec3 s = sign(p);
    if (d.x > d.y && d.x > d.z) return vec3(s.x, 0.0, 0.0);
    if (d.y > d.z) return vec3(0.0, s.y, 0.0);
    return vec3(0.0, 0.0, s.z);
}

vec3 faceColor(vec3 n) {
    vec3 an = abs(n);
    if (an.x > 0.5) return vec3(0.9, 0.25, 0.2);
    if (an.y > 0.5) return vec3(0.2, 0.8, 0.3);
    return vec3(0.2, 0.4, 0.95);
}

float checker(vec3 p, vec3 n) {
    vec3 an = abs(n);
    vec2 uv;
    if (an.x > 0.5) uv = p.yz;
    else if (an.y > 0.5) uv = p.xz;
    else uv = p.xy;
    vec2 q = floor(uv * 3.0);
    return mod(q.x + q.y, 2.0) * 0.15 + 0.85;
}

float edgeFactor(vec3 p, vec3 size) {
    vec3 d = abs(p) / size;
    vec3 edge = smoothstep(0.85, 0.95, d);
    float e = max(max(edge.x + edge.y, edge.x + edge.z), edge.y + edge.z);
    return 1.0 - e * 0.6;
}

void main(void) {
    vec2 rawUV = gl_FragCoord.xy / u_resolution;
    vec2 uv = vec2(rawUV.y, 1.0 - rawUV.x);

    vec2 fragFlip = vec2(gl_FragCoord.y, u_resolution.x - gl_FragCoord.x);
    vec2 res = u_resolution.yx;
    vec2 p = (2.0 * fragFlip - res) / res.y;

    float speed = u_x3 * 2.0;
    float t = u_time * speed;

    float rx = (u_x0 - 0.5) * 4.0 * t;
    float ry = (u_x1 - 0.5) * 4.0 * t;
    float rz = (u_x2 - 0.5) * 4.0 * t;

    mat3 rot = rotZ(rz) * rotY(ry) * rotX(rx);

    vec3 ro = vec3(0.0, 0.0, 4.0);
    vec3 rd = normalize(vec3(p, -1.8));

    vec3 rro = rot * ro;
    vec3 rrd = rot * rd;

    vec3 boxSize = vec3(0.8);

    vec2 hit = boxHit(rro, rrd, boxSize);

    vec3 bg = vec3(0.0);

    if (hit.x > hit.y || hit.y < 0.0) {
        gl_FragColor = vec4(bg, 1.0);
        return;
    }

    vec3 hitPos = rro + rrd * hit.x;
    vec3 n = boxNormal(hitPos, boxSize);

    vec3 worldN = transpose3(rot) * n;
    vec3 lightDir = normalize(vec3(0.5, 0.8, 1.0));
    float diff = max(dot(worldN, lightDir), 0.0);
    float amb = 0.25;

    vec3 viewDir = normalize(-rd);
    vec3 refl = reflect(-lightDir, worldN);
    float spec = pow(max(dot(viewDir, refl), 0.0), 32.0);

    vec3 baseCol = faceColor(n);
    float check = checker(hitPos, n);
    float edge = edgeFactor(hitPos, boxSize);

    vec3 col = baseCol * check * edge * (amb + diff * 0.75) + vec3(1.0) * spec * 0.4;

    float rim = 1.0 - max(dot(worldN, viewDir), 0.0);
    col += vec3(0.15, 0.1, 0.25) * rim * rim;

    gl_FragColor = vec4(col, 1.0);
}
