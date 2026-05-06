#version 330 core
// ant_light_color_solar_corona
// Sun corona with magnetic loop arcs, flare ejections, and spectrum plasma

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 solar(float t) {
    vec3 a = vec3(0.8, 0.4, 0.1);
    vec3 b = vec3(0.2, 0.3, 0.1);
    vec3 c = vec3(1.0, 0.5, 0.2);
    vec3 d = vec3(0.0, 0.1, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float angle = atan(p.y, p.x);

    // Sun disc
    float disc = smoothstep(0.22, 0.2, r);
    float limb = smoothstep(0.2, 0.15, r) - smoothstep(0.15, 0.1, r);

    // Corona rays
    float corona = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        float rayAngle = i * TAU / 8.0 + iTime * 0.1;
        float rayWidth = 0.15 + bass * 0.1;
        float da = abs(mod(angle - rayAngle + 3.14159, TAU) - 3.14159);
        float ray = smoothstep(rayWidth, 0.0, da) / (r * 2.0 + 0.1);
        corona += ray;
    }

    // Magnetic loop arcs
    float loops = 0.0;
    for (float i = 0.0; i < 4.0; i++) {
        float loopAngle = i * TAU / 4.0 + iTime * 0.05;
        vec2 loopCenter = vec2(cos(loopAngle), sin(loopAngle)) * 0.2;
        float loopR = length(p - loopCenter);
        float arcR = 0.15 + mid * 0.1;
        loops += smoothstep(0.01, 0.0, abs(loopR - arcR)) * 0.5;
    }

    // Texture through solar warp
    vec2 sampUV = tc + p * disc * 0.1;
    float chroma = treble * 0.03 + corona * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Corona glow
    col += solar(corona + iTime * 0.1) * corona * (0.5 + air * 1.0);

    // Loop plasma
    col += solar(loops * 3.0 + iTime * 0.2) * loops * (1.0 + mid * 2.0);

    // Disc surface: granulation noise
    float granulation = noise(p * 40.0 + iTime * 0.5);
    col = mix(col, col * solar(granulation + iTime * 0.1) * 1.5, disc);

    // Limb darkening with color
    col += solar(angle / TAU + iTime * 0.1) * limb * (0.5 + bass * 1.0);

    // CME flare on peak
    float flare = exp(-pow((angle - iTime * 0.3) * 2.0, 2.0)) * exp(-(r - 0.3) * 3.0);
    flare *= step(0.2, r);
    col += solar(0.1) * flare * (2.0 + amp_peak * 5.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
