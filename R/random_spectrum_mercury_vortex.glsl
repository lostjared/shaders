#version 330 core
// Remix: gem-ripple (swirl/vortex) + gem_metal (metallic sheen) + gem_glass (refraction normals)
// Spectrum drives: swirl strength (bass), metallic specular (mid), refraction index (treble)
// Creates a liquid mercury vortex that bends video through itself

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
    float lowMid = texture(spectrum, 0.10).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // === Vortex swirl from gem-ripple: bass drives strength ===
    float swirlStrength = (1.0 + bass * 4.0) * exp(-r * 0.8);
    float swirlAngle = angle + swirlStrength * sin(r * 8.0 - iTime * 3.0);
    vec2 swirlUV = vec2(cos(swirlAngle), sin(swirlAngle)) * r;

    // === Refraction from gem_glass: treble drives index ===
    // Fake surface normal from noise derivatives
    float eps = 0.002;
    float h = noise(swirlUV * 6.0 + iTime * 0.5);
    float hx = noise((swirlUV + vec2(eps, 0.0)) * 6.0 + iTime * 0.5);
    float hy = noise((swirlUV + vec2(0.0, eps)) * 6.0 + iTime * 0.5);
    vec2 normal = vec2(hx - h, hy - h) / eps;

    float eta = 0.7 + treble * 0.6;  // 0.7 to 1.3 IOR range
    vec2 refracted = normalize(vec2(uv) + normal * eta);

    // Convert back to texture coordinates
    vec2 texUV = refracted * 0.5 + 0.5;

    // === Metallic specular from gem_metal ===
    float ringDensity = 10.0 + mid * 20.0;
    float jagged = sin(angle * (6.0 + lowMid * 10.0) + iTime) * 0.04;
    float metalRing = sin((r + jagged) * ringDensity - iTime * 2.0);
    float specular = pow(max(0.0, metalRing), 4.0 + hiMid * 4.0);

    // Fresnel reflection
    float fresnel = pow(1.0 - abs(dot(normalize(vec3(uv, 1.0)), vec3(0.0, 0.0, 1.0))), 3.0);

    // Chromatic aberration through refraction
    float abr = 0.015 + treble * 0.02;
    vec3 tex;
    tex.r = texture(samp, texUV + abr * normal).r;
    tex.g = texture(samp, texUV).g;
    tex.b = texture(samp, texUV - abr * normal).b;

    // Mercury/chrome color
    vec3 metalColor = vec3(0.8, 0.85, 0.9);
    metalColor += vec3(bass * 0.3, mid * 0.2, treble * 0.4);

    // === Compose ===
    vec3 refractedTex = tex * (1.0 - fresnel * 0.6);
    vec3 reflection = metalColor * specular * (0.3 + mid * 0.5);
    vec3 result = refractedTex + reflection;

    // Hot center glow (like a liquid metal pool center)
    float poolGlow = exp(-r * (2.0 - bass * 1.2)) * (0.5 + bass * 0.6);
    result += poolGlow * vec3(0.9 + mid * 0.1, 0.7 + treble * 0.3, 0.5);

    // Edge vortex darkening
    result *= smoothstep(2.0, 0.5, r);

    // Peak flash — bright specular burst
    result += amp_peak * specular * 0.5;

    color = vec4(result, 1.0);
}
