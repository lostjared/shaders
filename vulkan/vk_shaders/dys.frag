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



vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255;
    }
    icolor.a = 1.0;
return icolor;
}

void main() {
    vec2 uv = tc;
    float timeOffset = 0.05 * sin(time_f);
    vec3 redLayer = texture(samp, uv + vec2(timeOffset, 0.0)).rgb;
    vec3 greenLayer = texture(samp, uv).rgb;
    vec3 blueLayer = texture(samp, uv - vec2(timeOffset, 0.0)).rgb;
    bool strobe = mod(floor(time_f * 2.0), 2.0) > 0.5;
    vec3 rgbStrobe = vec3(
        strobe ? redLayer.r : blueLayer.r,
        greenLayer.g,
        strobe ? blueLayer.b : redLayer.b
    );
    vec4 echoEffect = texture(samp, uv + vec2(0.01 * sin(time_f), 0.01 * cos(time_f)));
    vec4 modified = mix(vec4(rgbStrobe, 1.0), echoEffect, 0.5);
    vec4 original = texture(samp, uv);
    color = xor_RGB(original, modified);
}
