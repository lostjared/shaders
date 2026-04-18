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

const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
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
    vec2 ar = vec2(aspect, 1.0);
    vec2 ctr = vec2(0.5);

    vec2 uv = tc;
    uv.x = mix(uv.x, 1.0 - uv.x, step(0.5, uv.x));

    vec2 p = (uv - ctr) * ar;
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    float spiralTwist = 0.5 + 1.5 * aPk;
    ang += spiralTwist * sin(rD * 10.0 + t * 0.7);

    float base_ = 1.8 + 0.2 * pingPong(t * 0.2, 5.0);
    float period = log(base_) * pingPong(t * PI, 5.0);
    float k = fract((log(rD) - t * 0.6) / max(period, 0.01));
    float rw = exp(k * max(period, 0.01));

    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw * (1.0 + aLow * 0.5);
    vec2 logUV = fract(pwrap / ar + ctr);

    logUV = 1.0 - abs(1.0 - 2.0 * logUV);

    vec4 tex = texture(samp, logUV);
    float vign = 1.0 - smoothstep(0.6, 1.2, length((tc - ctr) * ar));
    tex.rgb *= 0.85 + 0.3 * vign;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0 - aLow * 0.1, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
