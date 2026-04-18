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
    for (int i = 0; i < 4; i++) {
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

    // Aurora curtain effect - vertical waves
    float t = time_f * (0.3 + amp_smooth * 0.5);

    // Base aurora wave (horizontal curtain)
    float wave1 = sin(p.x * (3.0 + amp_low * 5.0) + t * 1.5) * 0.3;
    float wave2 = sin(p.x * (5.0 + amp_mid * 4.0) + t * 2.0 + 1.0) * 0.15;
    float wave3 = sin(p.x * (8.0 + amp_high * 6.0) + t * 3.0 + 2.5) * 0.08;
    float curtainY = wave1 + wave2 + wave3;

    // Aurora intensity based on y position relative to curtain
    float auroraHeight = 0.4 + amp_smooth * 0.3;
    float auroraFade = smoothstep(auroraHeight, 0.0, abs(p.y - curtainY));

    // FBM adds detail
    float detail = fbm(p * 3.0 + vec2(t * 0.5, 0.0));
    auroraFade *= 0.5 + detail * 0.5;

    // Aurora colors from frequency bands
    vec3 auroraColor = vec3(0.0);
    auroraColor += vec3(0.1, 1.0, 0.3) * amp_low * 1.5;     // Green from bass
    auroraColor += vec3(0.1, 0.5, 1.0) * amp_mid * 1.2;     // Blue from mids
    auroraColor += vec3(0.8, 0.2, 1.0) * amp_high * 1.5;    // Purple from treble
    auroraColor = max(auroraColor, vec3(0.05, 0.2, 0.1));    // Minimum glow

    // Blend with texture
    vec3 tex = texture(samp, tc).rgb;
    vec3 col = tex + auroraColor * auroraFade * (0.5 + amp_rms * 1.0);

    // Warp texture slightly under the aurora
    vec2 auroraWarp = vec2(auroraFade * 0.02 * sin(time_f * 2.0), auroraFade * 0.01);
    vec3 warpedTex = texture(samp, clamp(tc + auroraWarp, 0.0, 1.0)).rgb;
    col = mix(col, warpedTex + auroraColor * auroraFade * 0.5, auroraFade * 0.3);

    // Peak flash
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
