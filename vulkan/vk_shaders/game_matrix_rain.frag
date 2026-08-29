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

// Matrix-style green rain code overlay on top of the source.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 src = texture(samp, tc).rgb;
    float lum = dot(src, vec3(0.299, 0.587, 0.114));

    float colW = 12.0;
    float rowH = 14.0;
    float colId = floor(tc.x * iResolution.x / colW);
    float speed = 0.4 + hash(vec2(colId, 1.0)) * 1.6;
    float yPos = fract(tc.y + time_f * speed * 0.15 + hash(vec2(colId, 7.0)));
    float row = floor(yPos * iResolution.y / rowH);
    float ch = hash(vec2(colId, row + floor(time_f * 8.0)));
    float head = smoothstep(0.0, 0.05, yPos) * smoothstep(0.20, 0.0, yPos);
    float tail = smoothstep(0.6, 0.0, yPos);
    float gly = step(0.5, ch);
    float bright = max(head * 1.4, tail * 0.6) * gly;
    vec3 green = vec3(0.1, 1.0, 0.25) * bright;
    color = vec4(src * 0.45 + green, 1.0);
}
