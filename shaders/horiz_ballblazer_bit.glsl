// gen-shader
// Bitblazer: Ballblazer with 1-bit Bayer-dithered color
// u_x0: forward speed
// u_x1: lateral sway amount
// u_x2: ink/paper color pair (cycles through 4 classic palettes)
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

float iTri(vec3 ro, vec3 rd, vec3 a, vec3 b, vec3 c) {
    vec3 e1=b-a, e2=c-a, h=cross(rd,e2);
    float det=dot(e1,h);
    if (abs(det)<1e-5) return -1.0;
    float f=1.0/det;
    vec3 s=ro-a;
    float u=f*dot(s,h); if (u<0.0||u>1.0) return -1.0;
    vec3 q=cross(s,e1);
    float v=f*dot(rd,q); if (v<0.0||u+v>1.0) return -1.0;
    float t=f*dot(e2,q);
    return t>0.001 ? t : -1.0;
}

vec3 nBox(vec3 p, vec3 lo, vec3 hi) {
    vec3 c=(lo+hi)*0.5, d=p-c, s=(hi-lo)*0.5;
    vec3 q=abs(d)/s;
    if (q.x>q.y&&q.x>q.z) return vec3(sign(d.x),0.0,0.0);
    if (q.y>q.z)           return vec3(0.0,sign(d.y),0.0);
    return                        vec3(0.0,0.0,sign(d.z));
}

vec3 faceNorm(vec3 n, vec3 rd) {
    return dot(n, rd) > 0.0 ? -n : n;
}

// --- Scene: object grid cells ---
#define CELL   8.0
#define SPAWN  0.58

void checkCell(vec2 ci, vec3 ro, vec3 rd,
               inout float bestT, inout vec3 bestN, inout vec3 bestCol) {
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

    int type = int(he * 2.9999);
    float t;

    if (type == 0) {
        vec3 ctr = vec3(ox, sz, oz);
        t = iSphere(ro, rd, ctr, sz);
        if (t > 0.0 && t < bestT) {
            bestT   = t;
            bestN   = faceNorm(normalize(ro + rd*t - ctr), rd);
            bestCol = col;
        }
    } else if (type == 1) {
        vec3 lo = vec3(ox - sz*0.55, 0.0, oz - sz*0.55);
        vec3 hi = vec3(ox + sz*0.55, sz*1.9, oz + sz*0.55);
        t = iBox(ro, rd, lo, hi);
        if (t > 0.0 && t < bestT) {
            bestT   = t;
            bestN   = faceNorm(nBox(ro + rd*t, lo, hi), rd);
            bestCol = col;
        }
    } else {
        float br   = sz * 0.95;
        float ph   = sz * 2.6;
        vec3 apex  = vec3(ox,    ph,  oz   );
        vec3 b0    = vec3(ox-br, 0.0, oz-br);
        vec3 b1    = vec3(ox+br, 0.0, oz-br);
        vec3 b2    = vec3(ox+br, 0.0, oz+br);
        vec3 b3    = vec3(ox-br, 0.0, oz+br);

        t = iTri(ro,rd, b0,b1,apex);
        if (t>0.0&&t<bestT) { vec3 n=faceNorm(normalize(cross(b1-b0,apex-b0)),rd); bestT=t;bestN=n;bestCol=col; }
        t = iTri(ro,rd, b1,b2,apex);
        if (t>0.0&&t<bestT) { vec3 n=faceNorm(normalize(cross(b2-b1,apex-b1)),rd); bestT=t;bestN=n;bestCol=col; }
        t = iTri(ro,rd, b2,b3,apex);
        if (t>0.0&&t<bestT) { vec3 n=faceNorm(normalize(cross(b3-b2,apex-b2)),rd); bestT=t;bestN=n;bestCol=col; }
        t = iTri(ro,rd, b3,b0,apex);
        if (t>0.0&&t<bestT) { vec3 n=faceNorm(normalize(cross(b0-b3,apex-b3)),rd); bestT=t;bestN=n;bestCol=col; }
    }
}

// --- 4x4 Bayer ordered dither threshold ---
// Returns a threshold in [0,1] for the given pixel coordinate
float bayer(vec2 px) {
    vec2 p = mod(floor(px), 4.0);

    vec4 r0 = vec4( 0.0,  8.0,  2.0, 10.0) / 16.0;
    vec4 r1 = vec4(12.0,  4.0, 14.0,  6.0) / 16.0;
    vec4 r2 = vec4( 3.0, 11.0,  1.0,  9.0) / 16.0;
    vec4 r3 = vec4(15.0,  7.0, 13.0,  5.0) / 16.0;

    vec4 row = p.y < 1.0 ? r0 :
               p.y < 2.0 ? r1 :
               p.y < 3.0 ? r2 : r3;

    return p.x < 1.0 ? row.x :
           p.x < 2.0 ? row.y :
           p.x < 3.0 ? row.z : row.w;
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

    // Shared scene colors (greyscale-friendly midtones for dithering)
    vec3 skyHoriz = vec3(0.55, 0.65, 0.80);
    vec3 skyTop   = vec3(0.10, 0.12, 0.18);
    vec3 fogCol   = vec3(0.40, 0.48, 0.60);
    vec3 floorA   = vec3(0.05, 0.05, 0.05);
    vec3 floorB   = vec3(0.90, 0.90, 0.90);
    vec3 sunDir   = normalize(vec3(0.4, 1.0, -0.3));

    // Floor plane
    float tFloor = (rd.y < -0.0001) ? (ro.y / (-rd.y)) : -1.0;

    // Object search
    float bestT  = tFloor > 0.0 ? tFloor : 1e6;
    vec3  bestN  = vec3(0.0);
    vec3  bestC  = vec3(0.0);
    bool  hitObj = false;

    vec2 camCell = floor(vec2(camX, camZ) / CELL);
    for (int iz = -1; iz <= 6; iz++) {
        for (int ix = -3; ix <= 3; ix++) {
            float prev = bestT;
            checkCell(camCell + vec2(float(ix), float(iz)), ro, rd, bestT, bestN, bestC);
            if (bestT < prev) hitObj = true;
        }
    }

    // --- Full-color shading (will be dithered to 1-bit) ---
    vec3 color;

    if (hitObj) {
        float diff = max(dot(bestN, sunDir), 0.0);
        float spec = pow(max(dot(reflect(-sunDir, bestN), -rd), 0.0), 40.0);
        color = bestC * (diff*0.75 + 0.25) + vec3(1.0)*spec*0.5;
        float fog = clamp(1.0 - exp(-bestT * 0.013), 0.0, 1.0);
        color = mix(color, fogCol, fog);

    } else if (tFloor > 0.0) {
        vec3 hp  = ro + rd*tFloor;
        float chk = mod(floor(hp.x) + floor(hp.z), 2.0);
        color = chk < 0.5 ? floorA : floorB;
        float fog = clamp(1.0 - exp(-tFloor * 0.014), 0.0, 1.0);
        color = mix(color, fogCol, fog);
        color = mix(skyHoriz, color, clamp(tFloor*0.35, 0.0, 1.0));

    } else {
        float s = clamp(rd.y*2.5 + 0.5, 0.0, 1.0);
        color = mix(skyHoriz, skyTop, pow(s, 0.5));
    }

    // --- 1-bit Bayer dither ---
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float threshold = bayer(gl_FragCoord.xy);
    float bit = step(threshold, luma); // 0 or 1

    // --- Ink / paper color pairs, cycled by u_x2 ---
    // 0.00  Classic       black / white
    // 0.25  Phosphor      black / green
    // 0.50  Amber         black / amber
    // 0.75  Blueprint     dark blue / pale blue
    float pf = fract(u_x2) * 4.0;
    float pi = floor(pf);
    float pt = smoothstep(0.0, 1.0, fract(pf));

    vec3 ink0 =vec3(0.00,0.00,0.00), ink1 =vec3(0.00,0.00,0.00),
         ink2 =vec3(0.00,0.00,0.00), ink3 =vec3(0.02,0.04,0.14);
    vec3 paper0=vec3(1.00,1.00,1.00), paper1=vec3(0.10,1.00,0.30),
         paper2=vec3(1.00,0.72,0.08), paper3=vec3(0.60,0.80,1.00);

    #define PLERP(a0,a1,a2,a3) ( \
        pi < 0.5 ? mix(a0,a1,pt) : \
        pi < 1.5 ? mix(a1,a2,pt) : \
        pi < 2.5 ? mix(a2,a3,pt) : \
                   mix(a3,a0,pt) )

    vec3 ink   = PLERP(ink0,  ink1,  ink2,  ink3 );
    vec3 paper = PLERP(paper0,paper1,paper2,paper3);

    gl_FragColor = vec4(mix(ink, paper, bit), 1.0);
}
