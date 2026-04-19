#version 330 core
// ant_light_color_spectral_drain
// Draining vortex with spectral color bands spiraling inward and echo trails

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 spectral(float t) {
    return 0.5 + 0.5 * cos(TAU * (t * 1.5 + vec3(0.0, 0.33, 0.67)));
}

vec2 mirrorUV(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Drain twist: logarithmic spiral
    float drainSpeed = 2.0 + bass * 4.0;
    float drainAngle = angle + log(r + 0.01) * (5.0 + mid * 3.0) - iTime * drainSpeed;

    // Spectral color bands in spiral
    float bands = sin(drainAngle * (6.0 + treble * 4.0)) * 0.5 + 0.5;
    bands = pow(bands, 2.0);

    // Echo trails: multiple offset samples
    vec3 result = vec3(0.0);
    for (float i = 0.0; i < 5.0; i++) {
        float echoR = r + i * 0.02;
        float echoAngle = drainAngle + i * 0.15;
        vec2 echoUV = vec2(cos(echoAngle), sin(echoAngle)) * echoR * 0.5 + 0.5;
        vec3 s = texture(samp, mirrorUV(echoUV)).rgb;
        s *= spectral(i * 0.2 + r + iTime * 0.3);
        result += s * (1.0 / (1.0 + i * 0.5));
    }
    result /= 2.0;

    // Band color overlay
    result += spectral(drainAngle / TAU + r + iTime * 0.1) * bands * (0.3 + mid * 0.4);

    // Drain center suction glow
    float suction = exp(-r * (4.0 - bass * 3.0));
    result += spectral(iTime * 0.4) * suction * (1.5 + amp_peak * 3.0);

    // Outer vignette
    result *= smoothstep(1.5, 0.4, r);

    result *= 0.85 + amp_smooth * 0.35;
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
