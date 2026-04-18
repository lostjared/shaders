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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);

    uv.x += sin(uv.y * 8.0 + t * 0.5) * 0.03 * aLow;
    uv.y += cos(uv.x * 6.0 + t * 0.3) * 0.02 * aMid;

    for (int i = 0; i < 3; i++) {
        uv = abs(uv * 2.0 - 1.0);
    }
    uv = mirror(uv);

    vec4 tex = texture(samp, uv);

    float curtain = uv.y + sin(uv.x * 10.0 + t * 1.5) * 0.1;
    float hue = fract(curtain * 0.3 + t * 0.02);
    vec3 aurora = hsv2rgb(vec3(hue, 0.5, 0.9));
    float auroraMask = smoothstep(0.3, 0.7, curtain) * (0.3 + 0.2 * aHigh);
    tex.rgb = mix(tex.rgb, tex.rgb * aurora * 1.8, auroraMask);

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
