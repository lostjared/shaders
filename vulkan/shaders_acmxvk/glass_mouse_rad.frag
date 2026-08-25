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
layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 c = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    float distortionStrength = 0.25;
    float noiseFactor = sin(uv.x * 10.0 + time_f) * cos(uv.y * 10.0 + time_f);

    float radius = 0.75; 
    float w = 1.0 - smoothstep(0.0, radius, length(uv - c));

    vec2 dir = normalize(uv - c + 1e-5);
    vec2 distortedCoord = uv + distortionStrength * noiseFactor * w * dir;

    distortedCoord = clamp(distortedCoord, 0.0, 1.0);
    color = texture(samp, distortedCoord);
}
