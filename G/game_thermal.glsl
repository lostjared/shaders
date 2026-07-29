#version 330 core
// Thermal/IR vision palette mapped from luminance.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec3 thermalRamp(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c0 = vec3(0.00, 0.00, 0.10);
    vec3 c1 = vec3(0.10, 0.00, 0.55);
    vec3 c2 = vec3(0.85, 0.10, 0.65);
    vec3 c3 = vec3(1.00, 0.55, 0.10);
    vec3 c4 = vec3(1.00, 0.95, 0.55);
    if (t < 0.25) return mix(c0, c1, t / 0.25);
    if (t < 0.5)  return mix(c1, c2, (t - 0.25) / 0.25);
    if (t < 0.75) return mix(c2, c3, (t - 0.5)  / 0.25);
    return mix(c3, c4, (t - 0.75) / 0.25);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    color = vec4(thermalRamp(lum), 1.0);
}
