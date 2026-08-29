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

// Cool snowy / frostbite tint with sparkle highlights.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float h21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c *= vec3(0.85, 0.95, 1.10);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float sparkle = step(0.995, h21(gl_FragCoord.xy + floor(time_f * 8.0))) * smoothstep(0.6, 1.0, lum);
    c += sparkle * vec3(0.6, 0.8, 1.0);
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
