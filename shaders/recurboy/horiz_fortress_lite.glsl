// LZX Fortress clone — lite version for recurBOY
// 3-bit digital pattern generator: quantized oscillators + logic combinators
//
// u_x0: pattern mode (0..1 sweeps 6 logic combinator modes)
// u_x1: LFO frequency
// u_x2: color palette (8 palettes)
// u_x3: animation speed / phase scroll

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

// Quantize to 3-bit (8 levels)
float q3(float v) {
    return floor(clamp(v, 0.0, 1.0) * 7.0 + 0.5) / 7.0;
}

// Extract bit n (0,1,2) from 3-bit value — no ternary, Pi-safe
float gbit(float val, float n) {
    float v = floor(val * 7.0 + 0.5);
    // divisor: 1.0 for bit0, 2.0 for bit1, 4.0 for bit2
    float d = 1.0 + step(0.5, n) * 1.0 + step(1.5, n) * 2.0;
    return mod(floor(v / d), 2.0);
}

// 3-bit XOR
float xor3(float a, float b) {
    float r = 0.0;
    r += abs(gbit(a, 0.0) - gbit(b, 0.0));
    r += abs(gbit(a, 1.0) - gbit(b, 1.0)) * 2.0;
    r += abs(gbit(a, 2.0) - gbit(b, 2.0)) * 4.0;
    return r / 7.0;
}

// 3-bit AND
float and3(float a, float b) {
    float r = 0.0;
    r += gbit(a, 0.0) * gbit(b, 0.0);
    r += gbit(a, 1.0) * gbit(b, 1.0) * 2.0;
    r += gbit(a, 2.0) * gbit(b, 2.0) * 4.0;
    return r / 7.0;
}

// 3-bit NAND
float nand3(float a, float b) {
    return xor3(and3(a, b), 1.0);
}

// 3-bit wrapping ADD
float add3(float a, float b) {
    float ia = floor(a * 7.0 + 0.5);
    float ib = floor(b * 7.0 + 0.5);
    return mod(ia + ib, 8.0) / 7.0;
}

// 3-bit wrapping SUB
float sub3(float a, float b) {
    float ia = floor(a * 7.0 + 0.5);
    float ib = floor(b * 7.0 + 0.5);
    return mod(ia - ib + 8.0, 8.0) / 7.0;
}

// 4 color palettes — reduced from 8 for Pi performance
vec3 pal(float val, float sel) {
    float idx = floor(val * 7.0 + 0.5);
    float p = floor(sel * 7.99);

    vec3 col;

    if (p < 1.0) {
        // Warm: black → red → yellow → white
        float r = min(idx / 3.0, 1.0);
        float g = max(0.0, (idx - 3.0) / 4.0);
        float bl = max(0.0, (idx - 6.0));
        col = vec3(r, g, bl);
    } else if (p < 2.0) {
        // Cool: black → blue → cyan → white
        float r = max(0.0, (idx - 5.0) / 2.0);
        float g = max(0.0, (idx - 2.0) / 5.0);
        float bl = min(idx / 3.0, 1.0);
        col = vec3(r, g, bl);
    } else if (p < 3.0) {
        // CGA: direct bit-to-channel mapping
        col = vec3(gbit(val, 0.0), gbit(val, 1.0), gbit(val, 2.0));
    } else if (p < 4.0) {
        // Phosphor green
        float v = idx / 7.0;
        col = vec3(v * 0.2, v, v * 0.3);
    } else if (p < 5.0) {
        // Amber
        float v = idx / 7.0;
        col = vec3(v, v * 0.6, v * 0.1);
    } else if (p < 6.0) {
        // Grayscale
        float v = idx / 7.0;
        col = vec3(v);
    } else if (p < 7.0) {
        // Sunset: purple → red → orange → gold
        float r = min((idx + 1.0) / 4.0, 1.0);
        float g = max(0.0, (idx - 4.0) / 4.0) * 0.8;
        float bl = max(0.0, 1.0 - idx / 3.0) * 0.6;
        col = vec3(r, g, bl);
    } else {
        // Inverse CGA
        col = vec3(1.0 - gbit(val, 2.0), 1.0 - gbit(val, 0.0), 1.0 - gbit(val, 1.0));
    }

    return floor(col * 7.0 + 0.5) / 7.0;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;

    float speed = u_x3 * 1.5;
    float t = u_time * speed;

    // LFO — spatial, varies across screen
    float lfoFreq = mix(0.02, 1.0, u_x1 * u_x1);
    float lfoPhase = t * lfoFreq + uv.x * 0.5 + uv.y * 0.3;
    float lfoRaw = fract(lfoPhase);
    float lfo    = q3(lfoRaw);
    float lfoTri = q3(abs(2.0 * lfoRaw - 1.0));

    // LFO frequency-modulates H/V oscillators
    float hFreq = 4.0 + lfoTri * 7.0 * 2.0;
    float vFreq = 3.0 + lfo    * 7.0 * 1.5;

    // Horizontal oscillator
    float hPhase = uv.x * hFreq + t * 0.15;
    float hRamp = q3(fract(hPhase));
    float hTri  = q3(abs(2.0 * fract(hPhase) - 1.0));

    // Vertical oscillator (cross-modulated by H)
    float vPhase = uv.y * vFreq + t * 0.11 + hRamp * 0.4;
    float vRamp = q3(fract(vPhase));
    float vTri  = q3(abs(2.0 * fract(vPhase) - 1.0));

    // 6 pattern modes (reduced from 8 for Pi)
    float mode = floor(u_x0 * 5.99);

    float val;

    if (mode < 1.0) {
        val = xor3(hRamp, vRamp);
    } else if (mode < 2.0) {
        val = xor3(hTri, vTri);
    } else if (mode < 3.0) {
        val = and3(add3(hRamp, lfo), vRamp);
    } else if (mode < 4.0) {
        val = add3(hRamp, vRamp);
    } else if (mode < 5.0) {
        val = nand3(hTri, vRamp);
    } else {
        val = xor3(add3(hRamp, lfo), sub3(vTri, lfo));
    }

    vec3 col = pal(val, u_x2);
    gl_FragColor = vec4(col, 1.0);
}
