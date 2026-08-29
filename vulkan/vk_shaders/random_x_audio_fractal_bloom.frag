#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Fractal iteration - smooth amp controls depth
    int iters = 3 + int(amp_smooth * 5.0);
    vec2 z = p;
    for (int i = 0; i < 8; i++) {
        if (i >= iters) break;
        float fi = float(i);
        z = abs(z * (1.5 + amp_low * 0.5 * sin(time_f + fi))) - 0.5;
        float ca = time_f * 0.1 + fi * 0.3 + amp_mid * 0.5;
        float cc = cos(ca), ss = sin(ca);
        z = vec2(cc * z.x - ss * z.y, ss * z.x + cc * z.y);
    }

    vec2 fracUV = z;
    fracUV.x /= aspect;
    fracUV += 0.5;
    fracUV = abs(mod(fracUV, 2.0) - 1.0);

    vec3 tex = texture(samp, clamp(fracUV, 0.0, 1.0)).rgb;

    // Bloom: smooth amp increases glow spread
    float bloomStr = amp_smooth * 0.5;
    vec2 ts = 1.0 / iResolution;
    vec3 bloom = vec3(0.0);
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 off = vec2(float(x), float(y)) * ts * (2.0 + bloomStr * 4.0);
            bloom += texture(samp, clamp(fracUV + off, 0.0, 1.0)).rgb;
        }
    }
    bloom /= 25.0;

    // RMS controls bloom blend
    vec3 col = mix(tex, bloom, amp_rms * 0.6);

    // Fractal hue overlay
    float fracLen = length(z);
    float hue = fract(fracLen * 0.5 + time_f * 0.05);
    vec3 fracColor = hsv2rgb(vec3(hue, 0.7, 0.8));
    col = mix(col, fracColor, amp_smooth * 0.3);

    // Peak flash
    col += smoothstep(0.6, 1.0, amp_peak) * 0.25;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
