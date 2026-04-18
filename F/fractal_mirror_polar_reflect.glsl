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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);

    float segments = 5.0 + 3.0 * aLow;
    float step_ = TAU / segments;
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);

    r += sin(a * 8.0 + t * 3.0) * 0.05 * aMid;
    r *= 1.0 + 0.2 * aLow * sin(t * 4.0);

    vec2 reflected = vec2(cos(a), sin(a)) * r;
    reflected.x /= aspect;
    reflected += 0.5;
    reflected = 1.0 - abs(1.0 - 2.0 * fract(reflected));

    vec4 tex = texture(samp, reflected);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.3), aPk);
    color = tex;
}
