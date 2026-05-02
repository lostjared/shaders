#version 330 core
// ant_spectrum_gradient_mirror
// Smooth gradient field with multi-axis mirrors, echo halos, and spectrum color bands

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
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Triple mirror: X, Y, and diagonal
    centered = abs(centered);
    if (centered.y > centered.x)
        centered = centered.yx;
    centered = abs(centered);

    float dist = length(centered);

    // Smooth gradient distortion
    float gradWave = sin(dist * (8.0 + mid * 12.0) + iTime * 2.0) * 0.03;
    centered += normalize(centered + 0.001) * gradWave * bass;

    uv = mirror(centered + 0.5);

    // Spectrum color bands: sample at different positions
    vec3 result = vec3(0.0);
    for (float i = 0.0; i < 8.0; i++) {
        float bandFreq = texture(spectrum, i * 0.08 + 0.02).r;
        float bandOff = bandFreq * 0.02 * (i + 1.0);
        vec2 bandUV = mirror(centered + 0.5 + vec2(bandOff * sin(iTime + i), bandOff * cos(iTime + i)));
        vec3 s = texture(samp, bandUV).rgb;
        // Map each band to a rainbow color
        s *= rainbow(i * 0.12 + dist * 2.0 + iTime * 0.2 + bandFreq);
        result += s * (1.0 / (1.0 + i * 0.3));
    }
    result /= 4.0;

    // Gradient field overlay
    vec3 grad = rainbow(dist * 5.0 + iTime * 0.4 + bass * 2.0);
    float gradMask = smoothstep(0.0, 0.5, dist);
    result = mix(result, result * grad, 0.3 * gradMask + hiMid * 0.15);

    // Color shift
    result = mix(result, result.gbr, treble * 0.4);

    // Air glow
    result += air * 0.08 * rainbow(iTime * 0.4);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
