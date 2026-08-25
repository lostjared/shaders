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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

// ant_light_color_deep_fractal_glow
// Deep zoom fractal with glowing iteration bands and spectrum-driven zoom depth
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Deep fractal zoom driven by spectrum
    float zoom = 2.0 + bass * 1.5;
    vec2 z = p * zoom;

    vec3 glow = vec3(0.0);
    float totalGlow = 0.0;

    for (int i = 0; i < 10; i++) {
        // Iterated fold + rotate
        z = abs(z) - (0.5 - mid * 0.1);
        z = rot(iTime * 0.08 + float(i) * 0.3) * z;
        z *= 1.2 + treble * 0.2;

        float d = length(z);
        float ringGlow = 0.01 / abs(sin(d * (5.0 + float(i)) - iTime) / 5.0);
        ringGlow = min(ringGlow, 2.0);

        vec3 bandColor = rainbow(float(i) * 0.1 + d * 0.2 + iTime * 0.05);
        glow += bandColor * ringGlow * (1.0 / (1.0 + float(i) * 0.3));
        totalGlow += ringGlow;
    }

    // Texture through fractal warp
    vec2 sampUV = fract(z * 0.03 + tc);
    float chroma = (treble + air) * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Blend fractal glow
    col = mix(col, col + glow * 0.15, 0.5 + mid * 0.3);

    // Total energy brightness
    col *= 1.0 + totalGlow * 0.01 * bass;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
