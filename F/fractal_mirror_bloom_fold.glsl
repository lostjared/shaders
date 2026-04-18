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
    return 1.0 - abs(1.0 - 2.0 * uv);
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec4 tentBlur3(sampler2D s, vec2 uv, vec2 px) {
    vec4 sum = vec4(0.0);
    float w = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            float wt = (2.0 - abs(float(x))) * (2.0 - abs(float(y)));
            sum += texture(s, uv + vec2(float(x), float(y)) * px) * wt;
            w += wt;
        }
    }
    return sum / w;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);
    vec2 px = 1.0 / iResolution;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);

    float zoom = 1.3 + 0.3 * aLow;
    for (int i = 0; i < 5; i++) {
        uv = abs((uv - ctr) * zoom) + ctr - 0.5;
        uv = rotateUV(uv, t * 0.1 + float(i) * 0.08, ctr, aspect);
    }
    uv = mirror(fract(uv));

    vec4 tex = tentBlur3(samp, uv, px * (1.0 + 2.0 * aLow));

    float glow = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i + 1);
        vec4 blurSample = tentBlur3(samp, uv, px * fi * 3.0);
        glow += dot(blurSample.rgb, vec3(0.299, 0.587, 0.114));
    }
    glow /= 4.0;
    float bloomMask = smoothstep(0.4, 0.9, glow) * (0.3 + 0.3 * aPk);
    tex.rgb += bloomMask * tex.rgb;

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
