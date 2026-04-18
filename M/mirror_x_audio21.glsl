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
    float t = time_f;
    vec2 uv = tc;
    vec2 uv1 = 1.0 - abs(1.0 - 2.0 * uv);
    vec2 uv2 = mirror(uv * (2.0 + aLow));
    float blend = 0.5 + 0.5 * sin(t * 2.0) * aMid;
    vec2 final_uv = mix(uv1, uv2, blend);
    float pixelate = 1.0 + floor(amp_smooth * 100.0);
    final_uv = floor(final_uv * pixelate) / pixelate;
    vec4 tex = texture(samp, final_uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
