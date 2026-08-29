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

// Cel-shaded anime look: posterized luminance + soft edge darkening.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;

    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float steps = 5.0;
    float bin = floor(lum * steps) / steps + 0.5 / steps;
    vec3 quant = c * (bin / max(lum, 0.001));

    float gx = dot(texture(samp, tc + vec2(px.x, 0.0)).rgb - texture(samp, tc - vec2(px.x, 0.0)).rgb, vec3(0.333));
    float gy = dot(texture(samp, tc + vec2(0.0, px.y)).rgb - texture(samp, tc - vec2(0.0, px.y)).rgb, vec3(0.333));
    float edge = 1.0 - smoothstep(0.05, 0.18, sqrt(gx*gx + gy*gy));
    color = vec4(quant * edge, 1.0);
}
