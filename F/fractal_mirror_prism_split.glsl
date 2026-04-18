#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_rms;

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

    float seg = 6.0 + 4.0 * aMid;
    vec2 uv = reflectUV(tc, seg, ctr, aspect);
    uv = 1.0 - abs(1.0 - 2.0 * fract(uv));

    float chromaStr = 0.006 + 0.012 * aPk + 0.006 * aHigh;
    vec2 dir = normalize(uv - 0.5 + 1e-5);
    vec2 offR = dir * chromaStr;
    vec2 offB = -dir * chromaStr;
    vec2 offG = dir * chromaStr * 0.5;
    offG = vec2(-offG.y, offG.x);

    vec3 rC = texture(samp, fract(uv + offR)).rgb;
    vec3 gC = texture(samp, fract(uv + offG)).rgb;
    vec3 bC = texture(samp, fract(uv + offB)).rgb;
    vec3 col = vec3(rC.r, gC.g, bC.b);

    col *= 1.0 + aPk * 0.6;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
