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
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float a = clamp(amp * 0.5, 0.0, 1.0);
    float pulse = 1.0 + 0.3 * aLow * sin(time_f * 4.0);
    uv = (uv - 0.5) * pulse + 0.5;
    uv = mirror(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.2, 0.9, 1.1 + aMid * 0.3), a);
    color = tex;
}
