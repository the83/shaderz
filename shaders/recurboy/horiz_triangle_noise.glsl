// Triangle noise — diagonal layered noise with color palettes for recurBOY
// Each layer samples through a rotated grid (0°, 60°, -60°)
//
// u_x0: cell size (0 = fine, 1 = large)
// u_x1: rotation drift (0 = fixed angles, 1 = slowly rotating)
// u_x2: color palette (8 palettes)
// u_x3: speed / animation rate

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 rot2(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float chNoise(vec2 uv, float cells, float f0, float fb, float tOff, float angle) {
    vec2 ruv = rot2(uv - 0.5, angle) + 0.5;
    float cx = floor(ruv.x * cells);
    float cy = floor(ruv.y * cells);
    float n0 = hash(vec2(cx, cy) + (f0 + tOff) * 7.31);
    float n1 = hash(vec2(cx, cy) + (f0 + tOff + 1.0) * 7.31);
    return mix(n0, n1, fb);
}

// Pre-baked palette colors (one branch, 3 colors out)
vec3 g_c0;
vec3 g_c1;
vec3 g_c2;

void calcColors(float sel) {
    float p = floor(sel * 7.99);

    if (p < 1.0) {
        // RGB
        g_c0 = vec3(1.0, 0.0, 0.0);
        g_c1 = vec3(0.0, 1.0, 0.0);
        g_c2 = vec3(0.0, 0.0, 1.0);
    } else if (p < 2.0) {
        // Warm
        g_c0 = vec3(1.0, 0.75, 0.0);
        g_c1 = vec3(1.0, 0.25, 0.0);
        g_c2 = vec3(0.57, 0.0, 0.0);
    } else if (p < 3.0) {
        // Cool
        g_c0 = vec3(0.43, 0.71, 1.0);
        g_c1 = vec3(0.0, 0.29, 1.0);
        g_c2 = vec3(0.0, 0.0, 0.57);
    } else if (p < 4.0) {
        // Coral reef
        g_c0 = vec3(0.0, 0.86, 0.71);
        g_c1 = vec3(1.0, 0.43, 0.57);
        g_c2 = vec3(0.14, 0.29, 0.57);
    } else if (p < 5.0) {
        // Phosphor green
        g_c0 = vec3(0.17, 0.86, 0.26);
        g_c1 = vec3(0.11, 0.57, 0.17);
        g_c2 = vec3(0.06, 0.29, 0.09);
    } else if (p < 6.0) {
        // Synthwave
        g_c0 = vec3(0.86, 0.29, 0.14);
        g_c1 = vec3(0.57, 0.0, 0.43);
        g_c2 = vec3(0.43, 0.0, 0.57);
    } else if (p < 7.0) {
        // Sunset
        g_c0 = vec3(1.0, 0.71, 0.0);
        g_c1 = vec3(0.86, 0.14, 0.14);
        g_c2 = vec3(0.43, 0.0, 0.43);
    } else {
        // Neon
        g_c0 = vec3(0.0, 1.0, 1.0);
        g_c1 = vec3(1.0, 0.0, 0.71);
        g_c2 = vec3(0.43, 0.0, 0.71);
    }
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;

    float speed = 0.3 + u_x3 * 1.5;
    float t = u_time * speed;

    float frame = t * 30.0;
    float f0 = floor(frame);
    float fb = fract(frame);

    float cells = mix(u_resolution.y, 4.0, u_x0 * u_x0);

    float drift = u_x1 * t * 0.15;
    float a0 = 0.0 + drift;
    float a1 = 1.047 + drift * 0.7;
    float a2 = -1.047 + drift * 1.3;

    float n0 = chNoise(uv, cells, f0, fb, 0.0,  a0);
    float n1 = chNoise(uv, cells, f0, fb, 31.0, a1);
    float n2 = chNoise(uv, cells, f0, fb, 67.0, a2);

    float hit0 = step(0.5, n0);
    float hit1 = step(0.5, n1);
    float hit2 = step(0.5, n2);

    calcColors(u_x2);

    vec3 col = vec3(0.0);
    col = mix(col, g_c2, hit2);
    col = mix(col, g_c1, hit1);
    col = mix(col, g_c0, hit0);

    gl_FragColor = vec4(col, 1.0);
}
