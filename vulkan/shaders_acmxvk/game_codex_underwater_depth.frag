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

// Underwater depth: caustic wobble, blue grade, and depth haze.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc;
    float caustic = sin(uv.x * 38.0 + sin(uv.y * 16.0 + time_f) * 3.0 + time_f * 2.0);
    caustic += sin((uv.x + uv.y) * 29.0 - time_f * 1.5);
    uv += vec2(caustic * 0.004, sin(uv.x * 22.0 + time_f * 1.7) * 0.006);
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float depth = smoothstep(0.0, 1.0, tc.y);
    c = mix(c, vec3(0.02, 0.22, 0.42), 0.38 + depth * 0.25);
    c += vec3(0.1, 0.55, 0.8) * max(0.0, caustic) * 0.07;
    color = vec4(c, 1.0);
}
