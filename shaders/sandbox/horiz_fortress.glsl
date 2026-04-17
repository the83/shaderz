// LZX Fortress clone — 3-bit digital video pattern generator
// Quantized oscillators combined through logic operations
// Inspired by early digital video art and arcade graphics aesthetics
//
// u_x0: pattern mode (0..1 sweeps 8 logic combinator modes)
// u_x1: LFO frequency
// u_x2: color palette (16 palettes)
// u_x3: animation speed / phase scroll

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

// Quantize to 3-bit (8 levels, values 0..7 mapped to 0..1)
float q3(float v) {
    return floor(clamp(v, 0.0, 1.0) * 7.0 + 0.5) / 7.0;
}

// Extract bit n (0,1,2) from a 3-bit value (0..7)
float bit(float val, float n) {
    float v = floor(val * 7.0 + 0.5);
    // bit 0: mod 2, bit 1: mod 4 / 2, bit 2: mod 8 / 4
    return mod(floor(v / (n < 0.5 ? 1.0 : n < 1.5 ? 2.0 : 4.0)), 2.0);
}

// 3-bit bitwise XOR
float xor3(float a, float b) {
    float r = 0.0;
    r += abs(bit(a, 0.0) - bit(b, 0.0));
    r += abs(bit(a, 1.0) - bit(b, 1.0)) * 2.0;
    r += abs(bit(a, 2.0) - bit(b, 2.0)) * 4.0;
    return r / 7.0;
}

// 3-bit bitwise AND
float and3(float a, float b) {
    float r = 0.0;
    r += bit(a, 0.0) * bit(b, 0.0);
    r += bit(a, 1.0) * bit(b, 1.0) * 2.0;
    r += bit(a, 2.0) * bit(b, 2.0) * 4.0;
    return r / 7.0;
}

// 3-bit bitwise OR
float or3(float a, float b) {
    float r = 0.0;
    r += min(bit(a, 0.0) + bit(b, 0.0), 1.0);
    r += min(bit(a, 1.0) + bit(b, 1.0), 1.0) * 2.0;
    r += min(bit(a, 2.0) + bit(b, 2.0), 1.0) * 4.0;
    return r / 7.0;
}

// 3-bit bitwise NAND
float nand3(float a, float b) {
    return xor3(and3(a, b), 1.0);
}

// 3-bit bitwise XNOR
float xnor3(float a, float b) {
    return xor3(xor3(a, b), 1.0);
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

// --- Color palettes ---
// Maps 3-bit value (0-7) through 16 selectable color palettes
// Each palette defines 8 RGB colors using 3-bit-per-channel (9-bit RGB) aesthetics

vec3 palette(float val, float sel) {
    float idx = floor(val * 7.0 + 0.5); // 0..7
    float p = floor(sel * 15.99);        // 0..15

    vec3 col;

    if (p < 1.0) {
        // 0: Warm ramp — black → red → orange → yellow → white
        float r = min(idx / 3.0, 1.0);
        float g = max(0.0, (idx - 3.0) / 4.0);
        float b = max(0.0, (idx - 6.0));
        col = vec3(r, g, b);
    } else if (p < 2.0) {
        // 1: Cool ramp — black → blue → cyan → white
        float r = max(0.0, (idx - 5.0) / 2.0);
        float g = max(0.0, (idx - 2.0) / 5.0);
        float b = min(idx / 3.0, 1.0);
        col = vec3(r, g, b);
    } else if (p < 3.0) {
        // 2: CGA palette — classic 8-color RGB bit-mapping
        col = vec3(bit(val, 0.0), bit(val, 1.0), bit(val, 2.0));
    } else if (p < 4.0) {
        // 3: Phosphor green — black → green monochrome
        float v = idx / 7.0;
        col = vec3(v * 0.2, v, v * 0.3);
    } else if (p < 5.0) {
        // 4: Synthwave — purple → magenta → pink → hot
        float r = 0.2 + idx / 9.0;
        float g = max(0.0, (idx - 4.0) / 6.0);
        float b = max(0.0, 0.8 - idx / 10.0);
        col = vec3(r, g, b);
    } else if (p < 6.0) {
        // 5: Inverse CGA — complementary bit mapping
        col = vec3(1.0 - bit(val, 2.0), 1.0 - bit(val, 0.0), 1.0 - bit(val, 1.0));
    } else if (p < 7.0) {
        // 6: Amber — black → amber monochrome
        float v = idx / 7.0;
        col = vec3(v, v * 0.6, v * 0.1);
    } else if (p < 8.0) {
        // 7: High contrast — black/white with color accents
        col = vec3(
            bit(val, 0.0) * 0.9 + bit(val, 2.0) * 0.1,
            bit(val, 1.0) * 0.9 + bit(val, 2.0) * 0.1,
            bit(val, 2.0)
        );
    } else if (p < 9.0) {
        // 8: Thermal — black → blue → magenta → red → yellow → white
        float r = smoothstep(2.0, 5.0, idx);
        float g = smoothstep(5.0, 7.0, idx);
        float b = smoothstep(0.0, 3.0, idx) - smoothstep(5.0, 7.0, idx);
        col = vec3(r, g, b);
    } else if (p < 10.0) {
        // 9: Ocean — deep navy → teal → seafoam → white
        float r = max(0.0, (idx - 5.0) / 3.0);
        float g = smoothstep(1.0, 6.0, idx);
        float b = 0.15 + idx / 9.0;
        col = vec3(r, g, b);
    } else if (p < 11.0) {
        // 10: Gameboy — dark olive → green → lime → lightest
        float v = idx / 7.0;
        col = vec3(v * 0.5, 0.2 + v * 0.6, v * 0.25);
    } else if (p < 12.0) {
        // 11: Grayscale
        float v = idx / 7.0;
        col = vec3(v);
    } else if (p < 13.0) {
        // 12: Neon — black → hot pink → cyan → white
        float r = smoothstep(0.0, 3.0, idx) - smoothstep(4.0, 6.0, idx) + smoothstep(6.0, 7.0, idx);
        float g = smoothstep(3.0, 6.0, idx);
        float b = smoothstep(1.0, 4.0, idx);
        col = vec3(r, g, b);
    } else if (p < 14.0) {
        // 13: Sunset — deep purple → red → orange → gold
        float r = smoothstep(1.0, 4.0, idx);
        float g = smoothstep(4.0, 7.0, idx) * 0.8;
        float b = smoothstep(0.0, 2.0, idx) - smoothstep(3.0, 6.0, idx);
        col = vec3(r, g, b);
    } else if (p < 15.0) {
        // 14: Sepia — dark brown → tan → cream
        float v = idx / 7.0;
        col = vec3(0.15 + v * 0.7, 0.1 + v * 0.55, 0.05 + v * 0.35);
    } else {
        // 15: Pastel — soft candy colors via offset bit mapping
        col = vec3(
            0.4 + bit(val, 0.0) * 0.4 + bit(val, 2.0) * 0.2,
            0.4 + bit(val, 1.0) * 0.4 + bit(val, 0.0) * 0.2,
            0.4 + bit(val, 2.0) * 0.4 + bit(val, 1.0) * 0.2
        );
    }

    // Quantize output to 3-bit per channel (9-bit RGB)
    return floor(col * 7.0 + 0.5) / 7.0;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float speed = u_x3 * 2.0;
    float t = u_time * speed;

    // --- LFO oscillator (spatial — varies across screen) ---
    float lfoFreq = mix(0.02, 1.0, u_x1 * u_x1);
    float lfoPhase = t * lfoFreq + uv.x * 0.5 + uv.y * 0.3;
    float lfoRaw = fract(lfoPhase);
    float lfo    = q3(lfoRaw);
    float lfoTri = q3(abs(2.0 * lfoRaw - 1.0));

    // --- LFO frequency-modulates the H/V oscillators ---
    // Pattern density breathes over time instead of just scrolling
    float hFreq = 4.0 + lfoTri * 7.0 * 2.0; // breathe between 4 and ~18
    float vFreq = 3.0 + lfo    * 7.0 * 1.5; // breathe between 3 and ~13

    // Horizontal oscillator
    float hPhase = uv.x * hFreq + t * 0.15;
    float hRamp = q3(fract(hPhase));
    float hTri  = q3(abs(2.0 * fract(hPhase) - 1.0));

    // Vertical oscillator (cross-modulated by H output for diagonal warping)
    float vPhase = uv.y * vFreq + t * 0.11 + hRamp * 0.4;
    float vRamp = q3(fract(vPhase));
    float vTri  = q3(abs(2.0 * fract(vPhase) - 1.0));

    // --- Pattern mode selection ---
    // u_x0 (0..1) selects among 8 logic combinator modes
    float mode = floor(u_x0 * 7.99);

    float val;

    if (mode < 1.0) {
        // XOR ramps — classic digital moire / quilt pattern
        val = xor3(hRamp, vRamp);
    } else if (mode < 2.0) {
        // XOR triangles — diamond lattice
        val = xor3(hTri, vTri);
    } else if (mode < 3.0) {
        // AND ramps + LFO — pulsing grid, bars appear/disappear
        val = and3(add3(hRamp, lfo), vRamp);
    } else if (mode < 4.0) {
        // ADD ramps — diagonal staircase
        val = add3(hRamp, vRamp);
    } else if (mode < 5.0) {
        // SUB triangles — shifting interference
        val = sub3(hTri, add3(vTri, lfoTri));
    } else if (mode < 6.0) {
        // NAND triangles + ramps — inverted logic textures
        val = nand3(hTri, vRamp);
    } else if (mode < 7.0) {
        // XNOR ramps + LFO — scrolling complementary moire
        val = xnor3(add3(hRamp, lfo), vRamp);
    } else {
        // Complex: XOR of (ADD H+LFO) with (SUB V-LFO) — morphing kaleidoscope
        val = xor3(add3(hRamp, lfo), sub3(vTri, lfoTri));
    }

    vec3 col = palette(val, u_x2);
    gl_FragColor = vec4(col, 1.0);
}
