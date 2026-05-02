#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

void main(void) {
    // 1. Audio Data
    float treble = texture(spectrum, 0.60).r;

    // 2. Base Signal
    vec3 col = texture(samp, tc).rgb;

    // 3. Edge Detection
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    float edge = fwidth(luma) * 10.0;

    // 4. Create the Mask (This is the missing piece)
    // Values between 0.02 and 0.08 define the sharpness of the "cling"
    float edgeMask = smoothstep(0.02, 0.08, edge * (1.0 + treble * 5.0));

    // 5. Generate Analog Artifacts
    // Dot crawl: small spatial interference pattern
    float dotCrawl = sin(tc.x * 600.0 + tc.y * 600.0 + time_f * 15.0);

    // Rainbow: color phase shift
    vec3 rainbow = 0.5 + 0.5 * cos(time_f + tc.xyx * 25.0 + vec3(0, 2, 4));

    // 6. Composition
    // We add the rainbow and dot crawl together, then apply the mask
    vec3 interference = (rainbow + dotCrawl * 0.25) * edgeMask;

    // Add the interference to the original signal
    col += interference * (0.5 + treble * 1.5);

    color = vec4(col, 1.0);
}