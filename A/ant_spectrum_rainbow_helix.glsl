#version 330 core
// ant_spectrum_rainbow_helix
// Double helix spiral with mirrored strands, rainbow coloring, and echo trails

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
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.25).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Double helix: two intertwined spirals
    float helixTwist = 3.0 + bass * 5.0;
    float helix1 = sin(angle * helixTwist + log(r + 0.001) * 6.0 - iTime * 2.5);
    float helix2 = sin(angle * helixTwist + log(r + 0.001) * 6.0 - iTime * 2.5 + PI);

    // Mirror in polar
    angle = abs(mod(angle + PI, PI * 2.0 / 6.0) - PI / 6.0);
    vec2 mirrorUV = vec2(cos(angle), sin(angle)) * r * 0.5 + 0.5;

    // Echo trails along helix
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 5.0; e++) {
        float offset = e * 0.01 * (1.0 + mid);
        vec2 eUV = mirror(mirrorUV + vec2(offset * sin(iTime + e * 1.3), offset * cos(iTime + e)));
        vec3 s = texture(samp, eUV).rgb;

        // Color per strand
        float strand = mix(helix1, helix2, fract(e * 0.5));
        s *= rainbow(e * 0.18 + strand * 0.3 + iTime * 0.3);
        result += s * (1.0 / (1.0 + e * 0.35));
    }
    result /= 2.8;

    // Helix glow
    float h1Glow = exp(-pow(helix1 * 3.0, 2.0)) * 0.5;
    float h2Glow = exp(-pow(helix2 * 3.0, 2.0)) * 0.5;
    result += rainbow(angle / PI + iTime * 0.4) * h1Glow * (1.0 + lowMid);
    result += rainbow(angle / PI + iTime * 0.4 + 0.5) * h2Glow * (1.0 + lowMid);

    // Color shifting
    result = mix(result, result.brg, treble * 0.5);

    // Gradient
    result *= mix(vec3(1.0), rainbow(r * 2.0 + iTime * 0.2), 0.2 + air * 0.15);

    result *= smoothstep(2.0, 0.4, r);
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
