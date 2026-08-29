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
    return 1.0 - abs(1.0 - 2.0 * uv);
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = tc;
    vec2 p = (uv - ctr) * vec2(aspect, 1.0);
    float rad = length(p);
    float ang = atan(p.y, p.x);

    float hexSeg = 6.0;
    float segAngle = 6.28318 / hexSeg;
    ang = mod(ang + segAngle * 0.5, segAngle) - segAngle * 0.5;
    ang = abs(ang);

    vec2 hexUV = vec2(cos(ang), sin(ang)) * rad;
    hexUV.x /= aspect;
    hexUV += ctr;

    float zoom = 1.3 + 0.3 * aLow;
    for (int i = 0; i < 4; i++) {
        hexUV = abs((hexUV - ctr) * zoom) + ctr - 0.5;
        hexUV = rotateUV(hexUV, t * 0.1 + float(i) * 0.15, ctr, aspect);
    }
    hexUV = mirror(fract(hexUV));

    vec4 tex = texture(samp, hexUV);
    float ring = abs(sin(rad * 20.0 - t * 2.0 * (1.0 + aLow)));
    ring = smoothstep(0.8, 1.0, ring) * 0.2 * aHigh;
    tex.rgb += ring;

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
