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
#define alpha ext.u0.x
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

float smoothNoise(vec2 uv) {
    return sin(uv.x * 12.0 + uv.y * 14.0 + time_f * 0.8) * 0.5 + 0.5;
}

void main(void) {
    vec2 uv = (tc * iResolution - 0.5 * iResolution) / iResolution.y;
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);
    float swirl = sin(time_f * 0.4) * 2.0;
    angle += swirl * radius * 1.5;

    float modRadius = pingPong(radius + time_f * 0.3, 0.8);
    float wave = sin(radius * 12.0 - time_f * 3.0) * 0.5 + 0.5;

    float cloudNoise = smoothNoise(uv * 3.0 + vec2(modRadius, angle * 0.5));
    cloudNoise += smoothNoise(uv * 6.0 - vec2(time_f * 0.2, time_f * 0.1));
    cloudNoise = pow(cloudNoise, 1.5);
    float r = sin(angle * 3.0 + modRadius * 8.0 + wave * 2.0) * cloudNoise;
    float g = sin(angle * 5.0 - modRadius * 6.0 + wave * 4.0) * cloudNoise;
    float b = sin(angle * 7.0 + modRadius * 10.0 - wave * 3.0) * cloudNoise;
    
    vec3 col = vec3(r, g, b) * 0.5 + 0.5;
    vec3 texColor = texture(samp, tc).rgb;
    col = mix(col, texColor, 0.25);
    color = vec4(sin(col * pingPong(time_f * 1.5, 6.0) + 1.5), alpha);
}

