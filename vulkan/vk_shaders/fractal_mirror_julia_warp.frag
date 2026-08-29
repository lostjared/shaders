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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

float fractalJulia(vec2 z, vec2 c, int iterations) {
    float m = 0.0;
    for (int i = 0; i < iterations; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > 4.0) {
            m = float(i) / float(iterations);
            break;
        }
    }
    return m;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 z = (uv - 0.5) * 3.0 * vec2(aspect, 1.0);
    vec2 c = vec2(-0.7 + 0.2 * sin(t * 0.3) * aLow, 0.27 + 0.1 * cos(t * 0.25) * aMid);

    float fracVal = fractalJulia(z, c, 40);
    vec2 warp = uv + fracVal * 0.15 * (1.0 + aPk);
    warp = mirror(warp);

    vec4 tex = texture(samp, warp);
    tex.rgb *= 1.0 + fracVal * 0.5;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
