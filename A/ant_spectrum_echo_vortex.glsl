#version 330 core
// ant_spectrum_echo_vortex
// Vortex echo tunnel with spiral mirrors, chromatic depth, and rainbow rotation

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
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Vortex rotation increasing with distance
    float vortexStr = 3.0 + bass * 4.0;
    float vortexAngle = angle + r * vortexStr + iTime * 1.5;
    vec2 vortexUV = vec2(cos(vortexAngle), sin(vortexAngle)) * r;

    // Kaleidoscope on vortex
    float seg = floor(6.0 + mid * 4.0);
    vec2 kUV = kaleidoscope(vortexUV, seg);
    kUV = abs(kUV);

    // Mirror texture
    vec2 texUV = mirror(kUV * 0.6 + 0.5);

    // Chromatic depth: channels at different vortex depths
    float chromStr = 0.02 + treble * 0.05;
    vec2 vR = vec2(cos(vortexAngle + chromStr * 3.0), sin(vortexAngle + chromStr * 3.0)) * r;
    vec2 vB = vec2(cos(vortexAngle - chromStr * 3.0), sin(vortexAngle - chromStr * 3.0)) * r;
    vec2 kR = abs(kaleidoscope(vR, seg));
    vec2 kB = abs(kaleidoscope(vB, seg));

    vec3 result;
    result.r = texture(samp, mirror(kR * 0.6 + 0.5)).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(kB * 0.6 + 0.5)).b;

    // Echo vortex layers
    for (float e = 1.0; e < 5.0; e++) {
        float eAngle = angle + r * (vortexStr + e * 0.5) + iTime * 1.5 + e * 0.5;
        vec2 eVUV = vec2(cos(eAngle), sin(eAngle)) * r;
        vec2 eKUV = abs(kaleidoscope(eVUV, seg));
        vec3 s = texture(samp, mirror(eKUV * 0.6 + 0.5)).rgb;
        s *= rainbow(e * 0.2 + r + iTime * 0.25 + hiMid);
        result += s * (0.2 / e);
    }

    // Rainbow rotation: tint based on angle
    result *= mix(vec3(1.0), rainbow(angle / PI + r + iTime * 0.3), 0.3 + air * 0.15);

    // Color shift
    result = mix(result, result.gbr, smoothstep(0.3, 0.7, sin(iTime * 0.5)));

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
