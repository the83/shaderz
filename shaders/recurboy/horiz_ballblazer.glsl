// Ballblazer arena — lite version for recurBOY
// Checkered floor, sky gradient, 4 random spheres, camera sway
//
// u_x0: forward speed
// u_x1: lateral sway amount
// u_x2: color palette (cycles through 4)
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

    // Palette
    float pf = fract(u_x2) * 4.0;
    float pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));

    vec3 fa0=vec3(0.0), fa1=vec3(0.06,0.0,0.0),
         fa2=vec3(0.0,0.02,0.08), fa3=vec3(0.0);
    vec3 fb0=vec3(1.0,0.72,0.08), fb1=vec3(1.0,0.40,0.02),
         fb2=vec3(0.75,0.95,1.0), fb3=vec3(0.20,1.0,0.10);
    vec3 sh0=vec3(0.05,0.30,0.80), sh1=vec3(0.55,0.08,0.02),
         sh2=vec3(0.0,0.65,0.85), sh3=vec3(0.55,0.0,0.80);
    vec3 st0=vec3(0.01,0.0,0.04), st1=vec3(0.04,0.0,0.0),
         st2=vec3(0.0,0.01,0.08), st3=vec3(0.04,0.0,0.06);
    vec3 fg0=vec3(0.03,0.18,0.50), fg1=vec3(0.25,0.04,0.02),
         fg2=vec3(0.0,0.30,0.45), fg3=vec3(0.22,0.0,0.35);
    vec3 glow0=vec3(0.10,0.50,1.0), glow1=vec3(1.0,0.30,0.05),
         glow2=vec3(0.0,0.90,1.0), glow3=vec3(0.90,0.10,1.0);

    vec3 floorA = pi<0.5 ? mix(fa0,fa1,pt) : pi<1.5 ? mix(fa1,fa2,pt) : pi<2.5 ? mix(fa2,fa3,pt) : mix(fa3,fa0,pt);
    vec3 floorB = pi<0.5 ? mix(fb0,fb1,pt) : pi<1.5 ? mix(fb1,fb2,pt) : pi<2.5 ? mix(fb2,fb3,pt) : mix(fb3,fb0,pt);
    vec3 skyHoriz = pi<0.5 ? mix(sh0,sh1,pt) : pi<1.5 ? mix(sh1,sh2,pt) : pi<2.5 ? mix(sh2,sh3,pt) : mix(sh3,sh0,pt);
    vec3 skyTop = pi<0.5 ? mix(st0,st1,pt) : pi<1.5 ? mix(st1,st2,pt) : pi<2.5 ? mix(st2,st3,pt) : mix(st3,st0,pt);
    vec3 fogCol = pi<0.5 ? mix(fg0,fg1,pt) : pi<1.5 ? mix(fg1,fg2,pt) : pi<2.5 ? mix(fg2,fg3,pt) : mix(fg3,fg0,pt);
    vec3 glowCol = pi<0.5 ? mix(glow0,glow1,pt) : pi<1.5 ? mix(glow1,glow2,pt) : pi<2.5 ? mix(glow2,glow3,pt) : mix(glow3,glow0,pt);

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

    // Shading
    vec3 color;
    if (g_hitObj > 0.5) {
        float shade = max(dot(g_bestN, normalize(vec3(0.4, 1.0, -0.3))), 0.0) * 0.75 + 0.25;
        color = g_bestCol * shade;
        float fog = clamp(1.0 - exp(-g_bestT * 0.013), 0.0, 1.0);
        color = mix(color, fogCol, fog);
    } else if (tFloor > 0.0) {
        vec3 hp = ro + rd * tFloor;
        float chk = step(0.0, sin(hp.x * 3.14159) * sin(hp.z * 3.14159));
        color = chk < 0.5 ? floorA : floorB;
        float fog = clamp(1.0 - exp(-tFloor * 0.014), 0.0, 1.0);
        color = mix(color, fogCol, fog);
        color = mix(skyHoriz, color, clamp(tFloor * 0.35, 0.0, 1.0));
    } else {
        float s = clamp(rd.y * 2.5 + 0.5, 0.0, 1.0);
        color = mix(skyHoriz, skyTop, pow(s, 0.5));
        color += glowCol * exp(-s * 8.0) * 0.35;
    }

    color *= mod(gl_FragCoord.y, 2.0) < 1.0 ? 0.82 : 1.0;
    gl_FragColor = vec4(color, 1.0);
}
