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

// Metal chrome — cool desaturated chrome look with rim brighten.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(vec3(lum), c, 0.30) * vec3(0.93, 0.99, 1.14);
    vec2 p = tc - 0.5;
    float rim = smoothstep(0.20, 0.65, length(p));
    chrome += vec3(0.20, 0.25, 0.35) * rim;
    color = vec4(chrome, 1.0);
}
