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

void main(void) {
    vec2 uv = tc;
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    if (uv.x < 0.5) uv.x = 1.0 - uv.x;
    if (uv.y < 0.5) uv.y = 1.0 - uv.y;
    float dist = length(uv - 0.5);
    float wave = sin(dist * 20.0 - time_f * 3.0) * 0.02 * aLow;
    uv += wave;
    vec4 tex = texture(samp, uv);
    float glow = smoothstep(0.4, 0.0, dist) * aMid * 0.5;
    tex.rgb += glow * vec3(0.3, 0.6, 1.0);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
