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

// Subtle CRT curvature with scanlines and mild RGB mask. Good for retro games.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    vec2 off = uv.yx * uv.yx;
    uv += uv * off * 0.05;
    uv = uv * 0.5 + 0.5;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    vec3 c = texture(samp, uv).rgb;
    float scan = 0.92 + 0.08 * sin(uv.y * iResolution.y * 3.14159);
    float mask = mod(gl_FragCoord.x, 3.0);
    vec3 rgbMask = vec3(mask < 1.0 ? 1.05 : 0.95,
                        mask < 2.0 && mask >= 1.0 ? 1.05 : 0.95,
                        mask >= 2.0 ? 1.05 : 0.95);
    c *= scan * rgbMask;
    color = vec4(c, 1.0);
}
