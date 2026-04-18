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

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

vec2 sineFold(vec2 uv, float t, float strength, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        float fi = float(i);
        p.x += strength * sin(p.y * (6.0 + fi * 2.3) + t * (0.9 + fi * 0.4));
        p.y += strength * cos(p.x * (5.0 + fi * 1.7) + t * (1.1 + fi * 0.3));
        p = fract(p);
    }
    return p;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float pulse = 1.0 + 0.3 * aLow * sin(t * 3.5);
    uv = (uv - 0.5) * pulse + 0.5;

    float strength = 0.03 + 0.05 * aMid;
    int iters = 4 + int(aPk * 4.0);
    uv = sineFold(uv, t, strength, iters);
    uv = mirror(uv);

    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.2, 0.95, 1.1 + aHigh * 0.2), aPk);
    color = tex;
}
