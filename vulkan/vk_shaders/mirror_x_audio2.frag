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









mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    vec2 uv = tc * iResolution.xy;
    float tileSize = mix(80.0, 200.0, aLow);
    vec2 idx = floor(uv / tileSize);
    vec2 local = mod(uv, tileSize) / tileSize;
    float angle = time_f * (1.0 + aHigh * 2.0) + length(idx) * 0.5;
    local = rot(angle) * (local - 0.5) + 0.5;
    local = mirror(local);
    vec2 texCoord = (idx + local) * tileSize / iResolution.xy;
    color = texture(samp, texCoord);
    color.rgb *= 1.0 + amp_peak * 0.4;
}
