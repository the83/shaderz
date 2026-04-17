// Color noise — chromatic filtered noise for recurBOY
// Each RGB channel runs independent noise at offset scales
//
// u_x0: horizontal coherence (0 = per-pixel static, 1 = horizontal bands)
// u_x1: vertical coherence (0 = per-pixel static, 1 = vertical columns)
// u_x2: density (0 = sparse colored sparks, 0.5 = grain, 1 = full color snow)
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

// Single channel noise with scale and time offsets
float chNoise(vec2 uv, float xC, float yC, float f0, float fb, float tOff, float sOff) {
    float cx = floor(uv.x * xC * sOff);
    float cy = floor(uv.y * yC * sOff);

    float n0 = hash(vec2(cx, cy) + (f0 + tOff) * 7.31);
    float n1 = hash(vec2(cx, cy) + (f0 + tOff + 1.0) * 7.31);
    float noise = mix(n0, n1, fb);

    float cx2 = floor(uv.x * xC * sOff * 0.73 + 5.7);
    float cy2 = floor(uv.y * yC * sOff * 0.73 + 3.1);
    float m0 = hash2(vec2(cx2, cy2) + (f0 + tOff) * 5.17);
    float m1 = hash2(vec2(cx2, cy2) + (f0 + tOff + 1.0) * 5.17);

    return noise * 0.6 + mix(m0, m1, fb) * 0.4;
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

    float r = chNoise(uv, xC, yC, f0, fb, 0.0,  1.0);
    float g = chNoise(uv, xC, yC, f0, fb, 31.0, 1.07);
    float b = chNoise(uv, xC, yC, f0, fb, 67.0, 0.93);

    float density = u_x2;
    float threshold = mix(0.75, 0.0, density);
    float softness = mix(0.12, 0.6, density);

    r = smoothstep(threshold, threshold + softness, r);
    g = smoothstep(threshold, threshold + softness, g);
    b = smoothstep(threshold, threshold + softness, b);

    float boost = mix(2.5, 1.0, min(density * 3.0, 1.0));

    gl_FragColor = vec4(
        min(r * boost, 1.0),
        min(g * boost, 1.0),
        min(b * boost, 1.0),
        1.0
    );
}
