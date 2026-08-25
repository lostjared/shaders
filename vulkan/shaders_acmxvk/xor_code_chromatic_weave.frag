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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 xorColor(vec3 a, vec3 b) {
    return vec3((bytes(a) ^ bytes(b)) & uvec3(255u)) / 255.0;
}

vec3 spectrum(float t) {
    return 0.55 + 0.45 * cos(6.2831853 * (t + vec3(0.0, 0.27, 0.63)));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float warp = sin(p.y * 18.0 + time_f * 2.0) * 0.035;
    float weft = cos(p.x * 21.0 - time_f * 1.6) * 0.035;
    vec2 uvA = tc + vec2(warp, weft);
    vec2 uvB = tc + vec2(weft, -warp);

    vec3 a = texture(samp, uvA).rgb;
    vec3 b = texture(samp, uvB).gbr;
    float overUnder = step(0.0, sin(p.x * 28.0) * sin(p.y * 28.0));
    vec3 woven = xorColor(a, b * (1.2 + overUnder * 1.3));

    float thread = pow(abs(sin(p.x * 28.0 + p.y * 28.0 - time_f * 3.0)), 10.0);
    vec3 tintA = spectrum(p.x * 0.3 + time_f * 0.03);
    vec3 tintB = spectrum(p.y * 0.3 - time_f * 0.025 + 0.4);
    vec3 tint = mix(tintA, tintB, overUnder);
    vec3 result = mix(mix(a, woven, 0.55), woven * tint * 1.3, 0.38);
    result += tint * thread * 0.38;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
