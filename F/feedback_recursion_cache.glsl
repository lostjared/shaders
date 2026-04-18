#version 330 core
// Feedback Recursion — Simulates infinite video feedback by warping
// each cache frame with a zoom + rotation that compounds over layers.
// Like pointing a camera at its own monitor — infinite regress.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform vec2 iResolution;
uniform float time_f;

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

void main(void) {
    vec4 current = texture(samp, tc);

    // Feedback parameters — slight zoom and rotation per layer
    float zoomPerLayer = 0.96 + 0.02 * sin(time_f * 0.5);
    float rotPerLayer = 0.03 * sin(time_f * 0.3);

    // Offset center drifts slowly
    vec2 feedbackCenter = vec2(
        0.5 + 0.02 * sin(time_f * 0.4),
        0.5 + 0.02 * cos(time_f * 0.35)
    );

    vec3 accum = current.rgb;
    float accWeight = 1.0;

    // Each cache layer applies compounding zoom + rotation
    // simulating multiple generations of feedback
    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Compound the transform: zoom^gen and rotation*gen
        float zoom = pow(zoomPerLayer, gen);
        float rot = rotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        vec2 fbUV = centered + feedbackCenter;

        vec4 cached = sampleCache(i, fbUV);

        // Feedback color shift: each generation drifts hue slightly
        float shift = gen * 0.02;
        cached.r *= 1.0 + shift;
        cached.g *= 1.0 - shift * 0.5;
        cached.b *= 1.0 + shift * 0.3;

        // Decay weight
        float w = pow(0.7, gen);
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // Slight contrast boost to keep feedback from going muddy
    accum = (accum - 0.5) * 1.15 + 0.5;
    accum = clamp(accum, 0.0, 1.0);

    color = vec4(accum, 1.0);
}
