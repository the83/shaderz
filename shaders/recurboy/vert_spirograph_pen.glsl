// Spirograph pen — classic dense pen-line hypotrochoid for recurBOY (vertical)
// Analytical approach: solves whether the curve passes through each pixel
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

    float k = mix(3.0, 40.0, u_x0 * u_x0);
    float n = k - 1.0;
    float r = 1.0 / k;
    float a = 1.0 - r;
    float d = mix(0.1, 0.95, u_x1) * a;

    float aspect = u_resolution.y / u_resolution.x;
    float maxR = a + d;
    vec2 pos = (uv - 0.5) * 2.0 * maxR * 1.6;
    pos.x *= aspect;

    float ct = cos(t);
    float st = sin(t);
    vec2 rp = vec2(pos.x * ct + pos.y * st, -pos.x * st + pos.y * ct);

    float rho2 = rp.x * rp.x + rp.y * rp.y;
    float rho = sqrt(rho2 + 0.00001);
    float theta = atan(rp.y, rp.x);

    float c2 = (rho2 + a * a - d * d) / (2.0 * a * rho);
    float reachable = step(-1.0, c2) * step(c2, 1.0);

    float arcC = acos(clamp(c2, -1.0, 1.0));

    float a1 = theta + arcC;
    float cb1 = (rp.x - a * cos(a1)) / d;
    float sb1 = (a * sin(a1) - rp.y) / d;
    float cosD1 = cb1 * cos(n * a1) + sb1 * sin(n * a1);

    float a2 = theta - arcC;
    float cb2 = (rp.x - a * cos(a2)) / d;
    float sb2 = (a * sin(a2) - rp.y) / d;
    float cosD2 = cb2 * cos(n * a2) + sb2 * sin(n * a2);

    float maxCosD = max(cosD1, cosD2);
    float onCurve = step(0.998, maxCosD) * reachable;

    calcColors(u_x2);

    vec3 col = mix(vec3(0.0), g_c0, onCurve);
    gl_FragColor = vec4(col, 1.0);
}
