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

// Gem bump — fake bump-map highlight using luminance gradient.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 ts = 1.0 / iResolution;
    float l  = dot(texture(samp, tc).rgb,             vec3(0.299, 0.587, 0.114));
    float lx = dot(texture(samp, tc + vec2(ts.x, 0)).rgb, vec3(0.299, 0.587, 0.114));
    float ly = dot(texture(samp, tc + vec2(0, ts.y)).rgb, vec3(0.299, 0.587, 0.114));
    vec3 n = normalize(vec3(l - lx, l - ly, 0.5));
    vec3 ld = normalize(vec3(sin(time_f * 0.4), cos(time_f * 0.4), 0.6));
    float diff = max(dot(n, ld), 0.0);
    vec3 c = texture(samp, tc).rgb;
    color = vec4(c * (0.65 + 0.85 * diff), 1.0);
}
