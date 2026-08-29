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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;

    vec2 uv = tc;
    uv.x += sin(uv.y * 15.0 + t * 3.0) * 0.03 * aMid;
    uv.y += cos(uv.x * 12.0 + t * 2.5) * 0.03 * aHigh;
    uv = mirror(uv);

    float chromaStr = 0.005 + 0.01 * aPk + 0.005 * aHigh;
    vec2 dir = normalize(uv - 0.5 + 1e-5);
    vec2 off = dir * chromaStr;

    vec3 rC = texture(samp, fract(uv + off)).rgb;
    vec3 gC = texture(samp, fract(uv)).rgb;
    vec3 bC = texture(samp, fract(uv - off)).rgb;
    vec3 col = vec3(rC.r, gC.g, bC.b);

    col *= 1.0 + aPk * 0.6;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
