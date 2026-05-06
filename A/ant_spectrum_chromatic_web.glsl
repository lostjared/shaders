#version 330 core
// ant_spectrum_chromatic_web
// Spider-web kaleidoscope with chromatic threads, echo web layers, and rainbow glow

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
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // High-segment kaleidoscope for web pattern
    float seg = floor(10.0 + bass * 10.0);
    vec2 kUV = kaleidoscope(uv, seg);

    // Web radial/concentric pattern
    float radial = abs(sin(angle * seg + iTime * 0.5));
    float concentric = abs(sin(r * (15.0 + mid * 20.0) - iTime * 2.0));
    float webPattern = min(radial, concentric);
    float threadGlow = pow(0.02 / max(webPattern, 0.001), 0.8);
    threadGlow = min(threadGlow, 3.0);

    // Chromatic web: offset per channel
    float spread = 0.01 + treble * 0.03;
    vec2 texUV = mirror(kUV * 0.6 + 0.5);
    vec3 tex;
    tex.r = texture(samp, mirror(texUV + vec2(spread, 0.0))).r;
    tex.g = texture(samp, texUV).g;
    tex.b = texture(samp, mirror(texUV - vec2(spread, 0.0))).b;

    // Echo web layers
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 4.0; e++) {
        float eSeg = seg + e * 2.0;
        vec2 eKUV = kaleidoscope(uv * (1.0 + e * 0.03), eSeg);
        vec3 eCol = texture(samp, mirror(eKUV * 0.6 + 0.5)).rgb;
        eCol *= rainbow(e * 0.25 + r + iTime * 0.2);
        echo += eCol * (0.3 / e);
    }

    // Web thread rainbow glow
    vec3 threadColor = rainbow(angle / PI + r * 2.0 + iTime * 0.3 + hiMid);

    // Compose
    vec3 result = tex + echo * 0.5;
    result += threadColor * threadGlow * 0.15 * (1.0 + bass);

    // Color shift
    result = mix(result, result.gbr, air * 0.4);

    // Gradient
    result *= mix(vec3(1.0), rainbow(r + iTime * 0.25), 0.2);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
