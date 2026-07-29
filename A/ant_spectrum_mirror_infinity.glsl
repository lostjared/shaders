#version 330 core
// ant_spectrum_mirror_infinity
// Infinite mirror recursion with kaleidoscopic fold, rainbow depth, and echo fade

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

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Infinity recursion: zoom into center with mirror folds
    vec3 result = vec3(0.0);
    float totalW = 0.0;
    float seg = floor(6.0 + bass * 6.0);

    for (float depth = 0.0; depth < 10.0; depth++) {
        // Progressive zoom + rotation
        float zoom = pow(1.15 + mid * 0.1, depth);
        float rotation = depth * (0.1 + lowMid * 0.05) + iTime * 0.05;
        vec2 infUV = uv * zoom;
        infUV *= rot(rotation);

        // Kaleidoscope at this depth
        vec2 kUV = kaleidoscope(infUV, seg);
        kUV = abs(kUV);
        if (kUV.y > kUV.x) kUV = kUV.yx;

        // Mirror texture
        vec2 texUV = mirror(kUV * 0.5 + 0.5);

        // Sample with chromatic offset per depth
        float chromOff = depth * 0.002 * (1.0 + treble);
        vec3 s;
        s.r = texture(samp, mirror(texUV + vec2(chromOff, 0.0))).r;
        s.g = texture(samp, texUV).g;
        s.b = texture(samp, mirror(texUV - vec2(chromOff, 0.0))).b;

        // Rainbow depth tint
        s *= rainbow(depth * 0.1 + length(kUV) + iTime * 0.15 + hiMid);

        // Weight: fade with depth
        float w = 1.0 / (1.0 + depth * 0.5);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Center glow
    float r = length(uv);
    result += exp(-r * 5.0) * rainbow(iTime * 0.4 + bass) * 0.15;

    // Color shift
    result = mix(result, result.gbr, smoothstep(0.3, 0.7, sin(iTime * 0.6)));
    result = mix(result, result.brg, air * 0.3);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
