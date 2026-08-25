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

// Metal aurora — green/violet aurora ribbons drifting overhead, edge-faded.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float band = sin(tc.x * 6.0 + time_f * 0.5 + sin(tc.y * 3.0 + time_f * 0.2) * 1.5);
    band = band * 0.5 + 0.5;
    float top = smoothstep(0.7, 0.0, tc.y);
    vec3 a = mix(vec3(0.10, 0.95, 0.50), vec3(0.65, 0.30, 1.10), band);
    color = vec4(c + a * top * 0.55, 1.0);
}
