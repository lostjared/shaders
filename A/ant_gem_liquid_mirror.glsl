#version 330 core
// ant_gem_liquid_mirror
// Rainbow spectrum mirror with glass warp normals and plasma noise flow

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

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
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Bass-wobbled mirror axis (from rainbow_spectrum)
    float mirrorBend = bass * sin(centered.y * PI + iTime * 2.0);
    centered.x += mirrorBend;
    centered.x = abs(centered.x);
    uv = centered + 0.5;

    // Plasma noise flow distortion
    float noiseScale = 5.0 + mid * 4.0;
    float nx = noise(uv * noiseScale + iTime * 0.4);
    float ny = noise(uv * noiseScale - iTime * 0.4 + 100.0);
    vec2 plasmaOff = vec2(nx, ny) * 0.06 * (1.0 + bass * 0.5);
    uv += plasmaOff;

    // Glass warp normals from texture luminance
    float delta = 0.008;
    float h  = dot(texture(samp, uv).rgb, vec3(0.33));
    float h1 = dot(texture(samp, uv + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, uv + vec2(0.0, delta)).rgb, vec3(0.33));
    vec2 normal = vec2(h1 - h, h2 - h);

    // Apply glass refraction
    uv += normal * (0.05 + mid * 0.06);

    // Frequency-driven ripples
    float rippleForce = mid * 0.08;
    uv.y += rippleForce * sin(uv.x * 18.0 + iTime * 4.0);
    uv.x += rippleForce * cos(uv.y * 18.0 + iTime * 4.0);

    // Chromatic split
    float shift = smoothstep(0.2, 0.8, treble) * 0.06;
    vec3 col;
    col.r = texture(samp, uv + vec2(shift, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(shift, 0.0)).b;

    // Rainbow spectrum wash
    float dist = length(tc - 0.5);
    vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (dist - iTime * 0.3 + vec3(0.0, 0.33, 0.67)));
    col = mix(col, col * rainbow, 0.3 + air * 0.25);

    // Glass specular
    float spec = pow(max(0.0, 1.0 - length(normal * 16.0)), 8.0);
    col += vec3(1.0) * spec * 0.3;

    // Frequency glow
    col += vec3(bass, mid, treble) * 0.15;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
