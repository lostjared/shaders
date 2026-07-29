#version 330 core
// ant_gem_deep_bloom
// Deep escape-time fractal zoom with neon bloom rings and mid-driven glow halos

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 neonRing(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Deep zoom with bass pulsation
    float zoom = pow(0.5, mod(iTime * 0.4, 9.0)) * (1.0 + bass * 0.4);
    vec2 p = uv * zoom;
    vec2 p0 = p;

    // Escape-time fractal
    float iters = 0.0;
    const float maxIters = 50.0;
    vec2 c = vec2(0.8 + mid * 0.2, 0.5 + 0.1 * sin(iTime * 0.25));
    for (float i = 0.0; i < maxIters; i++) {
        p = abs(p) / dot(p, p) - c;
        if (length(p) > 20.0) break;
        iters++;
    }
    float norm = iters / maxIters;

    // Distorted texture lookup through fractal field
    vec2 sampUV = tc + p * 0.02;
    sampUV = abs(fract(sampUV * 0.5 + 0.5) * 2.0 - 1.0);

    // Sample with mid-driven chromatic bloom
    float chroma = (mid + treble) * 0.035;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Neon bloom rings based on iteration depth
    vec3 bloomAccum = vec3(0.0);
    for (float i = 0.0; i < 5.0; i++) {
        float ringDist = abs(norm - (i + 1.0) * 0.15);
        float ring = pow(0.01 / max(ringDist, 0.001), 0.8);
        float freq = texture(spectrum, (i + 1.0) * 0.08).r;
        bloomAccum += neonRing(i * 0.2 + iTime * 0.15 + freq) * ring * 0.12;
    }
    col += bloomAccum;

    // Mid-driven glow halo around deep regions
    float depthGlow = smoothstep(0.3, 0.8, norm) * mid * 1.5;
    vec3 haloCol = neonRing(norm + iTime * 0.2 + bass);
    col += haloCol * depthGlow * 0.25;

    // Fractal color from iteration
    vec3 fracCol;
    fracCol.r = norm * 1.5;
    fracCol.g = sin(iters * 0.4 + iTime);
    fracCol.b = length(p) * 0.08;
    col = mix(col, col * (fracCol + 0.5), 0.25 + hiMid * 0.2);

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
