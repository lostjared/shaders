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

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

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

    float stripe = sin(tc.y * 30.0 + t * 3.0);
    stripe = step(0.0, stripe);
    vec2 uv1 = tc;
    vec2 uv2 = vec2(1.0 - tc.x, tc.y);

    float seg = 6.0 + 4.0 * aLow;
    uv1 = reflectUV(uv1, seg, ctr, aspect);
    uv2 = reflectUV(uv2, seg + 2.0, ctr, aspect);

    uv1 = rotateUV(uv1, t * 0.15 + aMid * 0.3, ctr, aspect);
    uv2 = rotateUV(uv2, -t * 0.12 + aHigh * 0.3, ctr, aspect);

    vec4 c1 = texture(samp, fract(uv1));
    vec4 c2 = texture(samp, fract(uv2));
    vec4 tex = mix(c1, c2, stripe);

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1, 1.0, 1.2), clamp(amp_rms, 0.0, 1.0) * 0.5);
    color = tex;
}
