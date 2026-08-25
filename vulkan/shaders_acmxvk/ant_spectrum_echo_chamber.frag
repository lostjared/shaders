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

// ant_spectrum_echo_chamber
// Infinite mirrored echo chamber with spectrum-driven depth and gradient colors
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.35).r;
    float treble = texture(spectrum, 0.55).r;
    float air    = texture(spectrum, 0.78).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Four-way mirror
    centered = abs(centered);
    uv = centered + 0.5;

    // Zoom echo: multiple scaled mirror samples
    vec3 result = vec3(0.0);
    float totalWeight = 0.0;

    for (float i = 0.0; i < 8.0; i++) {
        float scale = 1.0 + i * (0.15 + bass * 0.1);
        float rotation = i * 0.1 * (1.0 + mid);
        vec2 echoUV = (uv - 0.5);
        float c = cos(rotation), s = sin(rotation);
        echoUV = mat2(c, -s, s, c) * echoUV;
        echoUV = echoUV * scale + 0.5;
        echoUV = mirror(echoUV);

        float freq = texture(spectrum, i * 0.08 + 0.02).r;
        vec3 samp_col = texture(samp, echoUV).rgb;

        // Color shift per echo layer
        float hueOff = i * 0.12 + iTime * 0.2;
        samp_col *= rainbow(hueOff + freq);

        float w = 1.0 / (1.0 + i * 0.5);
        result += samp_col * w;
        totalWeight += w;
    }
    result /= totalWeight;

    // Gradient overlay
    float dist = length(centered);
    vec3 grad = rainbow(dist * 4.0 + iTime * 0.4);
    result = mix(result, result * grad, 0.3 + treble * 0.2);

    // Ripple distortion
    float ripple = sin(dist * 30.0 - iTime * 4.0) * hiMid * 0.02;
    vec3 rippled = texture(samp, mirror(uv + ripple)).rgb;
    result = mix(result, rippled, 0.2);

    // Air shimmer
    result += air * 0.08 * rainbow(iTime + dist * 2.0);

    // Peak
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
