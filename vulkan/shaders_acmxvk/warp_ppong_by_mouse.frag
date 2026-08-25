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




float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    vec2 uv = tc;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 d = uv - m;
    float dist = length(d);
    float r = 0.35;
    float w = 1.0 - smoothstep(0.0, r, dist);
    vec2 warp = normalize(d + 1e-5) * sin(dist * 24.0 - time_f * 4.0) * 0.25 * w;

    vec2 warpedCoords = uv + warp;
    warpedCoords.x = pingPong(warpedCoords.x + time_f * 0.05, 1.0);
    warpedCoords.y = pingPong(warpedCoords.y + time_f * 0.05, 1.0);

    color = texture(samp, warpedCoords);
}
