#version 330 core
// ant_new_helix_mirror
// Mix of ant_light_color_plasma_helix + ant_spectrum_mirror_infinity:
// double helix neon strands layered over an infinite mirror recursion
// with kaleidoscope folds and rainbow depth tint.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) { float s = sin(a), c = cos(a); return mat2(c, -s, s, c); }

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = abs(mod(ang, s) - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.13).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Infinite mirror recursion (reduced depth for perf, weighted by depth)
    vec3 recursion = vec3(0.0);
    float totalW = 0.0;
    float seg = floor(6.0 + bass * 6.0);
    for (float d = 0.0; d < 8.0; d++) {
        float zoom = pow(1.18 + mid * 0.1, d);
        vec2 rUV = uv * zoom * rot(d * (0.12 + lowMid * 0.05) + iTime * 0.05);
        vec2 kUV = kaleidoscope(rUV, seg);
        kUV = abs(kUV);
        if (kUV.y > kUV.x) kUV = kUV.yx;
        vec2 texUV = mirror(kUV * 0.5 + 0.5);
        float off = d * 0.002 * (1.0 + treble);
        vec3 s;
        s.r = texture(samp, mirror(texUV + vec2(off, 0.0))).r;
        s.g = texture(samp, texUV).g;
        s.b = texture(samp, mirror(texUV - vec2(off, 0.0))).b;
        s *= rainbow(d * 0.1 + length(kUV) + iTime * 0.15 + hiMid);
        float w = 1.0 / (1.0 + d * 0.55);
        recursion += s * w;
        totalW += w;
    }
    recursion /= totalW;

    // Double helix strands overlaid on recursion
    vec2 p = uv;
    float hA = sin(p.y * 15.0 + iTime * 3.0 + bass * 5.0) * (0.18 + mid * 0.1);
    float hB = sin(p.y * 15.0 + iTime * 3.0 + bass * 5.0 + PI) * (0.18 + mid * 0.1);
    float sA = smoothstep(0.045, 0.0, abs(p.x - hA));
    float sB = smoothstep(0.045, 0.0, abs(p.x - hB));

    vec3 col = recursion;
    col += rainbow(iTime * 0.3 + p.y) * sA * (1.8 + air * 4.0);
    col += rainbow(iTime * 0.3 + p.y + 0.5) * sB * (1.8 + air * 4.0);

    // Rungs between strands pulse on bass
    float rung = step(0.9, fract(p.y * 8.0 + iTime));
    float between = smoothstep(abs(hB), abs(hA), abs(p.x));
    col += rainbow(p.y + iTime) * rung * between * bass * 2.0;

    // Center glow
    col += exp(-length(uv) * 5.0) * rainbow(iTime * 0.4 + bass) * 0.15;

    col *= 0.9 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
