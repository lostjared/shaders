#version 330 core
// ant_spectrum_gradient_kaleidoscope
// Gradient-mapped kaleidoscope with smooth color bands, echo layers, and hue cycling

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
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Kaleidoscope
    float seg = floor(8.0 + bass * 8.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);

    // Gradient mapping: use kUV position to drive color bands
    float gradVal = length(kUV) * 3.0 + kUV.x * 2.0;
    gradVal += iTime * 0.5;
    vec3 gradColor = rainbow(gradVal + bass);

    // Texture with gradient modulation
    vec2 texUV = mirror(kUV * 0.6 + 0.5);
    vec3 tex = texture(samp, texUV).rgb;

    // Smooth color band overlay
    float bands = sin(gradVal * 5.0 + mid * PI) * 0.5 + 0.5;
    tex = mix(tex, tex * gradColor * 1.4, 0.35 * bands);

    // Echo layers with different gradient phases
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        vec2 eKUV = kaleidoscope(uv * (1.0 + e * 0.04), seg + e);
        eKUV = abs(eKUV);
        vec3 s = texture(samp, mirror(eKUV * 0.6 + 0.5)).rgb;
        float eGrad = length(eKUV) * 3.0 + eKUV.x * 2.0 + iTime * 0.5 + e * 0.5;
        s *= rainbow(eGrad + hiMid);
        echo += s * (0.25 / e);
    }

    vec3 result = tex + echo;

    // Hue cycling
    float hueShift = iTime * 0.4 + dist;
    result = mix(result, result.gbr, sin(hueShift) * 0.4 + 0.4);
    result = mix(result, result.brg, sin(hueShift * 0.7) * 0.2 + 0.2);

    // Air glow
    result += air * 0.06 * rainbow(iTime * 0.3 + dist);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
