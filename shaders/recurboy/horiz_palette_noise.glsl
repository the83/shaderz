// Palette noise — layered noise with color palettes for recurBOY
// Three independent noise layers with priority-based compositing
//
// u_x0: horizontal coherence (0 = per-pixel static, 1 = horizontal bands)
// u_x1: vertical coherence (0 = per-pixel static, 1 = vertical columns)
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

// Compute all 3 layer colors at once (one palette branch evaluation)
// Stores into globals to avoid calling palette 3x
vec3 g_c0; // highest priority (palette index 6)
vec3 g_c1; // mid priority (palette index 4)
vec3 g_c2; // lowest priority (palette index 2)

void calcColors(float sel) {
    float p = floor(sel * 7.99);

    if (p < 1.0) {
        // Warm
        g_c0 = vec3(1.0, 0.75, 0.0);
        g_c1 = vec3(1.0, 0.25, 0.0);
        g_c2 = vec3(0.57, 0.0, 0.0);
    } else if (p < 2.0) {
        // Cool
        g_c0 = vec3(0.43, 0.71, 1.0);
        g_c1 = vec3(0.0, 0.29, 1.0);
        g_c2 = vec3(0.0, 0.0, 0.57);
    } else if (p < 3.0) {
        // Coral reef — teal, pink, deep sea
        g_c0 = vec3(0.0, 0.86, 0.71);
        g_c1 = vec3(1.0, 0.43, 0.57);
        g_c2 = vec3(0.14, 0.29, 0.57);
    } else if (p < 4.0) {
        // Phosphor green
        g_c0 = vec3(0.17, 0.86, 0.26);
        g_c1 = vec3(0.11, 0.57, 0.17);
        g_c2 = vec3(0.06, 0.29, 0.09);
    } else if (p < 5.0) {
        // Synthwave
        g_c0 = vec3(0.86, 0.29, 0.14);
        g_c1 = vec3(0.57, 0.0, 0.43);
        g_c2 = vec3(0.43, 0.0, 0.57);
    } else if (p < 6.0) {
        // Electric — yellow, white, violet
        g_c0 = vec3(1.0, 1.0, 0.29);
        g_c1 = vec3(1.0, 1.0, 1.0);
        g_c2 = vec3(0.57, 0.14, 1.0);
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

    float xC = mix(u_resolution.x, 3.0, u_x0 * u_x0);
    float yC = mix(u_resolution.y, 3.0, u_x1 * u_x1);

    // Single-layer noise per channel (lighter than two-layer)
    float cx0 = floor(uv.x * xC);
    float cy0 = floor(uv.y * yC);
    float n0 = mix(hash(vec2(cx0, cy0) + f0 * 7.31), hash(vec2(cx0, cy0) + (f0 + 1.0) * 7.31), fb);

    float cx1 = floor(uv.x * xC * 1.07);
    float cy1 = floor(uv.y * yC * 1.07);
    float n1 = mix(hash(vec2(cx1, cy1) + (f0 + 31.0) * 7.31), hash(vec2(cx1, cy1) + (f0 + 32.0) * 7.31), fb);

    float cx2 = floor(uv.x * xC * 0.93);
    float cy2 = floor(uv.y * yC * 0.93);
    float n2 = mix(hash(vec2(cx2, cy2) + (f0 + 67.0) * 7.31), hash(vec2(cx2, cy2) + (f0 + 68.0) * 7.31), fb);

    float a0 = step(0.5, n0);
    float a1 = step(0.5, n1);
    float a2 = step(0.5, n2);

    // Compute palette colors once
    calcColors(u_x2);

    // Priority compositing: g_c0 > g_c1 > g_c2
    vec3 col = vec3(0.0);
    col = mix(col, g_c2, a2);
    col = mix(col, g_c1, a1);
    col = mix(col, g_c0, a0);

    gl_FragColor = vec4(col, 1.0);
}
