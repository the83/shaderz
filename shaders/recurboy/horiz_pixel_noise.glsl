// Pixel noise — filtered noise texture generator for recurBOY
// Independent H/V coherence and density control
//
// u_x0: horizontal coherence (0 = per-pixel static, 1 = horizontal bands)
// u_x1: vertical coherence (0 = per-pixel static, 1 = vertical columns)
// u_x2: density (0 = sparse starfield, 0.5 = grain, 1 = full snow)
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

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;

    float speed = 0.3 + u_x3 * 1.5;
    float t = u_time * speed;

    float frame = t * 30.0;
    float f0 = floor(frame);
    float fBlend = fract(frame);

    float xCells = mix(u_resolution.x, 3.0, u_x0 * u_x0);
    float yCells = mix(u_resolution.y, 3.0, u_x1 * u_x1);

    float cx = floor(uv.x * xCells);
    float cy = floor(uv.y * yCells);

    float n0 = hash(vec2(cx, cy) + f0 * 7.31);
    float n1 = hash(vec2(cx, cy) + (f0 + 1.0) * 7.31);
    float noise = mix(n0, n1, fBlend);

    float cx2 = floor(uv.x * xCells * 0.73 + 5.7);
    float cy2 = floor(uv.y * yCells * 0.73 + 3.1);
    float m0 = hash2(vec2(cx2, cy2) + f0 * 5.17);
    float m1 = hash2(vec2(cx2, cy2) + (f0 + 1.0) * 5.17);
    float noise2 = mix(m0, m1, fBlend);

    noise = noise * 0.6 + noise2 * 0.4;

    float density = u_x2;
    float threshold = mix(0.75, 0.0, density);
    float softness = mix(0.12, 0.6, density);
    noise = smoothstep(threshold, threshold + softness, noise);

    float boost = mix(2.5, 1.0, min(density * 3.0, 1.0));
    noise = min(noise * boost, 1.0);

    gl_FragColor = vec4(vec3(noise), 1.0);
}
