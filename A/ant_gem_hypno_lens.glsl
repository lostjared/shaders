#version 330 core
// ant_gem_hypno_lens
// Spherical fisheye lens with hypnotic concentric rings and spectrum-reactive color bands

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 hypno(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t * 1.5 + vec3(0.0, 0.25, 0.5)));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * 2.0;
    p.x *= aspect;

    float d = length(p);

    // Spherical fisheye bulge (from gem-aura)
    float sphereRadius = 1.0 + bass * 0.3;
    float z = sqrt(max(0.0, sphereRadius * sphereRadius - d * d));
    float fisheye = atan(d, z) / (PI * 0.5);
    vec2 sphereUV = (d > 0.0) ? (p / d) * fisheye : vec2(0.0);
    sphereUV.x /= aspect;
    sphereUV = sphereUV * 0.5 + 0.5;

    // Hypnotic concentric ring distortion
    float ringFreq = 15.0 + hiMid * 12.0;
    float rings = sin(d * ringFreq - iTime * 3.0 - bass * 8.0);
    sphereUV += (p / (d + 0.01)) * rings * 0.015 * (1.0 + mid);

    // Clamp to valid range with mirror
    sphereUV = abs(fract(sphereUV * 0.5 + 0.5) * 2.0 - 1.0);

    // Treble chromatic bands
    float chroma = treble * 0.05;
    float bandAngle = atan(p.y, p.x);
    vec2 chromaDir = vec2(cos(bandAngle), sin(bandAngle)) * chroma;
    vec3 col;
    col.r = texture(samp, sphereUV + chromaDir).r;
    col.g = texture(samp, sphereUV).g;
    col.b = texture(samp, sphereUV - chromaDir).b;

    // Spectrum color bands: concentric rings tinted by frequency
    vec3 bandColor = hypno(d * 2.0 - iTime * 0.3 + bass);
    float bandMask = rings * 0.5 + 0.5;
    col = mix(col, col * bandColor, bandMask * (0.3 + mid * 0.25));

    // Lighting on sphere surface
    vec3 normal = normalize(vec3(p, z));
    float lightAngle = iTime * 0.5 + mid * 3.0;
    vec3 lightDir = normalize(vec3(sin(lightAngle), cos(lightAngle), 1.0));
    float diff = max(dot(normal, lightDir), 0.0);
    float spec = pow(max(dot(reflect(-lightDir, normal), vec3(0, 0, 1)), 0.0), 16.0);
    col *= 0.6 + diff * 0.4;
    col += spec * 0.3 * (1.0 + amp_peak * 2.0);

    // Hot center glow
    float coreGlow = exp(-d * 4.0) * (1.0 + bass * 1.2);
    col += vec3(1.0, 0.95, 0.85) * coreGlow * 0.2;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
