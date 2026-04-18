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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc;
    float split = 0.5 + 0.2 * sin(t * 0.5) * aLow;
    if (uv.x < split) {
        uv.x = split - uv.x;
    } else {
        uv.x = uv.x - split;
    }
    uv.x = uv.x / (1.0 - split + 0.001);
    float wave = sin(uv.y * 20.0 + t * 3.0) * 0.02 * aHigh;
    uv.x += wave;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.4;
    color = tex;
}
