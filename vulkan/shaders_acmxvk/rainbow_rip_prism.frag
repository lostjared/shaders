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


vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float time_z = pingPong(time_f, 4.0) + 0.5;
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 normPos = uv * 2.0 - 1.0 * time_z;
    float dist = length(normPos);
    float phase = sin(dist * 10.0 - time_f * 4.0);
    vec2 tcAdjusted = tc + (normPos * 0.305 * phase);
    float dispersionScale = 0.02;
    vec2 dispersionOffset = normPos * dist * dispersionScale;
    vec2 tcAdjustedR = tcAdjusted + dispersionOffset * (-1.0);
    vec2 tcAdjustedG = tcAdjusted;
    vec2 tcAdjustedB = tcAdjusted + dispersionOffset * 1.0;
    float r = texture(samp, tcAdjustedR).r;
    float g = texture(samp, tcAdjustedG).g;
    float b = texture(samp, tcAdjustedB).b;
    vec3 texColor = vec3(r, g, b);
    float angle = atan(normPos.y, normPos.x);
    float spiral = angle + time_f * 1.0;
    float hue = mod(spiral / (2.0 * 3.14159265), 1.0);
    vec3 rainbowColor = hsv2rgb(vec3(hue, 1.0, 1.0));
    vec3 finalColor = texColor * rainbowColor;
    float time_t = pingPong(time_f, 8.0) + 2.0;
    color = vec4(sin(finalColor * time_t), 1.0);
}

