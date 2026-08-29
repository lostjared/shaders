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










void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float stripe = sin(uv.y * 40.0 + t * 3.0);
    stripe = step(0.0, stripe);
    vec2 uv1 = uv;
    vec2 uv2 = vec2(1.0 - uv.x, uv.y);
    uv1 += sin(t * 2.0 + uv1.yx * 10.0) * 0.02 * aLow;
    uv2 += cos(t * 1.5 + uv2.yx * 8.0) * 0.02 * aMid;
    vec4 c1 = texture(samp, fract(uv1));
    vec4 c2 = texture(samp, fract(uv2));
    vec4 tex = mix(c1, c2, stripe);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1, 1.0, 1.2), aRms * 0.5);
    color = tex;
}
