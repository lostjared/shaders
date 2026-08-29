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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

// Lens flare anamorphic streak when bright pixels are present.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 streak = vec3(0.0);
    float total = 0.0;
    for (int i = -8; i <= 8; ++i) {
        vec3 s = texture(samp, tc + vec2(float(i) * px.x * 3.0, 0.0)).rgb;
        float bright = max(0.0, max(s.r, max(s.g, s.b)) - 0.75);
        float w = exp(-float(i*i) * 0.05);
        streak += s * bright * w;
        total += w;
    }
    streak /= max(total, 0.001);
    streak *= vec3(0.5, 0.7, 1.0);
    color = vec4(c + streak * 0.7, 1.0);
}
