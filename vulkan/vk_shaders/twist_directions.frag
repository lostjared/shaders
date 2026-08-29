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
layout(set = 0, binding = 0) uniform sampler2D samp;



vec2 twist(vec2 coord, float twistAmount, float time, float direction) {
    float r = length(coord);
    float theta = atan(coord.y, coord.x);
    theta += (1.0 - r) * twistAmount * sin(time * direction);
    return vec2(cos(theta), sin(theta)) * r;
}

void main(void) {
    vec2 normCoord = gl_FragCoord.xy / iResolution.xy;

    vec2 centeredCoord = normCoord - vec2(0.5, 0.5);
    centeredCoord.x *= iResolution.x / iResolution.y;

    vec2 twistClockwise = twist(centeredCoord, 15.0, time_f, 1.0);

    vec2 twistCounterClockwise = twist(centeredCoord, 15.0, time_f, -1.0);

    twistClockwise.x *= iResolution.y / iResolution.x;
    twistCounterClockwise.x *= iResolution.y / iResolution.x;

    twistClockwise += vec2(0.5, 0.5);
    twistCounterClockwise += vec2(0.5, 0.5);
    vec4 texColorClockwise = texture(samp, twistClockwise);
    vec4 texColorCounterClockwise = texture(samp, twistCounterClockwise);

    color = mix(texColorClockwise, texColorCounterClockwise, 0.5);
}
