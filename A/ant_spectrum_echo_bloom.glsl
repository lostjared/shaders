#version 330 core
// ant_spectrum_echo_bloom
// Bloom echo feedback with mirrored halo, kaleidoscopic color, and gradient pulse

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
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float seg = floor(8.0 + bass * 4.0);
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Bloom: radial multi-sample with decay
    vec3 bloom = vec3(0.0);
    float bloomSamples = 12.0;
    float totalW = 0.0;
    for (float i = 0.0; i < 12.0; i++) {
        float bloomR = r * (1.0 + i * (0.008 + mid * 0.008));
        float bloomA = angle + i * 0.02 * sin(iTime * 0.5);
        vec2 bUV = vec2(cos(bloomA), sin(bloomA)) * bloomR;

        // Kaleidoscope fold
        bUV = kaleidoscope(bUV, seg);
        bUV = abs(bUV);

        vec3 s = texture(samp, mirror(bUV * 0.6 + 0.5)).rgb;
        s *= rainbow(i * 0.08 + r + iTime * 0.15);
        float w = 1.0 / (1.0 + i * 0.2);
        bloom += s * w;
        totalW += w;
    }
    bloom /= totalW;

    // Echo feedback: kaleidoscope at offsets
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.02).r;
        vec2 eUV = kaleidoscope(uv * (1.0 + e * 0.04), seg + e * 2.0);
        eUV = abs(eUV);
        vec3 s = texture(samp, mirror(eUV * 0.6 + 0.5)).rgb;
        s *= rainbow(e * 0.22 + r * 2.0 + iTime * 0.25 + freq);
        echo += s * (0.2 / e);
    }

    vec3 result = bloom + echo * 0.5;

    // Gradient pulse
    float pulse = sin(r * (10.0 + hiMid * 15.0) - iTime * 4.0) * 0.5 + 0.5;
    result += rainbow(r * 3.0 + iTime * 0.4) * pulse * 0.1;

    // Color shift
    result = mix(result, result.brg, treble * 0.4);
    result += air * 0.06 * rainbow(iTime * 0.3);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
