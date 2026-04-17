// Triangle noise — diagonal layered noise with fortress color palettes
// Each layer samples through a rotated grid (0°, 60°, -60°)
// creating triangular intersection patterns via priority compositing
//
// u_x0: cell size (0 = fine, 1 = large)
// u_x1: rotation drift (0 = fixed angles, 1 = slowly rotating)
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

vec2 rot2(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float channelNoise(vec2 uv, float cells, float f0, float fBlend, float tOff, float angle) {
    vec2 ruv = rot2(uv - 0.5, angle) + 0.5;

    float cx = floor(ruv.x * cells);
    float cy = floor(ruv.y * cells);

    float n0 = hash(vec2(cx, cy) + (f0 + tOff) * 7.31);
    float n1 = hash(vec2(cx, cy) + (f0 + tOff + 1.0) * 7.31);
    float noise = mix(n0, n1, fBlend);

    float cx2 = floor(ruv.x * cells * 0.73 + 5.7);
    float cy2 = floor(ruv.y * cells * 0.73 + 3.1);
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
        g_c0 = vec3(1.0, 0.0, 0.0); g_c1 = vec3(0.0, 1.0, 0.0); g_c2 = vec3(0.0, 0.0, 1.0); // RGB
    } else if (p < 2.0) {
        g_c0 = vec3(1.0, 0.75, 0.0); g_c1 = vec3(1.0, 0.25, 0.0); g_c2 = vec3(0.57, 0.0, 0.0); // Warm
    } else if (p < 3.0) {
        g_c0 = vec3(0.43, 0.71, 1.0); g_c1 = vec3(0.0, 0.29, 1.0); g_c2 = vec3(0.0, 0.0, 0.57); // Cool
    } else if (p < 4.0) {
        g_c0 = vec3(0.0, 0.86, 0.71); g_c1 = vec3(1.0, 0.43, 0.57); g_c2 = vec3(0.14, 0.29, 0.57); // Coral reef
    } else if (p < 5.0) {
        g_c0 = vec3(0.17, 0.86, 0.26); g_c1 = vec3(0.11, 0.57, 0.17); g_c2 = vec3(0.06, 0.29, 0.09); // Phosphor green
    } else if (p < 6.0) {
        g_c0 = vec3(0.86, 0.29, 0.14); g_c1 = vec3(0.57, 0.0, 0.43); g_c2 = vec3(0.43, 0.0, 0.57); // Synthwave
    } else if (p < 7.0) {
        g_c0 = vec3(1.0, 0.71, 0.0); g_c1 = vec3(0.86, 0.14, 0.14); g_c2 = vec3(0.43, 0.0, 0.43); // Sunset
    } else if (p < 8.0) {
        g_c0 = vec3(0.0, 1.0, 1.0); g_c1 = vec3(1.0, 0.0, 0.71); g_c2 = vec3(0.43, 0.0, 0.71); // Neon
    } else if (p < 9.0) {
        g_c0 = vec3(1.0, 0.86, 0.0); g_c1 = vec3(1.0, 0.14, 0.29); g_c2 = vec3(0.14, 0.0, 0.71); // Thermal
    } else if (p < 10.0) {
        g_c0 = vec3(0.57, 0.86, 1.0); g_c1 = vec3(0.0, 0.43, 0.71); g_c2 = vec3(0.0, 0.14, 0.43); // Ocean
    } else if (p < 11.0) {
        g_c0 = vec3(0.43, 0.71, 0.21); g_c1 = vec3(0.21, 0.43, 0.11); g_c2 = vec3(0.07, 0.29, 0.04); // Gameboy
    } else if (p < 12.0) {
        g_c0 = vec3(1.0); g_c1 = vec3(0.57); g_c2 = vec3(0.29); // Grayscale
    } else if (p < 13.0) {
        g_c0 = vec3(0.0, 1.0, 1.0); g_c1 = vec3(1.0, 0.0, 1.0); g_c2 = vec3(1.0, 1.0, 0.0); // CMY
    } else if (p < 14.0) {
        g_c0 = vec3(1.0, 0.71, 0.14); g_c1 = vec3(0.71, 0.43, 0.07); g_c2 = vec3(0.43, 0.21, 0.0); // Amber
    } else if (p < 15.0) {
        g_c0 = vec3(0.86, 0.71, 0.43); g_c1 = vec3(0.57, 0.43, 0.21); g_c2 = vec3(0.29, 0.21, 0.11); // Sepia
    } else {
        g_c0 = vec3(1.0, 0.71, 0.86); g_c1 = vec3(0.71, 0.86, 1.0); g_c2 = vec3(0.86, 1.0, 0.71); // Pastel
    }
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float speed = u_x3 * 2.0;
    float t = u_time * speed;

    float frame = t * 30.0;
    float f0 = floor(frame);
    float fBlend = fract(frame);

    // Cell count: both axes use the same scale (since rotation mixes them)
    float cells = mix(u_resolution.y, 4.0, u_x0 * u_x0);

    // Base angles: 0°, 60°, -60° — plus optional slow drift
    float drift = u_x1 * t * 0.15;
    float a0 = 0.0 + drift;
    float a1 = 1.047 + drift * 0.7;   // ~60°
    float a2 = -1.047 + drift * 1.3;  // ~-60°

    // Three noise layers, each rotated to a different angle
    float n0 = channelNoise(uv, cells, f0, fBlend, 0.0,  a0);
    float n1 = channelNoise(uv, cells, f0, fBlend, 31.0, a1);
    float n2 = channelNoise(uv, cells, f0, fBlend, 67.0, a2);

    // Binary threshold
    float threshold = 0.38;
    float softness = 0.36;
    float hit0 = step(0.5, smoothstep(threshold, threshold + softness, n0));
    float hit1 = step(0.5, smoothstep(threshold, threshold + softness, n1));
    float hit2 = step(0.5, smoothstep(threshold, threshold + softness, n2));

    // Compute palette colors once
    calcColors(u_x2);

    // Priority compositing: layer 0 > layer 1 > layer 2
    vec3 col = vec3(0.0);
    if (hit2 > 0.5) col = g_c2;
    if (hit1 > 0.5) col = g_c1;
    if (hit0 > 0.5) col = g_c0;

    gl_FragColor = vec4(col, 1.0);
}
