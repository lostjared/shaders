#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    vec2 ts = 1.0 / iResolution;

    // Edge detection kernel - bass thickens edges
    float edgeScale = 1.0 + amp_low * 3.0;
    vec2 off = ts * edgeScale;

    vec3 tl = texture(samp, tc + vec2(-off.x, -off.y)).rgb;
    vec3 t = texture(samp, tc + vec2(0.0, -off.y)).rgb;
    vec3 tr = texture(samp, tc + vec2(off.x, -off.y)).rgb;
    vec3 l = texture(samp, tc + vec2(-off.x, 0.0)).rgb;
    vec3 r = texture(samp, tc + vec2(off.x, 0.0)).rgb;
    vec3 bl = texture(samp, tc + vec2(-off.x, off.y)).rgb;
    vec3 b = texture(samp, tc + vec2(0.0, off.y)).rgb;
    vec3 br = texture(samp, tc + vec2(off.x, off.y)).rgb;

    vec3 gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    vec3 gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    float edge = length(gx) + length(gy);

    // Mids control neon brightness
    float neonBright = 1.5 + amp_mid * 3.0;
    edge *= neonBright;

    // Hue cycles with time and smooth amp
    float hue = fract(time_f * 0.1 + amp_smooth * 0.5);
    vec3 neonColor = hsv2rgb(vec3(hue, 0.9, 1.0));

    vec3 original = texture(samp, tc).rgb;

    // RMS controls blend between original and neon edges
    float blend = 0.3 + amp_rms * 0.5;
    vec3 col = mix(original * 0.3, neonColor * edge, blend);

    // Peak glow
    col += smoothstep(0.6, 1.0, amp_peak) * neonColor * 0.3;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
