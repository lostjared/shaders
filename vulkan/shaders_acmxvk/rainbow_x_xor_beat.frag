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










vec4 xor_RGB(vec4 icolor, vec3 source) {
    ivec3 int_color;
    ivec3 isource = ivec3(source * 255);
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

vec2 smoothRandom2(float t) {
    vec2 r0 = -1.0 + 2.0 * fract(sin(vec2(dot(vec2(floor(t)), vec2(127.1, 311.7)),
                                            dot(vec2(floor(t)), vec2(269.5, 183.3)))) * 43758.5453123);
    vec2 r1 = -1.0 + 2.0 * fract(sin(vec2(dot(vec2(floor(t) + 1.0), vec2(127.1, 311.7)),
                                            dot(vec2(floor(t) + 1.0), vec2(269.5, 183.3)))) * 43758.5453123);
    return mix(r0, r1, smoothstep(0.0, 1.0, fract(t)));
}

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0) * 0.5 + 0.5;
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

    float time_t = pingPong(time_f, 15.0) + 1.0;
    float wave = sin(uv.x * (10.0 + aLow * 10.0) + time_t * 2.0) * (0.1 + aPk * 0.2);
    vec2 random_direction = smoothRandom2(time_t) * (0.5 + aSmth * 0.5);
    float expand = 0.5 + 0.5 * sin(time_t * 2.0) + aLow * 0.4;
    vec2 spiral_uv = uv * expand + random_direction;

    float rotation_period = 3.0;
    float rotation_angle = mod(time_f, rotation_period * 2.0) < rotation_period ? time_t : -time_t;
    rotation_angle *= (1.0 + aSmth);

    float angle = atan(spiral_uv.y + wave, spiral_uv.x) + rotation_angle * 2.0;
    vec3 rainbow_color = rainbow(angle / 6.28318 + aHigh * 0.5);

    vec4 original_color = texture(samp, tc);

    float xorIntensity = 0.6 + aPk * 0.4;
    vec4 xored = xor_RGB(original_color, rainbow_color * xorIntensity);

    vec3 finalColor = mix(original_color.rgb, xored.rgb, 0.5 + aMid * 0.3);
    finalColor *= 1.0 + aPk * 0.5;

    color = vec4(finalColor, 1.0);
}
