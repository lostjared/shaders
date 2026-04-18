#version 330 core
// Remix: gem_polar (tunnel) + gem_metal (concentric rings) + gem_plas (plasma noise)
// Spectrum drives: tunnel depth speed (bass), ring density (mid), plasma distortion (treble)

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

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

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.3, 0.2, 0.2);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Sample full spectrum sweep for ring modulation
    float bass   = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.65).r;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Plasma noise distortion scaled by treble
    float nx = noise(uv * 4.0 + iTime * 0.4);
    float ny = noise(uv * 4.0 - iTime * 0.3);
    vec2 plasmaOffset = vec2(nx, ny) * (0.02 + treble * 0.06);

    // Tunnel mapping: log-polar with bass-driven depth speed
    float tunnelSpeed = 0.3 + bass * 1.5;
    vec2 tunnelUV;
    tunnelUV.x = (angle / 3.14159) + iTime * 0.05;
    tunnelUV.y = (1.0 / (r + 0.01)) + iTime * tunnelSpeed;

    // Mirror-wrap for seamless tiling
    vec2 texUV = abs(fract(tunnelUV * 0.5 + plasmaOffset) * 2.0 - 1.0);
    vec4 tex = texture(samp, texUV);

    // Metallic ring pattern: density driven by mid frequencies
    float ringDensity = 15.0 + mid * 30.0;
    float ripple = sin(angle * (6.0 + hiMid * 12.0) + iTime) * 0.04;
    float ringPattern = sin((r + ripple) * ringDensity - iTime * 3.0);

    // Color from ring position
    vec3 ringColor = palette(r * 2.0 - iTime * 0.4 + lowMid);

    // Hot center glow scaled by bass
    float centerGlow = exp(-r * (3.0 - bass * 1.5)) * (0.8 + bass * 0.6);

    // Compose
    vec3 result = mix(tex.rgb, ringColor, 0.35 + mid * 0.2);
    result *= 0.85 + 0.15 * ringPattern;
    result += centerGlow * vec3(1.0, 0.9, 0.7);

    // Tunnel vignette
    float vignette = smoothstep(0.0, 0.15, r) * smoothstep(2.0, 0.6, r);
    result *= vignette;

    // Peak flash
    result *= 1.0 + amp_peak * 0.3;

    color = vec4(result, 1.0);
}
