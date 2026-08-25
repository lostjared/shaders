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
#define amp ext.u1.y
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp; 







uniform vec4 iDate;


uniform vec3 iChannelResolution[4];



const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    vec4 tex = texture(samp, tc);

    float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

    float tHue = time_f * 0.15;
    float hueBase = fract(lum * 0.8 + tHue);

    vec3 neon1 = hsv2rgb(vec3(hueBase, 1.0, 1.0));
    vec3 neon2 = hsv2rgb(vec3(fract(hueBase + 0.33), 1.0, 1.0));

    float wave = pingPong(time_f * 0.25, 1.0);
    vec3 neon = mix(neon1, neon2, wave);

    float strength = 0.3 + 0.7 * wave;

    vec3 mixed = mix(tex.rgb, neon, strength);

    mixed = pow(mixed, vec3(0.8));
    mixed = clamp(mixed, 0.0, 1.0);

    color = vec4(mixed, tex.a);
}
