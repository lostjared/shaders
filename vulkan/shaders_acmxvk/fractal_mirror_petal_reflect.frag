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










const float TAU = 6.28318530718;

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float step_ = TAU / segments;
    ang = mod(ang, step_);
    ang = abs(ang - step_ * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 p = (tc - ctr) * vec2(aspect, 1.0);
    float rD = length(p);
    float ang = atan(p.y, p.x);

    float petals = 5.0 + 3.0 * aMid;
    float petalWave = 0.15 + 0.1 * aLow;
    float petalR = rD + petalWave * sin(ang * petals + t * 2.0);

    float seg = petals * 2.0;
    float step_ = TAU / seg;
    ang = mod(ang + t * 0.15, step_);
    ang = abs(ang - step_ * 0.5);

    vec2 petalUV = vec2(cos(ang), sin(ang)) * petalR;
    petalUV.x /= aspect;
    petalUV += ctr;
    petalUV = 1.0 - abs(1.0 - 2.0 * fract(petalUV));

    vec4 tex = texture(samp, petalUV);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
