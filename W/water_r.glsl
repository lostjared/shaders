#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

void main(void) {
    // Channel-specific parameters
    float speedR = 5.0;
    float amplitudeR = 0.03;
    float wavelengthR = 10.0;

    float speedG = 6.5;
    float amplitudeG = 0.025;
    float wavelengthG = 12.0;

    float speedB = 4.0;
    float amplitudeB = 0.035;
    float wavelengthB = 8.0;

    // Red channel wave (diagonal)
    float rippleR = sin(tc.x * wavelengthR + time_f * speedR) * amplitudeR;
    rippleR += sin(tc.y * wavelengthR * 0.8 + time_f * speedR * 1.2) * amplitudeR;
    vec2 rippleTC_R = tc + vec2(rippleR, rippleR);

    // Green channel wave (horizontal emphasis)
    float rippleG = sin(tc.x * wavelengthG * 1.5 + time_f * speedG) * amplitudeG;
    rippleG += sin(tc.y * wavelengthG * 0.3 + time_f * speedG * 0.7) * amplitudeG;
    vec2 rippleTC_G = tc + vec2(rippleG, -rippleG * 0.5);

    // Blue channel wave (vertical emphasis)
    float rippleB = sin(tc.x * wavelengthB * 0.5 + time_f * speedB) * amplitudeB;
    rippleB += sin(tc.y * wavelengthB * 1.7 + time_f * speedB * 1.3) * amplitudeB;
    vec2 rippleTC_B = tc + vec2(rippleB * 0.3, rippleB);

    // Sample texture with different displacements for each channel
    vec4 originalColor = texture(samp, tc);
    originalColor.r = texture(samp, rippleTC_R).r;
    originalColor.g = texture(samp, rippleTC_G).g;
    originalColor.b = texture(samp, rippleTC_B).b;

    color = originalColor;
}