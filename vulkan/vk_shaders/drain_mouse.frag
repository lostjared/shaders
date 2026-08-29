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




void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    float spiralSpeed = 2.0;
    float inwardSpeed = 0.5;
    float drainRadius = 8.0;
    float loopDuration = 20.0;
    float currentTime = mod(time_f, loopDuration);
    float progress = clamp(currentTime / loopDuration * inwardSpeed, 0.0, 1.0);

    vec2 normCoord = (tc - m) * ar;
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);

    angle += (1.0 - smoothstep(0.0, drainRadius, dist)) * currentTime * spiralSpeed;
    dist *= mix(1.0, 0.0, progress);

    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * dist;
    vec2 uv = spiralCoord / ar + m;

    color = texture(samp, uv);
}
