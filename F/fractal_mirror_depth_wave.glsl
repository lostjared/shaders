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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = tc;

    float waveX = sin(uv.y * 12.0 + t * 1.5 + aLow * 3.0) * 0.04 * aRms;
    float waveY = cos(uv.x * 10.0 + t * 1.2) * 0.03 * aMid;
    uv += vec2(waveX, waveY);

    for (int i = 0; i < 4; i++) {
        uv = abs(uv * 2.0 - 1.0);
        uv = rotateUV(uv, t * 0.08 + float(i) * 0.1 + aPk * 0.3, vec2(0.5), aspect);
    }
    uv = mirror(uv);

    float depth = sin(length(uv - 0.5) * 20.0 - t * 3.0) * 0.5 + 0.5;
    float depthWarp = depth * 0.04 * aLow;
    uv += (uv - 0.5) * depthWarp;
    uv = clamp(uv, 0.0, 1.0);

    vec4 tex = texture(samp, uv);
    tex.rgb *= 0.9 + depth * 0.3;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
