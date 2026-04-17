// Palette noise — layered noise with fortress color palettes
// Three independent noise layers with priority-based compositing
// No color mixing — highest priority layer wins
//
// u_x0: horizontal coherence (0 = per-pixel static, 1 = horizontal bands)
// u_x1: vertical coherence (0 = per-pixel static, 1 = vertical columns)
// u_x2: color palette (16 palettes)
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

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float channelNoise(vec2 uv, float xCells, float yCells, float f0, float fBlend, float tOff, float scaleOff) {
    float cx = floor(uv.x * xCells * scaleOff);
    float cy = floor(uv.y * yCells * scaleOff);

    float n0 = hash(vec2(cx, cy) + (f0 + tOff) * 7.31);
    float n1 = hash(vec2(cx, cy) + (f0 + tOff + 1.0) * 7.31);
    float noise = mix(n0, n1, fBlend);

    float cx2 = floor(uv.x * xCells * scaleOff * 0.73 + 5.7);
    float cy2 = floor(uv.y * yCells * scaleOff * 0.73 + 3.1);
    float m0 = hash2(vec2(cx2, cy2) + (f0 + tOff) * 5.17);
    float m1 = hash2(vec2(cx2, cy2) + (f0 + tOff + 1.0) * 5.17);

    return noise * 0.6 + mix(m0, m1, fBlend) * 0.4;
}

// Pre-baked color triples per palette (16 palettes)
vec3 g_c0; // highest priority
vec3 g_c1; // mid priority
vec3 g_c2; // lowest priority

void calcColors(float sel) {
    float p = floor(sel * 15.99);

    if (p < 1.0) {
        // 0: RGB
        g_c0 = vec3(1.0, 0.0, 0.0);
        g_c1 = vec3(0.0, 1.0, 0.0);
        g_c2 = vec3(0.0, 0.0, 1.0);
    } else if (p < 2.0) {
        // 1: Warm
        g_c0 = vec3(1.0, 0.75, 0.0);
        g_c1 = vec3(1.0, 0.25, 0.0);
        g_c2 = vec3(0.57, 0.0, 0.0);
    } else if (p < 3.0) {
        // 2: Cool
        g_c0 = vec3(0.43, 0.71, 1.0);
        g_c1 = vec3(0.0, 0.29, 1.0);
        g_c2 = vec3(0.0, 0.0, 0.57);
    } else if (p < 4.0) {
        // 3: Coral reef
        g_c0 = vec3(0.0, 0.86, 0.71);
        g_c1 = vec3(1.0, 0.43, 0.57);
        g_c2 = vec3(0.14, 0.29, 0.57);
    } else if (p < 5.0) {
        // 4: Phosphor green
        g_c0 = vec3(0.17, 0.86, 0.26);
        g_c1 = vec3(0.11, 0.57, 0.17);
        g_c2 = vec3(0.06, 0.29, 0.09);
    } else if (p < 6.0) {
        // 5: Synthwave
        g_c0 = vec3(0.86, 0.29, 0.14);
        g_c1 = vec3(0.57, 0.0, 0.43);
        g_c2 = vec3(0.43, 0.0, 0.57);
    } else if (p < 7.0) {
        // 6: Sunset
        g_c0 = vec3(1.0, 0.71, 0.0);
        g_c1 = vec3(0.86, 0.14, 0.14);
        g_c2 = vec3(0.43, 0.0, 0.43);
    } else if (p < 8.0) {
        // 7: Neon
        g_c0 = vec3(0.0, 1.0, 1.0);
        g_c1 = vec3(1.0, 0.0, 0.71);
        g_c2 = vec3(0.43, 0.0, 0.71);
    } else if (p < 9.0) {
        // 8: Thermal
        g_c0 = vec3(1.0, 0.86, 0.0);
        g_c1 = vec3(1.0, 0.14, 0.29);
        g_c2 = vec3(0.14, 0.0, 0.71);
    } else if (p < 10.0) {
        // 9: Ocean
        g_c0 = vec3(0.57, 0.86, 1.0);
        g_c1 = vec3(0.0, 0.43, 0.71);
        g_c2 = vec3(0.0, 0.14, 0.43);
    } else if (p < 11.0) {
        // 10: Gameboy
        g_c0 = vec3(0.43, 0.71, 0.21);
        g_c1 = vec3(0.21, 0.43, 0.11);
        g_c2 = vec3(0.07, 0.29, 0.04);
    } else if (p < 12.0) {
        // 11: Grayscale
        g_c0 = vec3(1.0);
        g_c1 = vec3(0.57);
        g_c2 = vec3(0.29);
    } else if (p < 13.0) {
        // 12: CMY
        g_c0 = vec3(0.0, 1.0, 1.0);
        g_c1 = vec3(1.0, 0.0, 1.0);
        g_c2 = vec3(1.0, 1.0, 0.0);
    } else if (p < 14.0) {
        // 13: Amber
        g_c0 = vec3(1.0, 0.71, 0.14);
        g_c1 = vec3(0.71, 0.43, 0.07);
        g_c2 = vec3(0.43, 0.21, 0.0);
    } else if (p < 15.0) {
        // 14: Sepia
        g_c0 = vec3(0.86, 0.71, 0.43);
        g_c1 = vec3(0.57, 0.43, 0.21);
        g_c2 = vec3(0.29, 0.21, 0.11);
    } else {
        // 15: Pastel
        g_c0 = vec3(1.0, 0.71, 0.86);
        g_c1 = vec3(0.71, 0.86, 1.0);
        g_c2 = vec3(0.86, 1.0, 0.71);
    }
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float speed = u_x3 * 2.0;
    float t = u_time * speed;

    float frame = t * 30.0;
    float f0 = floor(frame);
    float fBlend = fract(frame);

    float xCells = mix(u_resolution.x, 3.0, u_x0 * u_x0);
    float yCells = mix(u_resolution.y, 3.0, u_x1 * u_x1);

    // Three noise layers at different scales/offsets
    float n0 = channelNoise(uv, xCells, yCells, f0, fBlend, 0.0,  1.0);
    float n1 = channelNoise(uv, xCells, yCells, f0, fBlend, 31.0, 1.07);
    float n2 = channelNoise(uv, xCells, yCells, f0, fBlend, 67.0, 0.93);

    // Fixed density threshold
    float threshold = 0.38;
    float softness = 0.36;
    float a0 = step(0.5, smoothstep(threshold, threshold + softness, n0));
    float a1 = step(0.5, smoothstep(threshold, threshold + softness, n1));
    float a2 = step(0.5, smoothstep(threshold, threshold + softness, n2));

    // Compute palette colors once
    calcColors(u_x2);

    // Priority compositing: layer 0 (highest) → layer 1 → layer 2
    vec3 col = vec3(0.0);
    if (a2 > 0.5) col = g_c2;
    if (a1 > 0.5) col = g_c1;
    if (a0 > 0.5) col = g_c0;

    gl_FragColor = vec4(col, 1.0);
}
