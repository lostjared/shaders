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
    vec2 uv = tc;
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    uv.x = abs(uv.x - 0.5) + 0.5;
    uv.y = abs(uv.y - 0.5) + 0.5;
    float t = time_f;
    float ripple = sin(length(uv - 0.75) * 30.0 - t * 4.0) * 0.01 * aLow;
    uv += ripple;
    vec4 c1 = texture(samp, uv);
    vec4 c2 = texture(samp, 1.0 - uv);
    float blend = 0.5 + 0.3 * sin(t + length(tc - 0.5) * 10.0) * aMid;
    vec4 tex = mix(c1, c2, blend);
    tex.rgb *= 1.0 + amp_peak * 0.4;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1, 0.95, 1.2), aHigh * 0.5);
    color = tex;
}
