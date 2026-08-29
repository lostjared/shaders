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

// Diamond storm — sparse animated specular sparkles on highlights.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 g = floor(tc * iResolution / 6.0);
    float h = hash(g);
    float spark = step(0.965, h) * smoothstep(0.35, 0.9, lum);
    spark *= 0.5 + 0.5 * sin(time_f * 8.0 + h * 40.0);
    color = vec4(c + vec3(spark) * 1.6, 1.0);
}
