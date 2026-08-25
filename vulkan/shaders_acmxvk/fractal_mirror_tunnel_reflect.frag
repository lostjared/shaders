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










const float PI = 3.1415926535897932384626433832795;

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = (uv - ctr) * vec2(aspect, 1.0);
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    float tunnelSpeed = t * 0.8 * (1.0 + aLow * 0.5);
    float tunnelR = 0.3 / rD;
    float tunnelAng = ang / PI;

    vec2 tunnelUV = vec2(tunnelR + tunnelSpeed, tunnelAng);
    tunnelUV.x += sin(tunnelAng * 4.0 + t * 2.0) * 0.1 * aMid;
    tunnelUV = 1.0 - abs(1.0 - 2.0 * fract(tunnelUV));

    vec4 tex = texture(samp, tunnelUV);
    float fade = smoothstep(0.0, 0.3, rD);
    tex.rgb *= fade;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
