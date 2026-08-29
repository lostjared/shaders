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

// Metal pulse — global rhythmic brightness pulse, gentle.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float pulse = 1.0 + 0.22 * sin(time_f * 1.6);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float hi = smoothstep(0.4, 0.95, lum);
    color = vec4(c * pulse + vec3(0.95, 0.95, 1.0) * hi * 0.40 * pulse, 1.0);
}
