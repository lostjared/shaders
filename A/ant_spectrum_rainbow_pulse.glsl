#version 330 core
// ant_spectrum_rainbow_pulse
// Pulsing quad-mirror with rainbow ring waves, echo pulses, and color cycling

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.78).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Quad mirror with pulse
    float pulse = 1.0 + bass * 0.2 * sin(iTime * 5.0);
    centered *= pulse;
    centered = abs(centered);

    float dist = length(centered);

    // Ring wave distortion
    float ringWave = sin(dist * (20.0 + mid * 20.0) - iTime * 4.0);
    vec2 waveOff = normalize(centered + 0.001) * ringWave * 0.02 * (1.0 + hiMid);

    vec2 texUV = mirror(centered + 0.5 + waveOff);

    // Rainbow pulse echo: ring-offset samples
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 6.0; e++) {
        float ePulse = sin(dist * 20.0 - iTime * 4.0 + e * PI * 0.33);
        vec2 eOff = normalize(centered + 0.001) * ePulse * 0.01 * (e + 1.0);
        vec3 s = texture(samp, mirror(centered + 0.5 + eOff)).rgb;
        s *= rainbow(e * 0.15 + dist * 3.0 + iTime * 0.3);
        result += s * (1.0 / (1.0 + e * 0.3));
    }
    result /= 3.0;

    // Rainbow ring overlay
    float ringBright = smoothstep(0.0, 0.5, ringWave) * 0.3;
    result += rainbow(dist * 4.0 + iTime * 0.5 + bass) * ringBright;

    // Color cycling
    float cycle = iTime * 0.3;
    result = mix(result, result.gbr, sin(cycle) * 0.4 + 0.4);
    result = mix(result, result.brg, sin(cycle * 0.7) * 0.2 + 0.2);

    // Air shimmer
    result += air * 0.08 * rainbow(iTime + dist);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
