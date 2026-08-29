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
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc * iResolution.xy;
    float cols = 3.0 + floor(aLow * 3.0);
    float rows = 2.0 + floor(aMid * 2.0);
    vec2 sectionSize = iResolution / vec2(cols, rows);
    vec2 idx = floor(uv / sectionSize);
    vec2 local = mod(uv, sectionSize) / sectionSize;
    float dir = mod(idx.x + idx.y, 2.0) * 2.0 - 1.0;
    float angle = dir * (t * (1.0 + aHigh) + length(idx) * 0.7);
    local = rot(angle) * (local - 0.5) + 0.5;
    local = mirror(local);
    vec2 texCoord = (idx + local) * sectionSize / iResolution.xy;
    color = texture(samp, texCoord);
    color.rgb *= 1.0 + amp_peak * 0.5;
}
