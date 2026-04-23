// Julia set fractal — real-time animated Julia sets for recurBOY
// c parameter orbits through interesting regions; knobs bias the orbit center
//
// u_x0: real part of c bias (shifts orbit center horizontally)
// u_x1: imaginary part of c bias (shifts orbit center vertically)
// u_x2: color palette (13 palettes)
// u_x3: speed (center = stopped/manual, left = reverse, right = forward)

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
    float speed = speedKnob * 0.4;
    float t = u_time * speed;

    // Map knobs to c bias range [-1, 1]
    float biasR = (u_x0 - 0.5) * 2.0;
    float biasI = (u_x1 - 0.5) * 2.0;

    // Orbit through interesting c values using Lissajous path
    float cr = sin(t * 0.7) * 0.7885 * cos(t * 0.13);
    float ci = cos(t * 0.5) * 0.7885 * sin(t * 0.11);

    // Blend: near center = manual control, away from center = orbit with knob bias
    float absSpeed = abs(speedKnob);
    float manual = step(absSpeed, 0.05);
    cr = mix(cr + biasR * 0.3, biasR * 0.8, manual);
    ci = mix(ci + biasI * 0.3, biasI * 0.8, manual);

    // Map pixel to complex plane [-1.5, 1.5]
    float aspect = u_resolution.x / u_resolution.y;
    float zr = (uv.x - 0.5) * 3.0 * aspect;
    float zi = (uv.y - 0.5) * 3.0;

    // Iterate z = z^2 + c
    float iter = 0.0;
    float maxIter = 24.0;
    float escaped = 0.0;

    for (float i = 0.0; i < 24.0; i += 1.0) {
        if (escaped < 0.5) {
            float zr2 = zr * zr - zi * zi + cr;
            float zi2 = 2.0 * zr * zi + ci;
            zr = zr2;
            zi = zi2;
            float mag = zr * zr + zi * zi;
            if (mag > 4.0) {
                escaped = 1.0;
                iter = i;
            }
        }
    }

    // Smooth iteration count for nice gradients
    float smoothIter = iter;
    if (escaped > 0.5) {
        float mag = sqrt(zr * zr + zi * zi);
        smoothIter = iter - log(log(mag) / log(2.0)) / log(2.0);
    }

    calcColors(u_x2);

    // Color the fractal
    vec3 col = vec3(0.0);
    if (escaped > 0.5) {
        float f = smoothIter / maxIter;
        float band = f * 3.0;
        float lo = fract(band);
        float idx = floor(band);

        if (idx < 1.0) {
            col = mix(g_c2, g_c1, lo);
        } else if (idx < 2.0) {
            col = mix(g_c1, g_c0, lo);
        } else {
            col = mix(g_c0, vec3(1.0), lo);
        }
    }

    gl_FragColor = vec4(col, 1.0);
}
