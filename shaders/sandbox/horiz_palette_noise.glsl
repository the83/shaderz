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

// --- Fortress palette (3-bit value → RGB) ---

float bit(float val, float n) {
    float v = floor(val * 7.0 + 0.5);
    return mod(floor(v / (n < 0.5 ? 1.0 : n < 1.5 ? 2.0 : 4.0)), 2.0);
}

vec3 palette(float val, float sel) {
    float idx = floor(val * 7.0 + 0.5);
    float p = floor(sel * 15.99);

    vec3 col;

    if (p < 1.0) {
        col = vec3(min(idx / 3.0, 1.0), max(0.0, (idx - 3.0) / 4.0), max(0.0, (idx - 6.0)));
    } else if (p < 2.0) {
        col = vec3(max(0.0, (idx - 5.0) / 2.0), max(0.0, (idx - 2.0) / 5.0), min(idx / 3.0, 1.0));
    } else if (p < 3.0) {
        col = vec3(bit(val, 0.0), bit(val, 1.0), bit(val, 2.0));
    } else if (p < 4.0) {
        float v = idx / 7.0;
        col = vec3(v * 0.2, v, v * 0.3);
    } else if (p < 5.0) {
        col = vec3(0.2 + idx / 9.0, max(0.0, (idx - 4.0) / 6.0), max(0.0, 0.8 - idx / 10.0));
    } else if (p < 6.0) {
        col = vec3(1.0 - bit(val, 2.0), 1.0 - bit(val, 0.0), 1.0 - bit(val, 1.0));
    } else if (p < 7.0) {
        float v = idx / 7.0;
        col = vec3(v, v * 0.6, v * 0.1);
    } else if (p < 8.0) {
        col = vec3(bit(val, 0.0) * 0.9 + bit(val, 2.0) * 0.1, bit(val, 1.0) * 0.9 + bit(val, 2.0) * 0.1, bit(val, 2.0));
    } else if (p < 9.0) {
        col = vec3(smoothstep(2.0, 5.0, idx), smoothstep(5.0, 7.0, idx), smoothstep(0.0, 3.0, idx) - smoothstep(5.0, 7.0, idx));
    } else if (p < 10.0) {
        col = vec3(max(0.0, (idx - 5.0) / 3.0), smoothstep(1.0, 6.0, idx), 0.15 + idx / 9.0);
    } else if (p < 11.0) {
        float v = idx / 7.0;
        col = vec3(v * 0.5, 0.2 + v * 0.6, v * 0.25);
    } else if (p < 12.0) {
        float v = idx / 7.0;
        col = vec3(v);
    } else if (p < 13.0) {
        col = vec3(smoothstep(0.0, 3.0, idx) - smoothstep(4.0, 6.0, idx) + smoothstep(6.0, 7.0, idx), smoothstep(3.0, 6.0, idx), smoothstep(1.0, 4.0, idx));
    } else if (p < 14.0) {
        col = vec3(smoothstep(1.0, 4.0, idx), smoothstep(4.0, 7.0, idx) * 0.8, smoothstep(0.0, 2.0, idx) - smoothstep(3.0, 6.0, idx));
    } else if (p < 15.0) {
        float v = idx / 7.0;
        col = vec3(0.15 + v * 0.7, 0.1 + v * 0.55, 0.05 + v * 0.35);
    } else {
        col = vec3(0.4 + bit(val, 0.0) * 0.4 + bit(val, 2.0) * 0.2, 0.4 + bit(val, 1.0) * 0.4 + bit(val, 0.0) * 0.2, 0.4 + bit(val, 2.0) * 0.4 + bit(val, 1.0) * 0.2);
    }

    return floor(col * 7.0 + 0.5) / 7.0;
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

    // Priority compositing: layer 0 (highest) → layer 1 → layer 2
    // Three colors from the palette: indices 6, 4, 2 (spread across 0-7 range)
    // Priority: 6 > 4 > 2
    vec3 col = vec3(0.0); // background: black (palette index 0)

    // Lowest priority first, overwritten by higher
    if (a2 > 0.5) col = palette(2.0 / 7.0, u_x2);
    if (a1 > 0.5) col = palette(4.0 / 7.0, u_x2);
    if (a0 > 0.5) col = palette(6.0 / 7.0, u_x2);

    gl_FragColor = vec4(col, 1.0);
}
