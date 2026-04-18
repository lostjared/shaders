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
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc;
    float hMirror = step(0.5, uv.x);
    uv.x = mix(1.0 - uv.x, uv.x, hMirror);
    float vMirror = step(0.5, uv.y);
    uv.y = mix(1.0 - uv.y, uv.y, vMirror);
    float glitch = floor(uv.y * (10.0 + 20.0 * aHigh));
    float offset = sin(glitch * 43.758 + t * 5.0) * 0.03 * aMid;
    uv.x += offset;
    uv.y += sin(t * 7.0 + uv.x * 15.0) * 0.005 * aLow;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
