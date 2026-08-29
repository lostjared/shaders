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

// CGA cyan/magenta/white palette - DOS era vibe.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 p0 = vec3(0.0, 0.0, 0.0);
    vec3 p1 = vec3(0.0, 1.0, 1.0);
    vec3 p2 = vec3(1.0, 0.0, 1.0);
    vec3 p3 = vec3(1.0, 1.0, 1.0);
    vec3 q;
    if (lum < 0.25)      q = p0;
    else if (lum < 0.5)  q = p1;
    else if (lum < 0.75) q = p2;
    else                 q = p3;
    color = vec4(q, 1.0);
}
