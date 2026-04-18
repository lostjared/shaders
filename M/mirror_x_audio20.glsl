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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

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
    float wave = sin(r * 10.0 - t * 5.0) * 0.5 + 0.5;
    float radMod = r + t * 0.5 * aLow;
    float hue = fract(a / 6.28318 + t * 0.1 + wave * 0.3);
    vec3 overlay = hsv2rgb(vec3(hue, 0.7, 0.8 + 0.2 * aMid));
    vec4 tex = texture(samp, fract(uv));
    tex.rgb = mix(tex.rgb, tex.rgb * overlay, 0.4 + 0.3 * aHigh);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
