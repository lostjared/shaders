#version 330 core
// ant_spectrum_gradient_bloom
// Radial mirror bloom with gradient color bands, echo halos, and chromatic glow

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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Quad mirror
    centered = abs(centered);
    // Diamond fold
    if (centered.y > centered.x)
        centered = centered.yx;

    float dist = length(centered);

    // Radial bloom: concentric halo samples
    vec3 bloom = vec3(0.0);
    for (float i = 0.0; i < 8.0; i++) {
        float ringDist = dist + i * (0.01 + bass * 0.008);
        float ringAngle = atan(centered.y, centered.x) + i * 0.05;
        vec2 ringUV = vec2(cos(ringAngle), sin(ringAngle)) * ringDist + 0.5;
        vec3 s = texture(samp, mirror(ringUV)).rgb;
        s *= rainbow(i * 0.12 + dist * 3.0 + iTime * 0.3);
        bloom += s * (1.0 / (1.0 + i * 0.3));
    }
    bloom /= 4.5;

    // Echo halos
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.02).r;
        float haloR = dist + e * 0.03 * (1.0 + mid);
        vec2 haloUV = normalize(centered + 0.001) * haloR + 0.5;
        vec3 eCol = texture(samp, mirror(haloUV)).rgb;
        eCol *= rainbow(e * 0.2 + iTime * 0.25 + freq);
        echo += eCol * (0.2 / e);
    }

    vec3 result = bloom + echo;

    // Gradient color bands
    vec3 grad = rainbow(dist * 5.0 + iTime * 0.5 + bass * 2.0);
    float bandPattern = sin(dist * 30.0 - iTime * 4.0) * 0.5 + 0.5;
    result = mix(result, result * grad, 0.3 * bandPattern + hiMid * 0.2);

    // Chromatic glow
    float spread = 0.005 + treble * 0.02;
    vec3 chromGlow;
    chromGlow.r = texture(samp, mirror(centered + 0.5 + vec2(spread, 0.0))).r;
    chromGlow.g = texture(samp, mirror(centered + 0.5)).g;
    chromGlow.b = texture(samp, mirror(centered + 0.5 - vec2(spread, 0.0))).b;
    result = mix(result, chromGlow, 0.2);

    // Color shift
    result = mix(result, result.brg, air * 0.4);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
