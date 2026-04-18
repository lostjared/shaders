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
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        uv.x += sin(uv.y * (8.0 + fi * 3.0) + t * (1.0 + aLow)) * 0.03;
        uv.y += cos(uv.x * (7.0 + fi * 2.5) + t * (0.8 + aMid)) * 0.03;
        uv = mirror(uv);
    }
    vec4 tex = texture(samp, uv);
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.2, 0.9, 1.1), aHigh * 0.5);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
