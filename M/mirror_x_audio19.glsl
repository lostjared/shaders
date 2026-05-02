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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc;
    if (uv.x < 0.5)
        uv.x = 1.0 - uv.x;
    float stretch = 1.0 + pingPong(t, 2.0) * 0.5 + 0.3 * aLow;
    uv.x = 0.5 + (uv.x - 0.5) * stretch;
    vec2 center = vec2(0.5) * iResolution;
    vec2 texCoord = uv * iResolution;
    vec2 delta = texCoord - center;
    float dist = length(delta);
    float maxR = min(iResolution.x, iResolution.y) * 0.5;
    if (dist < maxR) {
        float factor = pingPong(t + aMid * 2.0, 8.0) * (1.0 - pow(dist / maxR, 2.0));
        texCoord += normalize(delta) * factor * (30.0 + 40.0 * aHigh);
    }
    uv = texCoord / iResolution;
    vec4 tex = texture(samp, fract(uv));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
