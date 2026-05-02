#version 330 core
// ant_spectrum_chromatic_pulse
// Pulsing chromatic rings with kaleidoscopic mirror, echo wave fronts, and rainbow wash

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

void main() {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Pulsing rings: radius distortion
    float pulseFreq = 15.0 + mid * 25.0;
    float pulsePhase = iTime * 4.0;
    float ringPulse = sin(r * pulseFreq - pulsePhase) * (0.02 + bass * 0.04);
    vec2 pulsedUV = uv + normalize(uv + 0.001) * ringPulse;

    // Kaleidoscope
    float seg = floor(6.0 + bass * 6.0);
    vec2 kUV = kaleidoscope(pulsedUV, seg);
    kUV = abs(kUV);

    // Chromatic pulse: each channel at different pulse phase
    float spread = 0.01 + treble * 0.03;
    vec2 baseTexUV = mirror(kUV * 0.6 + 0.5);
    vec3 result;
    vec2 pulseR = normalize(uv + 0.001) * sin(r * pulseFreq - pulsePhase + 1.0) * spread;
    vec2 pulseB = normalize(uv + 0.001) * sin(r * pulseFreq - pulsePhase - 1.0) * spread;
    result.r = texture(samp, mirror(kUV * 0.6 + 0.5 + pulseR * 2.0)).r;
    result.g = texture(samp, baseTexUV).g;
    result.b = texture(samp, mirror(kUV * 0.6 + 0.5 + pulseB * 2.0)).b;

    // Echo wave fronts
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float ePhase = pulsePhase + e * PI * 0.5;
        float ePulse = sin(r * pulseFreq - ePhase) * 0.02 * e;
        vec2 eUV = kaleidoscope(uv + normalize(uv + 0.001) * ePulse, seg);
        eUV = abs(eUV);
        vec3 s = texture(samp, mirror(eUV * 0.6 + 0.5)).rgb;
        s *= rainbow(e * 0.2 + r + iTime * 0.25 + hiMid);
        echo += s * (0.25 / e);
    }
    result += echo;

    // Rainbow wash
    result *= mix(vec3(1.0), rainbow(r * 2.5 + iTime * 0.4 + bass), 0.3 + air * 0.15);

    // Color cycle
    result = mix(result, result.brg, sin(iTime * 0.5) * 0.4 + 0.4);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
