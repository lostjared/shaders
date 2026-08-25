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


    c.x = fract(c.x);
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 uv = tc;
    float timeScale = 0.2;
    float spatialScale = 3.0;
    float hue = (uv.x + uv.y) * spatialScale + time_f * timeScale;

    vec3 colorHue = hsv2rgb(vec3(hue, 1.0, 1.0));
    vec4 texColor = texture(samp, uv);
    vec4 finalColor = vec4(texColor.rgb * colorHue, texColor.a);
    color = finalColor;
}
