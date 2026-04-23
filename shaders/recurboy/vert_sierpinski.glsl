// Sierpiński triangle — iterated fractal subdivision for recurBOY (vertical)
//
// u_x0: zoom level
// u_x1: fractal detail / iteration depth (1 to 8)
// u_x2: color palette (13 palettes)
// u_x3: speed (center = stopped, bipolar rotation)

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
        g_c0 = vec3(1.0);
        g_c1 = vec3(0.5);
        g_c2 = vec3(0.0);
    } else if (p < 2.0) {
        g_c0 = vec3(1.0, 0.0, 0.0);
        g_c1 = vec3(0.0, 1.0, 0.0);
        g_c2 = vec3(0.0, 0.0, 1.0);
    } else if (p < 3.0) {
        g_c0 = vec3(1.0, 0.75, 0.0);
        g_c1 = vec3(1.0, 0.25, 0.0);
        g_c2 = vec3(0.57, 0.0, 0.0);
    } else if (p < 4.0) {
        g_c0 = vec3(0.43, 0.71, 1.0);
        g_c1 = vec3(0.0, 0.29, 1.0);
        g_c2 = vec3(0.0, 0.0, 0.57);
    } else if (p < 5.0) {
        g_c0 = vec3(0.0, 0.86, 0.71);
        g_c1 = vec3(1.0, 0.43, 0.57);
        g_c2 = vec3(0.14, 0.29, 0.57);
    } else if (p < 6.0) {
        g_c0 = vec3(0.17, 0.86, 0.26);
        g_c1 = vec3(0.11, 0.57, 0.17);
        g_c2 = vec3(0.06, 0.29, 0.09);
    } else if (p < 7.0) {
        g_c0 = vec3(0.86, 0.29, 0.14);
        g_c1 = vec3(0.57, 0.0, 0.43);
        g_c2 = vec3(0.43, 0.0, 0.57);
    } else if (p < 8.0) {
        g_c0 = vec3(1.0, 0.71, 0.0);
        g_c1 = vec3(0.86, 0.14, 0.14);
        g_c2 = vec3(0.43, 0.0, 0.43);
    } else if (p < 9.0) {
        g_c0 = vec3(0.0, 1.0, 1.0);
        g_c1 = vec3(1.0, 0.0, 0.71);
        g_c2 = vec3(0.43, 0.0, 0.71);
    } else if (p < 10.0) {
        g_c0 = vec3(0.85, 0.95, 1.0);
        g_c1 = vec3(0.4, 0.7, 0.9);
        g_c2 = vec3(0.05, 0.15, 0.4);
    } else if (p < 11.0) {
        g_c0 = vec3(1.0, 1.0, 0.4);
        g_c1 = vec3(1.0, 0.4, 0.0);
        g_c2 = vec3(0.4, 0.0, 0.0);
    } else if (p < 12.0) {
        g_c0 = vec3(0.95, 0.6, 0.9);
        g_c1 = vec3(0.5, 0.8, 1.0);
        g_c2 = vec3(0.3, 0.2, 0.6);
    } else {
        g_c0 = vec3(0.85, 0.75, 0.45);
        g_c1 = vec3(0.45, 0.55, 0.25);
        g_c2 = vec3(0.25, 0.15, 0.05);
    }
}

void main(void) {
    vec2 rawUV = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
    vec2 uv = vec2(rawUV.y, 1.0 - rawUV.x);

    float speedKnob = (u_x3 - 0.5) * 2.0;
    float t = u_time * speedKnob * 0.3;

    float zoom = mix(8.0, 0.3, u_x0 * u_x0);
    float maxDepth = floor(mix(1.0, 8.0, u_x1));

    float aspect = u_resolution.y / u_resolution.x;
    vec2 pos = (uv - 0.5) * 2.0;
    pos.x *= aspect;

    float cr = cos(t);
    float sr = sin(t);
    pos = vec2(cr * pos.x - sr * pos.y, sr * pos.x + cr * pos.y);

    pos *= zoom;

    float x = pos.x - pos.y * 0.57735 + 0.5;
    float y = pos.y * 1.1547 + 0.333;

    x = mod(x, 2.0);
    y = mod(y, 2.0);
    x = abs(x - 1.0);
    y = abs(y - 1.0);

    float flip = step(1.0, x + y);
    x = mix(x, 1.0 - x, flip);
    y = mix(y, 1.0 - y, flip);

    float inSet = 1.0;
    float level = 8.0;

    for (float i = 0.0; i < 8.0; i += 1.0) {
        float active = step(i + 0.5, maxDepth) * step(0.5, inSet);

        x *= 2.0;
        y *= 2.0;

        float hx = step(1.0, x);
        float hy = step(1.0, y);
        float hole = step(1.0, x + y) * (1.0 - hx) * (1.0 - hy) * active;

        level = mix(level, i, hole * step(7.5, level));
        inSet *= 1.0 - hole;

        x -= hx;
        y -= hy;
    }

    calcColors(u_x2);

    vec3 col = vec3(0.0);
    if (inSet > 0.5) {
        float grad = x * 0.5 + y * 0.5;
        col = mix(g_c1, g_c0, grad);
    } else {
        float f = level / 8.0;
        col = g_c2 * f * 0.3;
    }

    gl_FragColor = vec4(col, 1.0);
}
