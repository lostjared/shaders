#version 330 core
// ant_light_color_chromatic_worm
// Writhing chromatic wormhole with spectrum-driven diameter and color trail

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Wormhole center path
    vec2 center = vec2(sin(iTime * 0.7) * 0.2, cos(iTime * 0.5) * 0.15);
    vec2 p = uv - center;

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Wormhole twist increasing toward center
    float wormTwist = (6.0 + bass * 10.0) / (r + 0.2);
    angle += wormTwist + iTime * 1.5;

    // Diameter pulsing with mid
    float diameter = 0.3 + mid * 0.2 + sin(iTime * 2.0) * 0.05;
    float tube = smoothstep(diameter + 0.05, diameter, r);

    // Chromatic channel separation along angle
    float dispersion = (treble + air) * 0.06;
    vec2 uvR = vec2(cos(angle + dispersion), sin(angle + dispersion)) * r * 0.5 + 0.5;
    vec2 uvG = vec2(cos(angle), sin(angle)) * r * 0.5 + 0.5;
    vec2 uvB = vec2(cos(angle - dispersion), sin(angle - dispersion)) * r * 0.5 + 0.5;

    vec3 col;
    col.r = texture(samp, uvR).r;
    col.g = texture(samp, uvG).g;
    col.b = texture(samp, uvB).b;

    // Color trail rings
    float rings = sin(r * 40.0 - iTime * 8.0) * 0.5 + 0.5;
    rings = pow(rings, 6.0);
    col += rainbow(r * 3.0 + iTime * 0.3) * rings * tube * (0.4 + mid * 0.6);

    // Wormhole rim glow
    float rim = smoothstep(diameter + 0.1, diameter, r) - tube;
    col += rainbow(angle / TAU + iTime * 0.2) * abs(rim) * (2.0 + air * 3.0);

    // Core singularity
    float core = exp(-r * (8.0 - bass * 5.0));
    col += rainbow(iTime * 0.5) * core * (2.0 + amp_peak * 4.0);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
