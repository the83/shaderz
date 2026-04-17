// Rotating 3D cube — white faces, black outlines
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

// Returns 0.0 on edges, 1.0 on face interior
// Needs the face normal to know which two axes to check
float edgeMask(vec3 p, vec3 n, vec3 size, float width) {
    vec3 d = abs(p) / size;
    vec3 e = smoothstep(1.0 - width, 1.0 - width * 0.3, d);
    // Only check the two in-plane axes (mask out the face-normal axis)
    vec3 an = abs(n);
    // Zero out the face axis so it doesn't contribute
    e *= vec3(1.0) - an;
    return 1.0 - min(e.x + e.y + e.z, 1.0);
}

void main(void) {
    vec2 p = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;

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

    if (hit.x > hit.y || hit.y < 0.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 hitPos = rro + rrd * hit.x;
    vec3 n = boxNormal(hitPos, boxSize);
    float edge = edgeMask(hitPos, n, boxSize, 0.06);

    // White face, black outline
    gl_FragColor = vec4(vec3(edge), 1.0);
}
