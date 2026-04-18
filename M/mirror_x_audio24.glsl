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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float logR = log(r + 0.001);
    float spiralTwist = 0.5 + 1.5 * aLow;
    a += spiralTwist * sin(logR * 8.0 + t * 2.0);
    float newR = r * (1.0 + 0.2 * sin(a * 3.0 + t * 1.5) * aMid);
    vec2 warped = vec2(cos(a), sin(a)) * newR;
    warped.x /= aspect;
    warped += 0.5;
    vec4 tex = texture(samp, fract(warped));
    float edge = smoothstep(0.0, 0.02, abs(sin(a * 4.0 + t))) * aHigh;
    tex.rgb += edge * 0.2;
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
