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

// PSX-style dithered low-bit color.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float bayer[16] = float[](
        0.0, 8.0, 2.0,10.0,
       12.0, 4.0,14.0, 6.0,
        3.0,11.0, 1.0, 9.0,
       15.0, 7.0,13.0, 5.0);
    int idx = int(mod(gl_FragCoord.x, 4.0)) + int(mod(gl_FragCoord.y, 4.0)) * 4;
    float t = (bayer[idx] / 16.0 - 0.5) / 16.0;
    c += t;
    c = floor(c * 16.0) / 15.0;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
