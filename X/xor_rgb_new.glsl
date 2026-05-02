#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
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
