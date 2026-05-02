#version 330 core

in vec2 tc;
out vec4 color;

// ACMX2 Standard Uniforms
uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

// The Frequency Data (1D texture bound to unit 9)
uniform sampler1D spectrum;

const float PI = 3.141592653589;

void main() {
    vec2 uv = tc;

    // 1. Sample Frequency Data
    // Bass (bins 0-0.1), Mids (0.1-0.4), Treble (0.4-1.0)
    float bass = texture(spectrum, 0.05).r;
    float mid = texture(spectrum, 0.25).r;
    float treble = texture(spectrum, 0.70).r;

    // 2. The Bent Mirror Axis
    // We create a central mirror at x = 0.5, but use Bass to "wobble" it.

    // Convert to centered coordinates (-0.5 to 0.5)
    vec2 centered_uv = uv - 0.5;

    // Use Bass to shift the central axis over Y time.
    float mirror_bend = bass * sin(centered_uv.y * PI + iTime * 2.0);
    centered_uv.x += mirror_bend;

    // 3. Apply the Mirroring (The folding)
    // By using 'abs', the negative side flips over the positive side.
    centered_uv.x = abs(centered_uv.x);

    // Convert back to 0.0 - 1.0 range
    uv = centered_uv + 0.5;

    // 4. Frequency-Driven Ripples
    // Before we sample the image, we use Mids to ripple the surface.
    // This makes the mirrored image look like it's reflected in moving water.
    float ripple_force = mid * 0.1;
    uv.y += ripple_force * sin(uv.x * 20.0 + iTime * 5.0);
    uv.x += ripple_force * cos(uv.y * 20.0 + iTime * 5.0);

    // 5. Sample the Texture and apply Treble effects
    // High Treble causes sharp color separation at the reflection point.
    float shift = smoothstep(0.2, 0.8, treble) * 0.08;

    vec3 result;
    result.r = texture(samp, uv + vec2(shift, 0.0)).r;
    result.g = texture(samp, uv).g;
    result.b = texture(samp, uv - vec2(shift, 0.0)).b;

    // Add a frequency glow based on the spectrum average
    vec3 glow = vec3(bass, mid, treble) * 0.2;
    result += glow;

    // Transient Peak "Hallucination" (Inverts the colors on peaks)
    if (amp_peak > 0.95) {
        result = vec3(1.0) - result;
    }

    color = vec4(result, 1.0);
}