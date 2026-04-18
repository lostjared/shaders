#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float dist = length(uv - 0.5);
    float ring = sin(dist * 25.0 - t * 4.0) * 0.5 + 0.5;
    ring *= aLow;
    uv += (uv - 0.5) * ring * 0.15;
    uv = mirror(uv);
    vec4 tex = texture(samp, uv);
    float neon = smoothstep(0.3, 0.0, abs(dist - 0.25 - 0.1 * aMid));
    tex.rgb += neon * vec3(0.0, aHigh, 1.0) * 0.4;
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
