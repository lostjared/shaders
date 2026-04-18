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

vec2 rotate2D(vec2 p, float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c) * p;
}

vec2 swirl(vec2 uv, vec2 center, float radius, float strength) {
    float dist = distance(uv, center);
    if (dist < radius) {
        float percent = (radius - dist) / radius;
        float theta = percent * percent * strength;
        uv = rotate2D(uv - center, theta) + center;
    }
    return uv;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float swirlStr = sin(t * 0.8) * 5.0 * (1.0 + aLow * 2.0);
    float swirlRad = 0.6 + 0.3 * aMid;
    uv = swirl(uv, vec2(0.5), swirlRad, swirlStr);

    for (int i = 0; i < 3; i++) {
        uv = abs(uv * 2.0 - 1.0);
        uv = rotate2D(uv - 0.5, t * 0.1 + float(i) * 0.3) + 0.5;
    }
    uv = mirror(uv);

    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0 - aLow * 0.1, 1.0 + aHigh * 0.3), aPk);
    color = tex;
}
