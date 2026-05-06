#version 330 core
// ant_gem_void_pulse
// Deep fractal zoom with inverse void pulse and spectrum-driven void colors

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Pulsating deep zoom
    float cycle = mod(iTime * 0.35, 10.0);
    float zoom = pow(0.5, cycle) * (1.0 + bass * 0.6);
    vec2 p = uv * zoom;

    // Escape-time with void attractor
    float iters = 0.0;
    const float maxIters = 55.0;
    vec2 voidPoint = vec2(
        0.7 + mid * 0.3 * sin(iTime * 0.2),
        0.4 + bass * 0.2 * cos(iTime * 0.3));
    for (float i = 0.0; i < maxIters; i++) {
        p = abs(p) / dot(p, p) - voidPoint;
        if (length(p) > 25.0)
            break;
        iters++;
    }
    float norm = iters / maxIters;

    // Texture lookup through void distortion
    vec2 sampUV = tc + p * 0.018;
    sampUV = abs(fract(sampUV * 0.5 + 0.5) * 2.0 - 1.0);

    // Sample with void-colored chromatic split
    float chroma = (mid + treble) * 0.04 + norm * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Void coloring from fractal depth
    vec3 voidCol;
    voidCol.r = sin(norm * 6.0 + iTime * 0.5 + bass) * 0.5 + 0.5;
    voidCol.g = sin(norm * 4.0 + iTime * 0.3 + 2.0) * 0.5 + 0.5;
    voidCol.b = sin(norm * 8.0 + iTime * 0.7 + 4.0) * 0.5 + 0.5;

    // Smooth inverse transition: deep regions invert
    float invertMix = smoothstep(0.3, 0.7, norm + mid * 0.3);
    vec3 inverted = vec3(1.0) - col;
    col = mix(col, inverted, invertMix * 0.6);

    // Void color tinting
    col = mix(col, col * voidCol, 0.35 + hiMid * 0.25);

    // Void edge glow
    float edgeGlow = pow(0.01 / max(abs(norm - 0.5), 0.001), 0.5);
    col += voidCol * edgeGlow * 0.06 * (1.0 + air);

    // Pulse: bass drives sudden brightness surges
    float pulse = bass * bass * sin(iTime * 8.0 + bass * 15.0) * 0.3;
    col *= 1.0 + max(pulse, 0.0);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
