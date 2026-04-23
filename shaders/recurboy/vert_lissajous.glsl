// Lissajous figures — analytical pen-line rendering for recurBOY (vertical)
//
// u_x0: a frequency (1 to 7, controls horizontal complexity)
// u_x1: b frequency (1 to 4, controls vertical complexity)
// u_x2: color palette (13 palettes)
// u_x3: speed / phase animation (center = stopped, bipolar)

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
    float delta = u_time * speedKnob * 0.5;

    float a = mix(1.0, 7.0, u_x0);
    float b = mix(1.0, 4.0, u_x1);

    float aspect = u_resolution.y / u_resolution.x;
    float px = (uv.x - 0.5) * 2.2 * aspect;
    float py = (uv.y - 0.5) * 2.2;

    float inRange = step(abs(py), 0.999);
    float asinPy = asin(clamp(py, -0.999, 0.999));

    float onCurve = 0.0;
    float lineW = 0.025;

    for (float k = 0.0; k < 8.0; k += 1.0) {
        float signK = 1.0 - 2.0 * mod(k, 2.0);
        float tk = (signK * asinPy + 3.14159 * k) / b;
        float xk = sin(a * tk + delta);
        float diff = abs(xk - px);
        onCurve = max(onCurve, 1.0 - step(lineW, diff));
    }

    onCurve *= inRange;

    calcColors(u_x2);

    vec3 col = g_c0 * onCurve;
    gl_FragColor = vec4(col, 1.0);
}
