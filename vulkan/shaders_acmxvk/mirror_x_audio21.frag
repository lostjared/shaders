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
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;









vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc;
    vec2 uv1 = 1.0 - abs(1.0 - 2.0 * uv);
    vec2 uv2 = mirror(uv * (2.0 + aLow));
    float blend = 0.5 + 0.5 * sin(t * 2.0) * aMid;
    vec2 final_uv = mix(uv1, uv2, blend);
    float pixelate = 1.0 + floor(amp_smooth * 100.0);
    final_uv = floor(final_uv * pixelate) / pixelate;
    vec4 tex = texture(samp, final_uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
