#version 330 core
// ant_spectrum_rainbow_cathedral
// Gothic cathedral arches with mirror symmetry, echo nave depths, and stained glass rainbow

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
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Cathedral vertical mirror
    uv.x = abs(uv.x);

    // Gothic arch distortion: pointed arch shape
    float archHeight = 0.8 + bass * 0.3;
    float archWidth = 0.4 + lowMid * 0.2;
    vec2 archUV = uv;
    archUV.y -= uv.x * uv.x * archHeight / (archWidth * archWidth);

    // Kaleidoscope within arch
    float seg = floor(4.0 + mid * 4.0);
    vec2 kUV = kaleidoscope(archUV, seg);
    kUV = abs(kUV);

    // Mirror texture
    vec2 texUV = mirror(kUV * 0.6 + 0.5);

    // Stained glass: chromatic facets
    float spread = 0.012 + treble * 0.04;
    vec3 stained;
    stained.r = texture(samp, mirror(texUV + vec2(spread, spread * 0.5))).r;
    stained.g = texture(samp, texUV).g;
    stained.b = texture(samp, mirror(texUV - vec2(spread, spread * 0.5))).b;

    // Echo nave depths: receding arch layers
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        vec2 eArchUV = archUV * (1.0 - e * 0.05);
        eArchUV *= rot(e * 0.03);
        vec2 eKUV = kaleidoscope(eArchUV, seg);
        eKUV = abs(eKUV);
        vec3 s = texture(samp, mirror(eKUV * 0.6 + 0.5)).rgb;
        // Stained glass rainbow per depth
        s *= rainbow(e * 0.18 + length(archUV) + iTime * 0.2 + hiMid);
        echo += s * (0.25 / e);
    }

    vec3 result = stained + echo;

    // Stained glass color overlay
    float glassAngle = atan(archUV.y, archUV.x);
    float glassDist = length(archUV);
    vec3 glassColor = rainbow(glassAngle / PI + glassDist * 2.0 + iTime * 0.3 + bass);
    result = mix(result, result * glassColor * 1.3, 0.3 + mid * 0.15);

    // Vertical light shaft
    float shaft = exp(-abs(uv.x) * 8.0);
    result += shaft * rainbow(uv.y + iTime * 0.5) * 0.12 * (1.0 + air);

    // Color shift
    result = mix(result, result.gbr, air * 0.35);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
