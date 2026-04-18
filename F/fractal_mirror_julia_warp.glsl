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

float fractalJulia(vec2 z, vec2 c, int iterations) {
    float m = 0.0;
    for (int i = 0; i < iterations; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > 4.0) {
            m = float(i) / float(iterations);
            break;
        }
    }
    return m;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 z = (uv - 0.5) * 3.0 * vec2(aspect, 1.0);
    vec2 c = vec2(-0.7 + 0.2 * sin(t * 0.3) * aLow, 0.27 + 0.1 * cos(t * 0.25) * aMid);

    float fracVal = fractalJulia(z, c, 40);
    vec2 warp = uv + fracVal * 0.15 * (1.0 + aPk);
    warp = mirror(warp);

    vec4 tex = texture(samp, warp);
    tex.rgb *= 1.0 + fracVal * 0.5;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
