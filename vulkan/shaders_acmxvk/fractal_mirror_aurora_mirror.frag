#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp ext.u1.y
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










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
