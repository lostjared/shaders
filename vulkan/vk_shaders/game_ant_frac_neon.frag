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

// Frac neon — neon-edge highlights via Sobel, low intensity.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 ts = 1.0 / iResolution;
    float gx = lum(texture(samp, tc + vec2( ts.x, 0)).rgb)
             - lum(texture(samp, tc + vec2(-ts.x, 0)).rgb);
    float gy = lum(texture(samp, tc + vec2(0,  ts.y)).rgb)
             - lum(texture(samp, tc + vec2(0, -ts.y)).rgb);
    float e = clamp(length(vec2(gx, gy)) * 6.0, 0.0, 1.0);
    vec3 neon = mix(vec3(1.0, 0.20, 0.85), vec3(0.20, 0.85, 1.0),
                    0.5 + 0.5 * sin(time_f * 0.8));
    color = vec4(c + neon * e * 1.20, 1.0);
}
