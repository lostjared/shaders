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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




void main() {
    vec2 uv = tc;
    vec2 m = (iMouse.z > 0.5 ? iMouse.xy : 0.5 * iResolution) / iResolution;
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 p = (uv - m);
    float r = length(p * ar);
    float mask = smoothstep(0.5, 0.0, r);

    float timeOffset = 0.05 * sin(time_f);
    vec3 redLayer = texture(samp, uv + vec2(timeOffset, 0.0)).rgb;
    vec3 greenLayer = texture(samp, uv).rgb;
    vec3 blueLayer = texture(samp, uv - vec2(timeOffset, 0.0)).rgb;

    bool strobe = mod(floor(time_f * 2.0), 2.0) > 0.5;
    vec3 rgbStrobe = vec3(
        strobe ? redLayer.r : blueLayer.r,
        greenLayer.g,
        strobe ? blueLayer.b : redLayer.b
    );

    vec2 dir = normalize(p + 1e-6);
    vec4 echoEffect = texture(samp, uv + dir * (0.015 + 0.005 * sin(time_f * 2.0)));
    vec4 fx = mix(vec4(rgbStrobe, 1.0), echoEffect, 0.5);

    vec4 base = texture(samp, uv);
    color = mix(base, fx, mask);
}
