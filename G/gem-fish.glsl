#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float amp;
uniform float uamp;

void main(void) {
    // 1. Center and Normalize
    vec2 uv = tc - 0.5;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // 2. Define the Swirl and Zoom
    // 'swirl' increases rotation based on distance and time
    float swirl = angle + (dist * 5.0) + (time_f * 0.5 * amp);

    // 'zoom' pulls the texture coordinates inward over time
    float zoom = dist * (0.5 + sin(time_f * 0.2) * 0.2);

    // 3. Convert back to Cartesian for texture sampling
    vec2 warpedUV;
    warpedUV.x = cos(swirl) * zoom;
    warpedUV.y = sin(swirl) * zoom;

    // 4. Multi-tap Radial Sampling (The "Streak" Effect)
    // We sample multiple times to create the motion blur look in your image
    vec3 finalCol = vec3(0.0);
    int samples = 12;
    float blurSize = 0.1 * (amp + uamp);

    for (int i = 0; i < samples; i++) {
        float slice = float(i) / float(samples);
        float scale = 1.0 - (slice * blurSize);

        // Offset R, G, and B slightly for chromatic aberration
        vec2 rUV = (warpedUV * scale * 0.95) + 0.5;
        vec2 gUV = (warpedUV * scale * 1.00) + 0.5;
        vec2 bUV = (warpedUV * scale * 1.05) + 0.5;

        finalCol.r += texture(samp, rUV).r;
        finalCol.g += texture(samp, gUV).g;
        finalCol.b += texture(samp, bUV).b;
    }

    finalCol /= float(samples);

    // 5. Add that central "Open Source" glow from your image
    float centerGlow = smoothstep(0.4, 0.0, dist) * (1.0 + uamp);
    finalCol += vec3(0.6, 0.8, 1.0) * centerGlow * 0.5;

    color = vec4(finalCol, 1.0);
}