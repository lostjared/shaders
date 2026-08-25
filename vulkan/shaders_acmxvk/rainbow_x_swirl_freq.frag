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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;










vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float t = pingPong(time_f, 15.0) + 1.0;
    float wave = sin(uv.x * (10.0 + aLow * 8.0) + t * 2.0) * (0.1 + aLow * 0.15);
    float expand = 0.5 + 0.5 * sin(t * 2.0) + aMid * 0.4;
    vec2 spiral_uv = uv * expand + vec2(cos(t), sin(t)) * (0.2 + aSmth * 0.3);

    float angle = atan(spiral_uv.y + wave, spiral_uv.x) + t * 2.0;

    vec3 rainLow  = rainbow(angle / 6.28318 + 0.0);
    vec3 rainMid  = rainbow(angle / 6.28318 + 0.33);
    vec3 rainHigh = rainbow(angle / 6.28318 + 0.66);

    vec3 rainbow_color = rainLow * (0.3 + aLow * 0.7)
                       + rainMid * (0.3 + aMid * 0.7)
                       + rainHigh * (0.3 + aHigh * 0.7);
    rainbow_color = clamp(rainbow_color, 0.0, 1.0);

    vec4 tex = texture(samp, tc);
    vec3 blended = mix(tex.rgb, rainbow_color, 0.5);

    blended *= 1.0 + aPk * 0.6;

    color = vec4(sin(blended * t), tex.a);
}
