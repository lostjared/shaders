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

// Stylized minimap-style overlay: blue grade, grid lines, soft radial glow.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 blue = mix(vec3(0.02, 0.08, 0.18), vec3(0.45, 0.85, 1.2), lum);
    vec2 g = abs(fract(tc * vec2(20.0, 12.0)) - 0.5);
    float grid = smoothstep(0.48, 0.5, max(g.x, g.y));
    float ping = 0.5 + 0.5 * sin(time_f * 2.0 - length(tc - 0.5) * 18.0);
    blue += vec3(0.1, 0.3, 0.5) * grid;
    blue += vec3(0.1, 0.4, 0.6) * pow(ping, 4.0) * 0.4;
    color = vec4(blue, 1.0);
}
