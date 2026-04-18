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

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

void main(void) {
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    float dist = length(uv - 0.5);
    float bulge = 1.0 + 0.4 * aLow * smoothstep(0.5, 0.0, dist);
    uv = (uv - 0.5) * bulge + 0.5;
    uv.x += sin(uv.y * 15.0 + t * 3.0) * 0.02 * aMid;
    uv.y += cos(uv.x * 15.0 + t * 2.5) * 0.02 * aHigh;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    float vign = 1.0 - smoothstep(0.3, 0.8, dist);
    tex.rgb *= 0.8 + 0.4 * vign;
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
