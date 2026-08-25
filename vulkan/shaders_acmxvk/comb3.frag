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



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec2 rotateUV(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    uv -= 0.5;
    uv = mat2(c, -s, s, c) * uv;
    uv += 0.5;
    return uv;
}

vec2 reflectUV(vec2 uv, float segments) {
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    float radius = length(uv - vec2(0.5));
    float segmentAngle = 2.0 * 3.14159265359 / segments;
    angle = mod(angle, segmentAngle);
    angle = abs(angle - segmentAngle * 0.5);
    return vec2(cos(angle), sin(angle)) * radius + 0.5;
}

vec2 fractalZoom(vec2 uv, float zoom, float time) {
    for (int i = 0; i < 5; i++) {
        uv = abs(uv * zoom) - 0.5;
        uv = rotateUV(uv, time * 0.1);
    }
    return uv;
}

void main() {
    vec2 uv = tc * iResolution / vec2(iResolution.y);
vec4 originalTexture = texture(samp, tc);
    vec2 kaleidoUV = reflectUV(uv, 6.0);
    float zoom = 1.5 + 0.5 * sin(time_f * 0.5);
    kaleidoUV = fractalZoom(kaleidoUV, zoom, time_f);
    kaleidoUV = rotateUV(kaleidoUV, time_f * 0.2);
    vec4 kaleidoColor = texture(samp, kaleidoUV);
    float blendFactor = 0.6;
    vec4 blendedColor = mix(kaleidoColor, originalTexture, blendFactor);

    blendedColor.rgb *= 0.5 + 0.5 * sin(kaleidoUV.xyx + time_f);

    color = sin(blendedColor * pingPong(time_f, 10.0));
    vec4 t = texture(samp, tc);
    color = color * t * 0.8;
    color = sin(color * pingPong(time_f, 15.0));
    color.a = 1.0;
}
