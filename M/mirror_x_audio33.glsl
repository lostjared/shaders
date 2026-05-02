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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc;
    if (uv.y < 0.5)
        uv.y = 1.0 - uv.y;
    float pp = pingPong(t * 0.5, 1.0);
    float split = mix(0.3, 0.7, pp);
    if (uv.x < split) {
        uv.x = split - (split - uv.x) * (1.0 + 0.3 * aLow);
        uv.x = abs(uv.x);
    }
    float dist = length(uv - vec2(split, 0.75));
    float ripple = sin(dist * 20.0 - t * 4.0) * 0.01 * aMid;
    uv += ripple;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    float highlight = smoothstep(0.3, 0.0, dist) * aHigh * 0.3;
    tex.rgb += highlight * vec3(0.8, 0.4, 1.0);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
