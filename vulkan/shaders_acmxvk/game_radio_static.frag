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

// Lost-signal radio static: heavy noise, occasional roll bar, mono mix.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float n = hash(gl_FragCoord.xy + time_f * 60.0);
    float bar = smoothstep(0.04, 0.0, abs(fract(tc.y - time_f * 0.3) - 0.5));
    vec3 mono = vec3(lum * 0.5 + n * 0.6);
    mono += bar * 0.4;
    color = vec4(mono, 1.0);
}
