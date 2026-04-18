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
    vec2 p = (uv - ctr) * ar;
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    float spiralTwist = 0.4 + 1.5 * aPk;
    ang += spiralTwist * sin(rD * 12.0 + t * 0.8);

    float base_ = 1.8 + 0.2 * pingPong(t * 0.2, 5.0);
    float period = log(base_) * pingPong(t * PI, 5.0);
    float k = fract((log(rD) - t * 0.5) / max(period, 0.01));
    float rw = exp(k * max(period, 0.01));
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw * (1.0 + aLow * 0.4);
    vec2 logUV = fract(pwrap / ar + ctr);

    float glitch = floor(logUV.y * (12.0 + 15.0 * aHigh));
    float offset = sin(glitch * 37.5 + t * 6.0) * 0.03 * aMid;
    logUV.x += offset;
    logUV = 1.0 - abs(1.0 - 2.0 * fract(logUV));

    vec4 tex = texture(samp, logUV);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1 + aLow * 0.2, 0.95, 1.0 + aHigh * 0.3), aPk);
    color = tex;
}
