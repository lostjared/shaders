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

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 blue = vec3(0.10, 0.55, 1.0);
    vec3 green = vec3(0.10, 1.00, 0.45);
    float ph = fract(t * 0.08);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c_ = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c_ * k3) * 1.05;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;

    vec2 uv = tc;
    float stripe = sin(uv.y * 40.0 + t * 3.0);
    stripe = step(0.0, stripe);
    vec2 uv1 = 1.0 - abs(1.0 - 2.0 * uv);
    vec2 uv2 = vec2(1.0 - uv.x, uv.y);
    uv2 = 1.0 - abs(1.0 - 2.0 * uv2);

    uv1 += sin(t * 2.0 + uv1.yx * 10.0) * 0.02 * aLow;
    uv2 += cos(t * 1.5 + uv2.yx * 8.0) * 0.02 * aMid;

    vec4 c1 = texture(samp, fract(uv1));
    vec4 c2 = texture(samp, fract(uv2));
    vec4 tex = mix(c1, c2, stripe);

    float aspect = iResolution.x / iResolution.y;
    float dist = length((tc - 0.5) * vec2(aspect, 1.0));
    vec3 neon = neonPalette(t + dist * 1.5);
    tex.rgb = mix(tex.rgb, tex.rgb * neon * 1.8, 0.2 + 0.15 * aHigh);

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
