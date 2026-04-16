// gen-shader
// Wetblazer: Ballblazer-style arena with a watery reflective floor (lite for RPi)
// u_x0: forward speed
// u_x1: lateral sway amount
// u_x2: color palette (cycles through 4 palettes)
// u_x3: overall speed

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

// --- Hashing / noise ---
float h1f(float n) { return fract(sin(n) * 43758.5453); }
float h1v(vec2 v)  { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }

float snoise(float t) {
    float i = floor(t), f = fract(t);
    f = f*f*(3.0-2.0*f);
    return mix(h1f(i), h1f(i+1.0), f);
}

// 2D value noise
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(
        mix(h1v(i+vec2(0,0)), h1v(i+vec2(1,0)), f.x),
        mix(h1v(i+vec2(0,1)), h1v(i+vec2(1,1)), f.x),
        f.y);
}

// Simplified water normal: single noise layer
vec2 waterNormal(vec2 p, float t) {
    float eps = 0.06;
    float h0  = vnoise(p*0.40 + vec2( t*0.30,  t*0.17));
    float h0x = vnoise((p+vec2(eps,0))*0.40 + vec2( t*0.30,  t*0.17));
    float h0z = vnoise((p+vec2(0,eps))*0.40 + vec2( t*0.30,  t*0.17));

    float dx = (h0x-h0);
    float dz = (h0z-h0);
    return vec2(dx, dz) / eps;
}

// --- Geometry intersections ---
float iSphere(vec3 ro, vec3 rd, vec3 c, float r) {
    vec3 oc = ro - c;
    float b = dot(oc, rd), disc = b*b - dot(oc,oc) + r*r;
    if (disc < 0.0) return -1.0;
    float t = -b - sqrt(disc);
    return t > 0.001 ? t : -1.0;
}

float iBox(vec3 ro, vec3 rd, vec3 lo, vec3 hi) {
    vec3 id = 1.0/rd;
    vec3 tN = min((lo-ro)*id, (hi-ro)*id);
    vec3 tF = max((lo-ro)*id, (hi-ro)*id);
    float tNear = max(max(tN.x,tN.y),tN.z);
    float tFar  = min(min(tF.x,tF.y),tF.z);
    if (tFar < tNear || tFar < 0.001) return -1.0;
    return tNear > 0.001 ? tNear : tFar;
}

vec3 nBox(vec3 p, vec3 lo, vec3 hi) {
    vec3 c=(lo+hi)*0.5, d=p-c, s=(hi-lo)*0.5;
    vec3 q=abs(d)/s;
    if (q.x>q.y&&q.x>q.z) return vec3(sign(d.x),0.0,0.0);
    if (q.y>q.z)           return vec3(0.0,sign(d.y),0.0);
    return                        vec3(0.0,0.0,sign(d.z));
}

// --- Scene: object grid cells ---
#define CELL   8.0
#define SPAWN  0.58

float g_bestT;
vec3  g_bestN;
vec3  g_bestCol;

void checkCell(vec2 ci, vec3 ro, vec3 rd) {
    if (h1v(ci) > SPAWN) return;

    float ha = h1v(ci+vec2(7.3,2.1));
    float hb = h1v(ci+vec2(1.7,9.3));
    float hc = h1v(ci+vec2(4.1,5.7));
    float hd = h1v(ci+vec2(8.9,3.2));
    float he = h1v(ci+vec2(3.3,6.6));
    float ox = (ci.x + 0.15 + ha*0.70) * CELL;
    float oz = (ci.y + 0.15 + hb*0.70) * CELL;
    float sz = 0.4 + hc * 1.0;

    vec3 col = vec3(ha + 0.1, hb + 0.1, hd + 0.1);
    col /= max(max(col.r, col.g), col.b);

    int type = int(he * 1.9999);
    float t;

    if (type == 0) {
        vec3 ctr = vec3(ox, sz, oz);
        t = iSphere(ro, rd, ctr, sz);
        if (t > 0.0 && t < g_bestT) {
            g_bestT   = t;
            g_bestN   = normalize(ro + rd*t - ctr);
            if (dot(g_bestN, rd) > 0.0) g_bestN = -g_bestN;
            g_bestCol = col;
        }
    } else {
        vec3 lo = vec3(ox - sz*0.55, 0.0,    oz - sz*0.55);
        vec3 hi = vec3(ox + sz*0.55, sz*1.9, oz + sz*0.55);
        t = iBox(ro, rd, lo, hi);
        if (t > 0.0 && t < g_bestT) {
            g_bestT   = t;
            g_bestN   = nBox(ro + rd*t, lo, hi);
            if (dot(g_bestN, rd) > 0.0) g_bestN = -g_bestN;
            g_bestCol = col;
        }
    }
}

// Sky color given a ray direction (used for water reflections)
vec3 skyColor(vec3 dir, vec3 skyHoriz, vec3 skyTop, vec3 glowCol) {
    float s = clamp(dir.y*2.5 + 0.5, 0.0, 1.0);
    vec3 c = mix(skyHoriz, skyTop, pow(s, 0.5));
    c += glowCol * exp(-s*8.0) * 0.35;
    return c;
}

void main() {
    vec2 uv    = gl_FragCoord.xy / u_resolution;
    float asp  = u_resolution.x / u_resolution.y;

    float speed = u_x3 * 3.0;
    float tm    = u_time * speed;
    float fwd   = 0.5  + u_x0 * 5.0;
    float sway  = u_x1 * 4.0;

    float camZ = tm * fwd;
    float camX = (snoise(tm*0.18)-0.5)*2.0*sway
               + (snoise(tm*0.07+13.7)-0.5)*sway*0.6;
    vec3 ro = vec3(camX, 0.9, camZ);

    vec2 ndc = (uv*2.0-1.0) * vec2(asp, 1.0);
    vec3 rd  = normalize(vec3(ndc.x, ndc.y + 0.25, 1.6));

    // --- Color palettes ---
    float pf  = fract(u_x2) * 4.0;
    float pi  = floor(pf);
    float pt  = smoothstep(0.0, 1.0, fract(pf));

    vec3 sh0=vec3(0.30,0.60,1.00), sh1=vec3(0.90,0.35,0.10),
         sh2=vec3(0.10,0.80,0.90), sh3=vec3(0.75,0.20,0.95);
    vec3 st0=vec3(0.08,0.18,0.45), st1=vec3(0.28,0.06,0.04),
         st2=vec3(0.04,0.22,0.40), st3=vec3(0.20,0.04,0.35);
    vec3 fg0=vec3(0.25,0.45,0.75), fg1=vec3(0.60,0.25,0.15),
         fg2=vec3(0.15,0.55,0.70), fg3=vec3(0.50,0.18,0.65);
    vec3 glow0=vec3(0.40,0.70,1.00), glow1=vec3(1.00,0.55,0.10),
         glow2=vec3(0.10,0.95,1.00), glow3=vec3(0.95,0.30,1.00);
    vec3 wt0=vec3(0.05,0.20,0.45), wt1=vec3(0.30,0.08,0.04),
         wt2=vec3(0.04,0.28,0.38), wt3=vec3(0.22,0.05,0.35);
    vec3 ws0=vec3(1.00,0.55,0.00), ws1=vec3(0.00,0.80,0.50),
         ws2=vec3(0.90,0.10,0.70), ws3=vec3(0.10,0.90,0.10);

    #define PLERP(a0,a1,a2,a3) ( \
        pi < 0.5 ? mix(a0,a1,pt) : \
        pi < 1.5 ? mix(a1,a2,pt) : \
        pi < 2.5 ? mix(a2,a3,pt) : \
                   mix(a3,a0,pt) )

    vec3 skyHoriz = PLERP(sh0,sh1,sh2,sh3);
    vec3 skyTop   = PLERP(st0,st1,st2,st3);
    vec3 fogCol   = PLERP(fg0,fg1,fg2,fg3);
    vec3 glowCol  = PLERP(glow0,glow1,glow2,glow3);
    vec3 waterTint   = PLERP(wt0,wt1,wt2,wt3);
    vec3 waterSurface= PLERP(ws0,ws1,ws2,ws3);

    vec3 sunDir = normalize(vec3(0.4, 1.0, -0.3));

    // Floor plane (y = 0)
    float waterY  = 0.35;
    float tFloor = (rd.y < -0.0001) ? ((ro.y - waterY) / (-rd.y)) : -1.0;

    // Object search (reduced for RPi)
    g_bestT  = tFloor > 0.0 ? tFloor : 1e6;
    g_bestN  = vec3(0.0);
    g_bestCol = vec3(0.0);
    float hitObj = 0.0;

    vec2 camCell = floor(vec2(camX, camZ) / CELL);
    for (int iz = 0; iz <= 3; iz++) {
        for (int ix = -1; ix <= 1; ix++) {
            float prev = g_bestT;
            checkCell(camCell + vec2(float(ix), float(iz)), ro, rd);
            if (g_bestT < prev) hitObj = 1.0;
        }
    }

    // --- Shading ---
    vec3 color;

    if (hitObj > 0.5) {
        float diff = max(dot(g_bestN, sunDir), 0.0);
        float spec = pow(max(dot(reflect(-sunDir, g_bestN), -rd), 0.0), 40.0);
        color = g_bestCol * (diff*0.75 + 0.25) + vec3(1.0,0.95,0.8)*spec*0.45;
        float fog = clamp(1.0 - exp(-g_bestT * 0.013), 0.0, 1.0);
        color = mix(color, fogCol, fog);

    } else if (tFloor > 0.0) {
        // Water surface
        vec3 hp = ro + rd * tFloor;

        // Animated wave normal (perturb flat up-normal)
        vec2 slope = waterNormal(hp.xz, tm * 0.4);
        float waveStr = 0.18 * clamp(1.0 - tFloor * 0.03, 0.2, 1.0);
        vec3 wn = normalize(vec3(slope.x * waveStr, 1.0, slope.y * waveStr));

        // Reflect view ray off the perturbed surface normal
        vec3 reflDir = reflect(rd, wn);

        // Reflection: water surface has its own colour, independent of sky
        vec3 reflCol = waterSurface * (0.7 + 0.3 * dot(reflDir, vec3(0.0, 1.0, 0.0)));

        // Fresnel: grazing angles are more reflective
        float fresnel = pow(1.0 - max(dot(-rd, wn), 0.0), 3.0);
        fresnel = mix(0.3, 1.0, fresnel);

        // Specular highlight from sun
        float spec = pow(max(dot(reflDir, sunDir), 0.0), 80.0);
        vec3 specCol = glowCol * spec * 1.2;

        // Deep water color underneath (attenuated by distance)
        float depth = clamp(tFloor * 0.04, 0.0, 1.0);
        vec3 waterDeep = mix(waterTint * 1.4, fogCol, depth);

        // Blend: deep water base + fresnel reflection + specular
        color = mix(waterDeep, reflCol, fresnel) + specCol;

        // Fog at horizon
        float fog = clamp(1.0 - exp(-tFloor * 0.014), 0.0, 1.0);
        color = mix(color, fogCol, fog * 0.7);
        color = mix(skyHoriz, color, clamp(tFloor*0.35, 0.0, 1.0));

    } else {
        float s = clamp(rd.y*2.5 + 0.5, 0.0, 1.0);
        color = mix(skyHoriz, skyTop, pow(s, 0.5));
        color += glowCol * exp(-s*8.0) * 0.35;
    }

    // CRT scanlines
    color *= mod(gl_FragCoord.y, 2.0) < 1.0 ? 0.82 : 1.0;

    gl_FragColor = vec4(color, 1.0);
}
