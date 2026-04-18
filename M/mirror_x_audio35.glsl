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
uniform float amp_rms;

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float stripe = sin(uv.y * 40.0 + t * 3.0);
    stripe = step(0.0, stripe);
    vec2 uv1 = uv;
    vec2 uv2 = vec2(1.0 - uv.x, uv.y);
    uv1 += sin(t * 2.0 + uv1.yx * 10.0) * 0.02 * aLow;
    uv2 += cos(t * 1.5 + uv2.yx * 8.0) * 0.02 * aMid;
    vec4 c1 = texture(samp, fract(uv1));
    vec4 c2 = texture(samp, fract(uv2));
    vec4 tex = mix(c1, c2, stripe);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1, 1.0, 1.2), aRms * 0.5);
    color = tex;
}
