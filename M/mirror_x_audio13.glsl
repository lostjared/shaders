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

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float spiral = r * (6.0 + 4.0 * aLow) + t * 2.0;
    a += sin(spiral) * 0.3 * aMid;
    r *= 1.0 + 0.1 * sin(a * 3.0 + t);
    vec2 warped = vec2(cos(a), sin(a)) * r;
    warped.x /= aspect;
    warped += 0.5;
    float pp = pingPong(t * 0.3, 3.0) / 3.0;
    warped = mix(warped, fract(warped * 2.0), pp * aMid);
    vec4 tex = texture(samp, fract(warped));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
