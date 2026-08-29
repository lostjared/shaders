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

// Crystal pulse — gentle facet brightness pulse on highlights.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float pulse = 0.5 + 0.5 * sin(time_f * 1.4);
    float facet = smoothstep(0.40, 0.95, lum) * pulse;
    vec3 crystal = c + vec3(0.45, 0.70, 1.10) * facet * 0.65;
    crystal *= 1.0 + pulse * 0.10;
    color = vec4(crystal, 1.0);
}
