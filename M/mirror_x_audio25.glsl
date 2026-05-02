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
    float n = 3.0 + floor(aLow * 5.0);
    for (int i = 0; i < 5; i++) {
        if (float(i) >= n)
            break;
        uv = abs(uv * 2.0 - 1.0);
        uv *= 1.0 + 0.05 * sin(t + float(i) * 1.7) * aMid;
    }
    uv = mirror(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb += aHigh * 0.1 * vec3(sin(t * 2.0), sin(t * 2.5), sin(t * 3.0)) * 0.5 + 0.5;
    color = tex;
}
