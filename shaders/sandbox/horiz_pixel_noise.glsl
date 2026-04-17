// Pixel noise — filtered noise texture generator
// Independent H/V coherence and density control
// From starfields to buzzing grain to thrashing snow
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

// Fast hash — gritty, non-smooth, like analog avalanche noise
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Second independent hash for layering
float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 pixel = gl_FragCoord.xy;

    float speed = u_x3 * 2.0;
    float t = u_time * speed;

    // Quantize time to ~30fps intervals for analog noise character
    // Blend between frames for smoother motion at low speeds
    float frame = t * 30.0;
    float f0 = floor(frame);
    float fBlend = fract(frame);

    // Spatial coherence: how many "cells" across the screen
    // At 0: every pixel is independent (TV snow)
    // At 1: just a few cells (big bands/columns)
    float xCells = mix(u_resolution.x, 3.0, u_x0 * u_x0);
    float yCells = mix(u_resolution.y, 3.0, u_x1 * u_x1);

    // Quantize pixel position to cell grid
    float cx = floor(uv.x * xCells);
    float cy = floor(uv.y * yCells);

    // Two temporal frames for interpolation
    float n0 = hash(vec2(cx, cy) + f0 * 7.31);
    float n1 = hash(vec2(cx, cy) + (f0 + 1.0) * 7.31);
    float noise = mix(n0, n1, fBlend);

    // Layer a second noise at slightly different scale for richness
    float cx2 = floor(uv.x * xCells * 0.73 + 5.7);
    float cy2 = floor(uv.y * yCells * 0.73 + 3.1);
    float m0 = hash2(vec2(cx2, cy2) + f0 * 5.17);
    float m1 = hash2(vec2(cx2, cy2) + (f0 + 1.0) * 5.17);
    float noise2 = mix(m0, m1, fBlend);

    // Combine layers
    noise = noise * 0.6 + noise2 * 0.4;

    // Density control:
    // Low u_x2 = sparse starfield (high threshold, only brightest points)
    // Mid u_x2 = grainy texture
    // High u_x2 = full snow (everything visible)
    float density = u_x2;

    // Apply density curve
    // At low density: only values near 1.0 survive (starfield)
    // At high density: wide range visible (snow)
    float threshold = mix(0.75, 0.0, density);
    float softness = mix(0.12, 0.6, density);
    noise = smoothstep(threshold, threshold + softness, noise);

    // At low density, boost surviving pixels to full white (starfield)
    float boost = mix(2.5, 1.0, min(density * 3.0, 1.0));
    noise = min(noise * boost, 1.0);

    gl_FragColor = vec4(vec3(noise), 1.0);
}
