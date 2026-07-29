#version 330 core
// Remix: gem-deep (escape-time fractal) + gem_spectrum_extreme (spiral melt)
// Spectrum drives: fractal constant (bass), zoom rate (mid), color inversion threshold (treble)

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid    = texture(spectrum, 0.25).r;
    float treble = texture(spectrum, 0.55).r;
    float air    = texture(spectrum, 0.75).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Zoom rate modulated by mid frequencies
    float zoomSpeed = 0.3 + mid * 0.6;
    float zoom = pow(0.5, mod(iTime * zoomSpeed, 10.0));
    vec2 p = uv * zoom;

    // Escape-time fractal with bass-driven constant
    float iters = 0.0;
    const float maxIters = 48.0;
    vec2 c = vec2(0.8 + bass * 0.3, 0.5 + lowMid * 0.2 + 0.1 * sin(iTime * 0.3));

    for (float i = 0.0; i < maxIters; i++) {
        p = abs(p) / dot(p, p) - c;
        if (length(p) > 20.0) break;
        iters++;
    }

    float normIters = iters / maxIters;

    // Ghost-sample the texture through the fractal coordinates
    vec2 ghostUV = tc + p * 0.015;
    // Spiral twist from extreme shader — bass drives the twist strength
    vec2 ghostCentered = ghostUV - 0.5;
    float gDist = length(ghostCentered);
    float gAngle = atan(ghostCentered.y, ghostCentered.x);
    gAngle += bass * 3.0 * exp(-gDist);
    ghostUV = vec2(cos(gAngle), sin(gAngle)) * gDist + 0.5;

    vec4 tex = texture(samp, ghostUV);

    // Multiple ghost offsets from spectrum (frequency smear from extreme shader)
    vec3 smeared = tex.rgb;
    for (float j = 1.0; j < 4.0; j++) {
        float freqSamp = texture(spectrum, j * 0.08).r;
        vec2 offset = vec2(freqSamp * 0.03 * j, 0.0);
        smeared = mix(smeared, texture(samp, ghostUV + offset).rgb, 0.4);
    }

    // Fractal coloring
    vec3 fracColor;
    fracColor.r = normIters * 2.0;
    fracColor.g = sin(iters * 0.5 + iTime) * 0.5 + 0.5;
    fracColor.b = length(p) * 0.08;

    // Swap channels based on treble
    fracColor = mix(fracColor, fracColor.brg, smoothstep(0.3, 0.7, treble));

    // Fluid inversion driven by treble + amp_smooth
    float invTrigger = smoothstep(0.3, 0.8, amp_smooth + mid);
    vec3 negative = vec3(1.0) - fracColor;
    fracColor = mix(fracColor, negative, invTrigger);

    // Composite: texture + fractal
    vec3 result = mix(smeared, fracColor, 0.6 + air * 0.15);

    // Harmonic glow from spectrum bands
    result += vec3(bass, mid, treble) * 0.2;

    // Peak blackout fade (from extreme shader)
    result *= 1.0 - smoothstep(0.92, 1.0, amp_peak);

    color = vec4(result, 1.0);
}
