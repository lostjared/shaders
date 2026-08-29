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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main() {
    vec2 uv = tc;

    float trailStrength = 0.05;
    float strobeSpeed = sin(time_f * 10.0);

    vec2 trailOffsetR = vec2(trailStrength * strobeSpeed, 0.0);
    vec2 trailOffsetG = vec2(-trailStrength * strobeSpeed, trailStrength * strobeSpeed);
    vec2 trailOffsetB = vec2(0.0, -trailStrength * strobeSpeed);

    vec3 rgbTrail = vec3(
        texture(samp, uv + trailOffsetR).r,
        texture(samp, uv + trailOffsetG).g,
        texture(samp, uv + trailOffsetB).b
    );

    float strobe = 0.5 + 0.5 * sin(time_f * 20.0);
    vec3 baseColor = texture(samp, uv).rgb;

    color = vec4(mix(baseColor, rgbTrail, strobe), 1.0);
}

