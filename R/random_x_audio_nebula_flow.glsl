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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main(void) {
    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Smooth/RMS drives nebula flow speed
    float flowSpeed = 0.3 + amp_smooth * 1.5;
    float t = time_f * flowSpeed;

    // FBM noise field for nebula distortion
    float n1 = fbm(p * (3.0 + amp_rms * 4.0) + vec2(t * 0.5, t * 0.3));
    float n2 = fbm(p * (4.0 + amp_mid * 3.0) + vec2(-t * 0.4, t * 0.6) + n1 * 2.0);

    // Warp texture with nebula noise
    vec2 warp = vec2(n1 - 0.5, n2 - 0.5) * (0.05 + amp_smooth * 0.08);
    // Bass adds large-scale push
    warp += p * amp_low * 0.03;
    uv += warp;
    uv = clamp(uv, 0.0, 1.0);

    vec3 tex = texture(samp, uv).rgb;

    // Nebula color overlay
    float nebulaMask = n2 * n1;
    vec3 nebulaColor = vec3(
        0.3 + 0.7 * sin(time_f * 0.2 + nebulaMask * 3.0),
        0.2 + 0.4 * sin(time_f * 0.3 + nebulaMask * 5.0 + 2.0),
        0.5 + 0.5 * cos(time_f * 0.15 + nebulaMask * 4.0));

    // RMS controls overlay intensity
    tex = mix(tex, nebulaColor, amp_rms * 0.35);

    // Treble adds stars (bright noise points)
    float star = noise(tc * iResolution * 0.5 + time_f * 0.5);
    star = smoothstep(0.95, 1.0, star) * amp_high * 1.5;
    tex += star;

    // Peak flash
    tex += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex, 0.0, 1.0), 1.0);
}
