// Brakhage — chaotic paint swirls inspired by "The Dante Quartet" (vertical)
// Each "frame" is a new random painting; swirls animate continuously between refreshes
//
// u_x0: swirl scale (tight → sprawling)
// u_x1: color diversity (1 color → 6 distinct colors per painting)
// u_x2: refresh rate (static painting → rapid Brakhage frame changes)
// u_x3: speed / swirl animation rate

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_x0;
uniform float u_x1;
uniform float u_x2;
uniform float u_x3;

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 hue2rgb(float h) {
    float r = abs(h * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(h * 6.0 - 2.0);
    float b = 2.0 - abs(h * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec3 palette(float n, float nColors, float baseHue) {
    float idx = n * nColors;
    float fi = floor(idx);
    float bl = fract(idx);
    vec3 ca = hue2rgb(fract(baseHue + fi * 0.618033));
    vec3 cb = hue2rgb(fract(baseHue + (fi + 1.0) * 0.618033));
    return mix(ca, cb, bl * bl);
}

void main(void) {
    vec2 rawUV = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
    vec2 uv = vec2(rawUV.y, 1.0 - rawUV.x);
    float aspect = u_resolution.y / u_resolution.x;

    float speed = 0.2 + u_x3 * 1.2;
    float t = u_time * speed;

    float refreshRate = u_x2 * u_x2 * 8.0;
    float seed = 0.0;
    if (refreshRate > 0.01) {
        seed = floor(u_time * refreshRate);
    }

    float nColors = 1.0 + floor(u_x1 * 5.99);
    float baseHue = hash(vec2(seed * 17.31, seed * 3.71));

    // Randomize warp character per painting — frequencies, amplitudes, layer scales
    float rf1 = 1.5 + hash(vec2(seed, 0.0)) * 3.5;
    float rf2 = 1.5 + hash(vec2(seed, 1.0)) * 3.5;
    float rf3 = 1.0 + hash(vec2(seed, 2.0)) * 2.5;
    float rf4 = 1.0 + hash(vec2(seed, 3.0)) * 2.5;
    float ra1 = 0.8 + hash(vec2(seed, 4.0)) * 1.4;
    float ra2 = 0.8 + hash(vec2(seed, 5.0)) * 1.4;
    float ra3 = 0.3 + hash(vec2(seed, 6.0)) * 0.8;
    float l2s = 1.3 + hash(vec2(seed, 7.0)) * 1.4;
    float l3s = 2.2 + hash(vec2(seed, 8.0)) * 2.0;
    float rf5 = 2.0 + hash(vec2(seed, 9.0)) * 4.0;
    float rf6 = 2.0 + hash(vec2(seed, 10.0)) * 4.0;
    float ra4 = 0.4 + hash(vec2(seed, 11.0)) * 0.8;
    float ra5 = 0.4 + hash(vec2(seed, 12.0)) * 0.8;
    float rf7 = 3.0 + hash(vec2(seed, 13.0)) * 4.0;
    float rf8 = 3.0 + hash(vec2(seed, 14.0)) * 4.0;
    float ra6 = 0.3 + hash(vec2(seed, 15.0)) * 0.6;
    float ra7 = 0.3 + hash(vec2(seed, 16.0)) * 0.6;

    float scale = mix(3.0, 12.0, u_x0);
    vec2 st = vec2(uv.x * aspect, uv.y) * scale;

    // === Layer 1: large swirl shapes ===
    vec2 p1 = st;
    p1.x += sin(p1.y * rf1 + t + seed * 7.3) * ra1;
    p1.y += cos(p1.x * rf2 + t * 0.8 + seed * 5.1) * ra2;
    p1.x += sin(p1.y * rf3 + t * 0.5 + seed * 3.7) * ra3;

    float n1 = noise(p1 + seed * 13.37);
    vec3 col1 = palette(n1, nColors, baseHue);

    // === Layer 2: smaller paint strokes ===
    vec2 p2 = st * l2s;
    p2.x += sin(p2.y * rf5 + t * 0.6 + seed * 11.0) * ra4;
    p2.y += cos(p2.x * rf6 + t * 0.7 + seed * 9.0) * ra5;

    float n2 = noise(p2 + seed * 7.71);
    vec3 col2 = palette(n2, nColors, baseHue);
    float mask2 = smoothstep(0.3, 0.7, noise(p2 * 0.53 + seed * 5.13));

    // === Layer 3: fine spatter ===
    vec2 p3 = st * l3s;
    p3.x += sin(p3.y * rf7 + t * 0.4 + seed * 2.3) * ra6;
    p3.y += cos(p3.x * rf8 + t * 0.3 + seed * 8.1) * ra7;

    float n3 = noise(p3 + seed * 19.13);
    vec3 col3 = palette(n3, nColors, baseHue);
    float mask3 = smoothstep(0.45, 0.75, noise(p3 * 0.47 + seed * 11.31));

    // Composite: base → strokes → spatter
    vec3 col = col1;
    col = mix(col, col2, mask2);
    col = mix(col, col3, mask3);

    float bright = 0.8 + 0.2 * noise(st * 0.7 + seed * 3.0);
    col *= bright;

    gl_FragColor = vec4(col, 1.0);
}
