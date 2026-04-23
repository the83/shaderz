// Spirograph — glowing hypotrochoid curves for recurBOY
// Neon glow rendering with additive distance field
//
// u_x0: petal count / inner-to-outer ratio (3 to 9 lobes)
// u_x1: pen offset (controls loop depth, pointy vs round)
// u_x2: color palette (13 palettes)
// u_x3: speed (center = stopped, left = reverse, right = forward)

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

vec3 g_c0;
vec3 g_c1;
vec3 g_c2;

void calcColors(float sel) {
    float p = floor(sel * 12.99);

    if (p < 1.0) {
        // B&W high contrast
        g_c0 = vec3(1.0);
        g_c1 = vec3(0.5);
        g_c2 = vec3(0.0);
    } else if (p < 2.0) {
        // RGB
        g_c0 = vec3(1.0, 0.0, 0.0);
        g_c1 = vec3(0.0, 1.0, 0.0);
        g_c2 = vec3(0.0, 0.0, 1.0);
    } else if (p < 3.0) {
        // Warm
        g_c0 = vec3(1.0, 0.75, 0.0);
        g_c1 = vec3(1.0, 0.25, 0.0);
        g_c2 = vec3(0.57, 0.0, 0.0);
    } else if (p < 4.0) {
        // Cool
        g_c0 = vec3(0.43, 0.71, 1.0);
        g_c1 = vec3(0.0, 0.29, 1.0);
        g_c2 = vec3(0.0, 0.0, 0.57);
    } else if (p < 5.0) {
        // Coral reef
        g_c0 = vec3(0.0, 0.86, 0.71);
        g_c1 = vec3(1.0, 0.43, 0.57);
        g_c2 = vec3(0.14, 0.29, 0.57);
    } else if (p < 6.0) {
        // Phosphor green
        g_c0 = vec3(0.17, 0.86, 0.26);
        g_c1 = vec3(0.11, 0.57, 0.17);
        g_c2 = vec3(0.06, 0.29, 0.09);
    } else if (p < 7.0) {
        // Synthwave
        g_c0 = vec3(0.86, 0.29, 0.14);
        g_c1 = vec3(0.57, 0.0, 0.43);
        g_c2 = vec3(0.43, 0.0, 0.57);
    } else if (p < 8.0) {
        // Sunset
        g_c0 = vec3(1.0, 0.71, 0.0);
        g_c1 = vec3(0.86, 0.14, 0.14);
        g_c2 = vec3(0.43, 0.0, 0.43);
    } else if (p < 9.0) {
        // Neon
        g_c0 = vec3(0.0, 1.0, 1.0);
        g_c1 = vec3(1.0, 0.0, 0.71);
        g_c2 = vec3(0.43, 0.0, 0.71);
    } else if (p < 10.0) {
        // Ice
        g_c0 = vec3(0.85, 0.95, 1.0);
        g_c1 = vec3(0.4, 0.7, 0.9);
        g_c2 = vec3(0.05, 0.15, 0.4);
    } else if (p < 11.0) {
        // Fire
        g_c0 = vec3(1.0, 1.0, 0.4);
        g_c1 = vec3(1.0, 0.4, 0.0);
        g_c2 = vec3(0.4, 0.0, 0.0);
    } else if (p < 12.0) {
        // Vapor
        g_c0 = vec3(0.95, 0.6, 0.9);
        g_c1 = vec3(0.5, 0.8, 1.0);
        g_c2 = vec3(0.3, 0.2, 0.6);
    } else {
        // Earth
        g_c0 = vec3(0.85, 0.75, 0.45);
        g_c1 = vec3(0.45, 0.55, 0.25);
        g_c2 = vec3(0.25, 0.15, 0.05);
    }
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;

    // Bipolar speed: center = stopped, left = reverse, right = forward
    float speedKnob = (u_x3 - 0.5) * 2.0;
    float speed = speedKnob * 0.5;
    float t = u_time * speed;

    // Spirograph geometry: hypotrochoid with R=1, r=1/k, pen offset d
    float k = mix(3.0, 9.0, u_x0);
    float km1 = k - 1.0;
    float R = 1.0;
    float r = R / k;
    float a = R - r;
    float d = mix(0.1, 0.95, u_x1) * a;

    // Map pixel to centered coords scaled to fit the curve
    float aspect = u_resolution.x / u_resolution.y;
    float maxR = a + d;
    vec2 p = (uv - 0.5) * 2.0 * maxR * 1.15;
    p.x *= aspect;

    // Trace curve with additive glow
    float glow = 0.0;
    float step = 6.2832 * 2.0 / 12.0;

    for (float i = 0.0; i < 12.0; i += 1.0) {
        float s = t + i * step;
        float cx = a * cos(s) + d * cos(km1 * s);
        float cy = a * sin(s) - d * sin(km1 * s);
        float ex = p.x - cx;
        float ey = p.y - cy;
        glow += 0.004 / (ex * ex + ey * ey + 0.003);
    }

    glow = clamp(glow, 0.0, 1.0);

    calcColors(u_x2);

    // Map glow intensity through palette
    vec3 col = vec3(0.0);
    float f3 = glow * 3.0;
    col = mix(col, g_c2, clamp(f3, 0.0, 1.0));
    col = mix(col, g_c1, clamp(f3 - 0.5, 0.0, 1.0));
    col = mix(col, g_c0, clamp(f3 - 1.5, 0.0, 1.0));
    col = mix(col, vec3(1.0), clamp(f3 - 2.5, 0.0, 1.0));

    gl_FragColor = vec4(col, 1.0);
}
