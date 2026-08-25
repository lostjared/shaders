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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(rand(i + vec2(0.0, 0.0)), rand(i + vec2(1.0, 0.0)), u.x),
               mix(rand(i + vec2(0.0, 1.0)), rand(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main(void) {
    vec2 uv = tc;
    float glitchStrength = 0.01;
    float timeNoise = noise(uv * 10.0 + time_f * 0.5);
    uv.x += (rand(uv + time_f) - 0.5) * glitchStrength;
    uv.y += (rand(uv + time_f * 1.5) - 0.5) * glitchStrength;
    vec4 texColor = texture(samp, uv);
    vec4 colorShift = vec4(texColor.r, texColor.g * 0.5 + 0.5 * timeNoise, texColor.b * 0.5 + 0.5 * (1.0 - timeNoise), texColor.a);
    float glitchNoise = rand(uv + time_f);
    vec4 glitchColor = vec4(vec3(sin(glitchNoise * time_f)), 1.0) * glitchStrength ;
    color = mix(colorShift, glitchColor, glitchStrength * glitchNoise);
    color = sin(color * time_f);
    color.a = 1.0;
}
