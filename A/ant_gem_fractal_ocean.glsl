#version 330 core
// ant_gem_fractal_ocean
// Deep escape-time fractal with liquid ripple waves and ocean aurora palette

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 ocean(float t) {
    vec3 a = vec3(0.1, 0.3, 0.5);
    vec3 b = vec3(0.3, 0.4, 0.5);
    vec3 c = vec3(1.0, 1.2, 1.0);
    vec3 d = vec3(0.0, 0.25, 0.5);
    return a + b * cos(6.28318 * (c * t + d));
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
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Fractal zoom pulsing with bass
    float zoom = pow(0.5, mod(iTime * 0.3, 8.0)) * (1.0 + bass * 0.5);
    vec2 p = uv * zoom;

    // Escape-time fractal iteration
    float iters = 0.0;
    const float max_iters = 48.0;
    for (float i = 0.0; i < max_iters; i++) {
        p = abs(p) / dot(p, p) - vec2(0.8 + mid * 0.3, 0.5 + 0.1 * sin(iTime * 0.3));
        if (length(p) > 20.0) break;
        iters++;
    }
    float normIters = iters / max_iters;

    // Liquid ripple distortion on texture coords
    vec2 texUV = tc + p * 0.015;
    float ripple = noise(tc * 6.0 + iTime * 0.5) * 0.04 * (1.0 + mid);
    texUV += vec2(sin(texUV.y * 15.0 + iTime * 3.0), cos(texUV.x * 15.0 + iTime * 3.0)) * ripple;

    // Mirror-wrap to keep in bounds
    texUV = abs(fract(texUV * 0.5 + 0.5) * 2.0 - 1.0);

    // Sample with chromatic split on treble
    float chroma = treble * 0.035;
    vec3 col;
    col.r = texture(samp, texUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, texUV).g;
    col.b = texture(samp, texUV - vec2(chroma, 0.0)).b;

    // Ocean aurora overlay keyed to fractal depth
    vec3 oceanCol = ocean(normIters * 2.0 + iTime * 0.15 + bass);
    col = mix(col, col * oceanCol, 0.4 + hiMid * 0.3);

    // Deep glow rings
    float ringGlow = pow(0.01 / max(abs(sin(normIters * 8.0 + iTime)), 0.001), 0.8);
    col += oceanCol * ringGlow * 0.15 * (1.0 + air);

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.4;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
