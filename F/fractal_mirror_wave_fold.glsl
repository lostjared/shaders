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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;

    vec2 uv = tc;
    float waveX = sin(uv.y * 20.0 + t * 3.0 * (1.0 + aLow)) * 0.04 * aMid;
    float waveY = cos(uv.x * 18.0 + t * 2.5 * (1.0 + aHigh)) * 0.04 * aMid;
    uv.x += waveX;
    uv.y += waveY;

    for (int i = 0; i < 4; i++) {
        uv = abs(uv * 2.0 - 1.0);
    }
    uv = mirror(uv);

    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
