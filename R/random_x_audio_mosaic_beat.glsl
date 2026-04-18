#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    // RMS controls mosaic resolution (low RMS = big pixels, high RMS = small pixels)
    float mosaicSize = mix(64.0, 4.0, clamp(amp_rms * 3.0, 0.0, 1.0));
    vec2 mosaicUV = floor(tc * iResolution / mosaicSize) * mosaicSize / iResolution;

    // Center of each mosaic cell
    vec2 cellCenter = mosaicUV + (mosaicSize * 0.5) / iResolution;

    vec3 tex = texture(samp, cellCenter).rgb;

    // Bass adds color quantization (fewer colors on beat)
    float levels = 16.0 - amp_low * 12.0;
    levels = max(levels, 2.0);
    tex = floor(tex * levels) / levels;

    // Mids shift cell borders
    vec2 cellFrac = fract(tc * iResolution / mosaicSize);
    float border = step(cellFrac.x, 0.05 + amp_mid * 0.1) + step(cellFrac.y, 0.05 + amp_mid * 0.1);
    border = min(border, 1.0);
    tex = mix(tex, tex * 0.5, border * 0.5);

    // Treble adds sparkle to random cells
    float sparkle = fract(sin(dot(mosaicUV, vec2(12.9898, 78.233)) + time_f) * 43758.5453);
    if (sparkle < amp_high * 0.2) {
        tex += amp_high * 0.4;
    }

    // Peak flash
    tex += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    // Smooth brightness
    tex *= 1.0 + amp_smooth * 0.15;

    color = vec4(clamp(tex, 0.0, 1.0), 1.0);
}
