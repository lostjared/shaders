#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// Random function for noise effects
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Chromatic aberration effect
vec3 chromaticAberration(vec2 uv, float intensity) {
    float r = texture(samp, uv + vec2(intensity, 0.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - vec2(intensity, 0.0)).b;
    return vec3(r, g, b);
}

void main(void) {
    vec2 uv = tc;

    // Tape stretch/wobble
    uv.y += sin(time_f * 2.0 + uv.x * 20.0) * 0.005;

    // Vertical jitter
    float vjitter = (rand(vec2(time_f)) - 0.5) * 0.02;
    uv.y = mod(uv.y + vjitter, 1.0);

    // Horizontal jitter
    uv.x += sin(time_f * 10.0) * 0.005;

    // Head switching effect (horizontal glitch line)
    float scanLine = fract(time_f * 0.5);
    if (abs(uv.y - scanLine) < 0.005 + rand(vec2(time_f)) * 0.01) {
        uv.x += (rand(vec2(uv.y + time_f)) - 0.5) * 0.1;
    }

    // Chromatic aberration
    vec3 col = chromaticAberration(uv, 0.003 + rand(uv) * 0.003);

    // Add noise
    float noiseIntensity = 0.3;
    vec3 noise = vec3(rand(uv * time_f)) * noiseIntensity;
    col += noise;

    // Horizontal scan lines
    float scanLines = sin(uv.y * 800.0 + time_f * 10.0) * 0.1;
    col -= scanLines * 0.1;

    // Color bleed (red and blue channels lag)
    vec2 bleedOffset = vec2(0.002 + sin(time_f) * 0.001, 0.0);
    col.r = texture(samp, uv + bleedOffset).r;
    col.b = texture(samp, uv - bleedOffset).b;

    // Tape damage (random dropouts)
    if (rand(vec2(time_f * 0.1, uv.y)) > 0.99) {
        col *= 0.1 + rand(uv) * 0.5;
    }

    // VHS color distortion
    col = mix(col, col.grb, sin(time_f) * 0.1);

    // Flicker effect
    col *= 0.9 + 0.1 * rand(vec2(time_f * 0.5));

    // Add VHS tracking lines
    float trackLines = step(0.995, rand(vec2(uv.y * 100.0, time_f)));
    col += trackLines * 0.3;

    // Output final color
    color = vec4(col, 1.0);

    // Tape edge distortion
    color *= smoothstep(0.0, 0.1, uv.y) * smoothstep(1.0, 0.9, uv.y);
}