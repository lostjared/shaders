#version 330 core
// Remix: gem_glass (crystalline refraction) + gem-ripple (vortex swirl)
// Spectrum drives: refraction strength (bass), swirl intensity (mid), chromatic split (treble)

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    vec2 uv = tc;

    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.18).r;
    float treble = texture(spectrum, 0.55).r;

    // Glass normal from texture gradient
    float delta = 0.008;
    float h = dot(texture(samp, uv).rgb, vec3(0.33));
    float h1 = dot(texture(samp, uv + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, uv + vec2(0.0, delta)).rgb, vec3(0.33));
    vec2 normal = vec2(h1 - h, h2 - h);

    // Vortex swirl centered on screen, intensity driven by mid frequencies
    vec2 centered = uv - 0.5;
    float r = length(centered);
    float angle = atan(centered.y, centered.x);
    float swirl = (2.0 + mid * 6.0) * exp(-r * 2.5);
    angle += swirl;

    // Reconstruct UV with glass normal displacement scaled by bass
    float glassStrength = 0.03 + bass * 0.08;
    vec2 warpedUV = vec2(cos(angle), sin(angle)) * r + 0.5;
    warpedUV += normal * glassStrength;

    // Chromatic aberration driven by treble
    float shift = (0.005 + treble * 0.04) * (1.0 + r);
    vec3 result;
    result.r = texture(samp, mirror(warpedUV + normal * shift)).r;
    result.g = texture(samp, mirror(warpedUV)).g;
    result.b = texture(samp, mirror(warpedUV - normal * shift)).b;

    // Specular highlight on steep glass slopes
    float specular = pow(max(0.0, 1.0 - length(normal * 20.0)), 10.0);
    result += vec3(1.0, 0.95, 0.9) * specular * (0.3 + bass * 0.4);

    // Bass-driven brightness bloom
    result *= 1.0 + bass * 0.8;

    // Vignette
    result *= smoothstep(1.3, 0.3, r);

    color = vec4(result, 1.0);
}
