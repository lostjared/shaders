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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
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

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        float s = sin(t * 0.12 + float(i) * 0.07), cc = cos(t * 0.12 + float(i) * 0.07);
        vec2 q = p - c;
        q.x *= aspect;
        q = mat2(cc, -s, s, cc) * q;
        q.x /= aspect;
        p = q + c;
    }
    return p;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float seg = 6.0 + 2.0 * aMid;
    uv = reflectUV(uv, seg, ctr, aspect);
    float zoom = 1.3 + 0.4 * aLow;
    uv = fractalFold(uv, zoom, t, ctr, aspect, 5);
    uv = 1.0 - abs(1.0 - 2.0 * fract(uv));

    vec4 tex = texture(samp, uv);

    float dist = length((tc - 0.5) * vec2(aspect, 1.0));
    float wave = sin(dist * 15.0 - t * 2.0) * 0.5 + 0.5;
    float hue = fract(t * 0.03 + dist * 0.5 + wave * 0.3);
    vec3 nebula = hsv2rgb(vec3(hue, 0.6, 0.8));
    tex.rgb = mix(tex.rgb, tex.rgb * nebula * 1.8, 0.25 + 0.15 * aHigh);

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
