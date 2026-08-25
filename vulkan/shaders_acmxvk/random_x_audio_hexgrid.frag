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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










// Hexagonal grid helper
vec4 hexCoord(vec2 uv) {
    vec2 r = vec2(1.0, 1.732);
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    vec2 id = uv - gv;
    return vec4(gv, id);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc * vec2(aspect, 1.0);

    // Bass drives hexagon scale (bigger on beat)
    float hexScale = 8.0 + amp_low * 20.0;
    vec4 hex = hexCoord(uv * hexScale);
    vec2 hexCenter = hex.zw / hexScale / vec2(aspect, 1.0);

    // Sample from hex center
    vec3 tex = texture(samp, clamp(hexCenter, 0.0, 1.0)).rgb;

    // Mids rotate hex pattern
    float rot = time_f * (0.1 + amp_mid * 0.5);
    vec2 ruv = uv - 0.5 * vec2(aspect, 1.0);
    float c = cos(rot), s = sin(rot);
    ruv = vec2(c * ruv.x - s * ruv.y, s * ruv.x + c * ruv.y);
    ruv += 0.5 * vec2(aspect, 1.0);
    vec4 hex2 = hexCoord(ruv * hexScale);
    vec2 hexCenter2 = hex2.zw / hexScale / vec2(aspect, 1.0);
    vec3 tex2 = texture(samp, clamp(hexCenter2, 0.0, 1.0)).rgb;

    // Blend rotated and non-rotated
    tex = mix(tex, tex2, amp_mid * 0.5);

    // Hex edge highlight from treble
    float hexDist = length(hex.xy);
    float hexEdge = smoothstep(0.45, 0.5, hexDist);
    tex += hexEdge * amp_high * 0.4 * vec3(0.5, 0.8, 1.0);

    // RMS brightness
    tex *= 1.0 + amp_rms * 0.3;

    // Peak flash
    tex += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex, 0.0, 1.0), 1.0);
}
