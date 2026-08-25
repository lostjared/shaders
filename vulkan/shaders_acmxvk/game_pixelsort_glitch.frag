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

// Vertical pixel-sort style glitch: bright bands smear downward in time.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    float colId = floor(tc.x * iResolution.x / 3.0);
    float trig = hash(colId + floor(time_f * 1.5));
    vec2 uv = tc;
    if (trig > 0.85) {
        float drag = fract(tc.y + time_f * 0.6) * 0.25;
        uv.y = clamp(tc.y - drag, 0.0, 1.0);
    }
    vec3 c = texture(samp, uv).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c += vec3(0.3, 0.0, 0.4) * (trig > 0.85 ? lum : 0.0) * 0.4;
    color = vec4(c, 1.0);
}
