#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

// Spectral helper for the rainbow smear
vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.2)
        c = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), w * 5.0);
    else if (w < 0.4)
        c = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), (w - 0.2) * 5.0);
    else if (w < 0.6)
        c = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (w - 0.4) * 5.0);
    else if (w < 0.8)
        c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (w - 0.6) * 5.0);
    else
        c = vec3(1.0, 0.0, 0.0);
    return pow(c, vec3(0.8));
}

void main(void) {
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = uv - center;
    float dist = length(dir);
    vec2 refractDir = normalize(dir);

    // --- PING-PONG CALCULATION ---
    // Change '1.5' to adjust the speed of the oscillation
    float pulse = sin(time_f * 1.5) * 0.5 + 0.5;

    // Remap pulse to dispersion range (0.02 is subtle, 0.25 is extreme)
    float dispersionBase = mix(0.02, 0.25, pulse);
    float dispersion = dispersionBase * dist;

    int samples = 28;
    vec3 accumulatedColor = vec3(0.0);

    // --- SPECTRAL DISPERSION ---
    for (int i = 0; i < samples; i++) {
        float w = float(i) / float(samples - 1);
        float shift = (w - 0.5) * dispersion;

        vec2 sampleUV = uv + (refractDir * shift);
        vec3 tex = texture(samp, clamp(sampleUV, 0.0, 1.0)).rgb;
        accumulatedColor += tex * spectrum(w);
    }

    // Normalization and saturation boost
    vec3 finalRGB = accumulatedColor / (float(samples) * 0.45);
    finalRGB = pow(finalRGB, vec3(0.9));

    // --- DYNAMIC REFLECTION ---
    // Light source that shifts slightly with the pulse
    vec2 lightPos = vec2(0.2 + (pulse * 0.1), 0.8);
    float lightDist = length(uv - lightPos);

    // Reflection also "breathes" with the pulse
    float reflection = pow(max(1.0 - lightDist, 0.0), 15.0) * (0.4 + pulse * 0.4);
    float streak = pow(max(1.0 - abs(uv.x + uv.y - 1.0), 0.0), 50.0) * (0.2 + pulse * 0.3);

    finalRGB += (reflection + streak);

    // Subtle edge vignette
    finalRGB *= 1.1 - (dist * 0.2);

    color = vec4(finalRGB, 1.0);
}