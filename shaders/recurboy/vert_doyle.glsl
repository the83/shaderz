// Doyle spiral — circle packing in log-polar space for recurBOY (vertical)
//
// u_x0: circles per ring (3 to 10)
// u_x1: spiral twist amount
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

    float N = floor(mix(3.0, 10.0, u_x0));
    float twist = mix(0.2, 2.5, u_x1);

    float aspect = u_resolution.y / u_resolution.x;
    vec2 pos = (uv - 0.5) * 2.0;
    pos.x *= aspect;

    float r = length(pos);
    float theta = atan(pos.y, pos.x) + t;
    float lr = log(max(r, 0.0001));

    float h = 6.2832 / N;
    float circR2 = h * h * 0.18;

    float mf = lr / h;
    float m0 = floor(mf);
    float m1 = m0 + 1.0;

    float minDist = 100.0;
    float bestM = 0.0;
    float bestN = 0.0;

    float lr0 = m0 * h;
    float toff0 = m0 * twist;
    float n00 = floor((theta - toff0) / h);
    float dlr0 = lr - lr0;

    float dth = theta - (n00 * h + toff0);
    dth = dth - 6.2832 * floor(dth / 6.2832 + 0.5);
    float dist = dlr0 * dlr0 + dth * dth;
    float closer = step(dist, minDist);
    minDist = mix(minDist, dist, closer);
    bestM = mix(bestM, m0, closer);
    bestN = mix(bestN, n00, closer);

    dth = theta - ((n00 + 1.0) * h + toff0);
    dth = dth - 6.2832 * floor(dth / 6.2832 + 0.5);
    dist = dlr0 * dlr0 + dth * dth;
    closer = step(dist, minDist);
    minDist = mix(minDist, dist, closer);
    bestM = mix(bestM, m0, closer);
    bestN = mix(bestN, n00 + 1.0, closer);

    float lr1 = m1 * h;
    float toff1 = m1 * twist;
    float n10 = floor((theta - toff1) / h);
    float dlr1 = lr - lr1;

    dth = theta - (n10 * h + toff1);
    dth = dth - 6.2832 * floor(dth / 6.2832 + 0.5);
    dist = dlr1 * dlr1 + dth * dth;
    closer = step(dist, minDist);
    minDist = mix(minDist, dist, closer);
    bestM = mix(bestM, m1, closer);
    bestN = mix(bestN, n10, closer);

    dth = theta - ((n10 + 1.0) * h + toff1);
    dth = dth - 6.2832 * floor(dth / 6.2832 + 0.5);
    dist = dlr1 * dlr1 + dth * dth;
    closer = step(dist, minDist);
    minDist = mix(minDist, dist, closer);
    bestM = mix(bestM, m1, closer);
    bestN = mix(bestN, n10 + 1.0, closer);

    float inCircle = 1.0 - step(circR2, minDist);
    float shade = (1.0 - sqrt(minDist / circR2) * 0.3) * inCircle;

    calcColors(u_x2);

    float f = fract((bestM + bestN * 0.618) * 0.5);
    vec3 baseCol = mix(g_c2, g_c1, clamp(f * 2.0, 0.0, 1.0));
    baseCol = mix(baseCol, g_c0, clamp(f * 2.0 - 1.0, 0.0, 1.0));

    vec3 col = baseCol * shade;
    gl_FragColor = vec4(col, 1.0);
}
