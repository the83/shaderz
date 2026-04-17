// Ballblazer arena — lite 1-bit dithered version for recurBOY
// Checkered floor, sky gradient, 4 random spheres, camera sway
//
// u_x0: forward speed
// u_x1: lateral sway amount
// u_x2: ink/paper color theme
// u_x3: overall speed

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

float h1f(float n) { return fract(sin(n) * 43758.5453); }
float h1v(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }

float snoise(float t) {
    float i = floor(t);
    float f = fract(t);
    f = f * f * (3.0 - 2.0 * f);
    return mix(h1f(i), h1f(i + 1.0), f);
}

float g_bestT;
vec3 g_bestN;
vec3 g_bestCol;
float g_hitObj;

void checkCell(vec2 ci, vec3 ro, vec3 rd) {
    if (h1v(ci) > 0.5) return;
    float ha = h1v(ci + vec2(7.3, 2.1));
    float hb = h1v(ci + vec2(1.7, 9.3));
    float hc = h1v(ci + vec2(4.1, 5.7));
    float hd = h1v(ci + vec2(8.9, 3.2));

    float ox = (ci.x + 0.15 + ha * 0.70) * 8.0;
    float oz = (ci.y + 0.15 + hb * 0.70) * 8.0;
    float sz = 0.4 + hc * 1.0;

    vec3 ctr = vec3(ox, sz, oz);
    vec3 oc = ro - ctr;
    float b = dot(oc, rd);
    float disc = b * b - dot(oc, oc) + sz * sz;
    if (disc < 0.0) return;
    float t = -b - sqrt(disc);
    if (t < 0.001 || t >= g_bestT) return;

    g_bestT = t;
    vec3 n = normalize(ro + rd * t - ctr);
    g_bestN = dot(n, rd) > 0.0 ? -n : n;
    g_bestCol = vec3(ha + 0.1, hb + 0.1, hd + 0.1);
    g_bestCol /= max(max(g_bestCol.r, g_bestCol.g), g_bestCol.b);
    g_hitObj = 1.0;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
    float asp = u_resolution.x / u_resolution.y;

    float speed = 0.5 + u_x3 * 2.5;
    float tm = u_time * speed;
    float fwd = 0.5 + u_x0 * 5.0;
    float sway = u_x1 * 4.0;

    float camZ = mod(tm * fwd, 200.0);
    float camX = (snoise(tm * 0.18) - 0.5) * 2.0 * sway
               + (snoise(tm * 0.07 + 13.7) - 0.5) * sway * 0.6;
    vec3 ro = vec3(camX, 0.9, camZ);

    vec2 ndc = (uv * 2.0 - 1.0) * vec2(asp, 1.0);
    vec3 rd = normalize(vec3(ndc.x, ndc.y + 0.25, 1.6));

    // Floor plane
    float tFloor = (rd.y < -0.0001) ? (ro.y / (-rd.y)) : -1.0;

    // Objects: 4 cells, spheres only
    g_bestT = tFloor > 0.0 ? tFloor : 1e6;
    g_bestN = vec3(0.0);
    g_bestCol = vec3(0.0);
    g_hitObj = 0.0;

    vec2 camCell = floor(vec2(camX, camZ) / 8.0);
    checkCell(camCell + vec2(0.0, 0.0), ro, rd);
    checkCell(camCell + vec2(1.0, 0.0), ro, rd);
    checkCell(camCell + vec2(0.0, 1.0), ro, rd);
    checkCell(camCell + vec2(1.0, 1.0), ro, rd);

    // Scene luminance
    float luma;
    if (g_hitObj > 0.5) {
        float shade = max(dot(g_bestN, normalize(vec3(0.4, 1.0, -0.3))), 0.0) * 0.75 + 0.25;
        luma = dot(g_bestCol * shade, vec3(0.299, 0.587, 0.114));
        float fog = clamp(1.0 - exp(-g_bestT * 0.013), 0.0, 1.0);
        luma = mix(luma, 0.0, fog);
    } else if (tFloor > 0.0) {
        vec3 hp = ro + rd * tFloor;
        float chk = step(0.0, sin(hp.x * 3.14159) * sin(hp.z * 3.14159));
        luma = chk < 0.5 ? 0.0 : 0.8;
        float fog = clamp(1.0 - exp(-tFloor * 0.014), 0.0, 1.0);
        luma = mix(luma, 0.0, fog);
        luma = mix(0.3, luma, clamp(tFloor * 0.35, 0.0, 1.0));
    } else {
        float s = clamp(rd.y * 2.5 + 0.5, 0.0, 1.0);
        luma = mix(0.3, 0.0, pow(s, 0.5));
    }

    // 4x4 Bayer dither
    vec2 p = mod(floor(gl_FragCoord.xy), 4.0);
    vec4 r0 = vec4( 0.0, 8.0, 2.0,10.0) / 16.0;
    vec4 r1 = vec4(12.0, 4.0,14.0, 6.0) / 16.0;
    vec4 r2 = vec4( 3.0,11.0, 1.0, 9.0) / 16.0;
    vec4 r3 = vec4(15.0, 7.0,13.0, 5.0) / 16.0;
    vec4 row = p.y<1.0 ? r0 : p.y<2.0 ? r1 : p.y<3.0 ? r2 : r3;
    float threshold = p.x<1.0 ? row.x : p.x<2.0 ? row.y : p.x<3.0 ? row.z : row.w;
    float bit = step(threshold, luma);

    // Ink/paper color pairs
    float pf = fract(u_x2) * 4.0;
    float pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));
    vec3 ink0=vec3(0.0), ink1=vec3(0.0), ink2=vec3(0.0), ink3=vec3(0.05,0.05,0.18);
    vec3 pap0=vec3(1.0), pap1=vec3(0.15,0.95,0.25), pap2=vec3(1.0,0.72,0.0), pap3=vec3(0.55,0.75,1.0);
    vec3 ink = pi<0.5 ? mix(ink0,ink1,pt) : pi<1.5 ? mix(ink1,ink2,pt) : pi<2.5 ? mix(ink2,ink3,pt) : mix(ink3,ink0,pt);
    vec3 paper = pi<0.5 ? mix(pap0,pap1,pt) : pi<1.5 ? mix(pap1,pap2,pt) : pi<2.5 ? mix(pap2,pap3,pt) : mix(pap3,pap0,pt);

    vec3 out_color = mix(ink, paper, bit);
    out_color *= mod(gl_FragCoord.y, 2.0) < 1.0 ? 0.82 : 1.0;
    gl_FragColor = vec4(out_color, 1.0);
}
