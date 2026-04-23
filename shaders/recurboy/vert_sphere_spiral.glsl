// Spherical spiral — loxodrome on a rotating sphere for recurBOY (vertical)
//
// u_x0: winding density (2 to 25 wraps)
// u_x1: camera tilt (equator to pole view)
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
    float t = u_time * speedKnob * 0.4;

    float a = mix(2.0, 25.0, u_x0);
    float tilt = mix(-1.2, 1.2, u_x1);
    float ct = cos(tilt);
    float st = sin(tilt);

    float aspect = u_resolution.y / u_resolution.x;
    vec2 pos = (uv - 0.5) * 3.6;
    pos.x *= aspect;

    float r2 = pos.x * pos.x + pos.y * pos.y;
    float onSphere = 1.0 - step(1.0, r2);
    float zf = sqrt(max(1.0 - r2, 0.001));

    float fy = ct * pos.y - st * zf;
    float fz = st * pos.y + ct * zf;
    float phi_f = asin(clamp(fy, -0.999, 0.999));
    float theta_f = atan(pos.x, fz) + t;
    float cosD_f = cos(theta_f - a * phi_f);

    float by = ct * pos.y + st * zf;
    float bz = st * pos.y - ct * zf;
    float phi_b = asin(clamp(by, -0.999, 0.999));
    float theta_b = atan(pos.x, bz) + t;
    float cosD_b = cos(theta_b - a * phi_b);

    float lineThresh = 0.99;
    float onFront = step(lineThresh, cosD_f);
    float onBack = step(lineThresh, cosD_b);

    float shade_f = 0.5 + 0.5 * zf;
    float shade_b = 0.25 + 0.15 * zf;

    calcColors(u_x2);

    vec3 col = vec3(0.0);
    col = mix(col, g_c1 * shade_b, onBack * onSphere);
    col = mix(col, g_c0 * shade_f, onFront * onSphere);

    float edge = smoothstep(0.92, 1.0, sqrt(r2)) * onSphere;
    col += g_c2 * edge * 0.4;

    gl_FragColor = vec4(col, 1.0);
}
