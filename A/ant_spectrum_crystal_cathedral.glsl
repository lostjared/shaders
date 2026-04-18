#version 330 core
// ant_spectrum_crystal_cathedral
// Multi-axis mirror cathedral with rainbow stained glass and echo trails

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
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

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Cathedral kaleidoscope: 6-12 segments
    float seg = floor(6.0 + bass * 6.0);
    vec2 kUV = kaleidoscope(uv, seg);

    // Diamond fold mirroring
    kUV = abs(kUV);
    if (kUV.y > kUV.x) kUV = kUV.yx;

    // Recursive fold with rotation
    for (int i = 0; i < 4; i++) {
        kUV = abs(kUV * (1.2 + mid * 0.3)) - 0.4;
        kUV *= rot(iTime * 0.08 + float(i) * 0.5);
        kUV = abs(kUV);
        if (kUV.y > kUV.x) kUV = kUV.yx;
    }

    // Map back to texture coords with mirroring
    vec2 texUV = mirror(kUV * 0.5 + 0.5);

    // Echo trails: blend multiple time-offset samples
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 5.0; e++) {
        float offset = e * 0.015 * (1.0 + hiMid);
        vec2 echoUV = mirror(texUV + vec2(offset * sin(iTime + e), offset * cos(iTime + e)));
        result += texture(samp, echoUV).rgb * (1.0 - e * 0.18);
    }
    result /= 3.2;

    // Rainbow stained glass overlay
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    vec3 stainedGlass = rainbow(angle / PI + r * 2.0 + iTime * 0.3 + bass);
    float glassMask = smoothstep(0.3, 0.7, sin(length(kUV) * 15.0 + iTime));
    result = mix(result, result * stainedGlass, 0.4 + treble * 0.3);

    // Color shift based on spectrum
    result.rgb = mix(result.rgb, result.gbr, smoothstep(0.3, 0.7, mid));

    // Air shimmer
    result += air * 0.1 * rainbow(iTime * 0.5 + r);

    // Peak inversion
    float inv = smoothstep(0.9, 1.0, amp_peak);
    result = mix(result, vec3(1.0) - result, inv);

    color = vec4(result, 1.0);
}
