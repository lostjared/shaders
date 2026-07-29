#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

void main(void) {
    // Wave parameters
    float speedR = 5.0;
    float amplitudeR = 0.03;
    float wavelengthR = 10.0;

    float speedG = 6.5;
    float amplitudeG = 0.025;
    float wavelengthG = 12.0;

    float speedB = 4.0;
    float amplitudeB = 0.035;
    float wavelengthB = 8.0;

    // Create wave displacements
    float rippleR = sin(tc.x * wavelengthR + time_f * speedR) * amplitudeR;
    rippleR += sin(tc.y * wavelengthR * 0.8 + time_f * speedR * 1.2) * amplitudeR;
    vec2 rippleTC_R = tc + vec2(rippleR, rippleR);

    float rippleG = sin(tc.x * wavelengthG * 1.5 + time_f * speedG) * amplitudeG;
    rippleG += sin(tc.y * wavelengthG * 0.3 + time_f * speedG * 0.7) * amplitudeG;
    vec2 rippleTC_G = tc + vec2(rippleG, -rippleG * 0.5);

    float rippleB = sin(tc.x * wavelengthB * 0.5 + time_f * speedB) * amplitudeB;
    rippleB += sin(tc.y * wavelengthB * 1.7 + time_f * speedB * 1.3) * amplitudeB;
    vec2 rippleTC_B = tc + vec2(rippleB * 0.3, rippleB);

    // Pattern configuration
    const vec3 patterns[4] = vec3[](
        vec3(1.0, 0.0, 1.0), // R and B mirrored
        vec3(0.0, 1.0, 0.0), // G mirrored
        vec3(1.0, 0.0, 0.0), // R mirrored
        vec3(0.0, 0.0, 1.0)  // B mirrored
    );
    
    // Pattern cycling
    float patternSpeed = 4.0; // Changes per second
    int patternIndex = int(mod(time_f * patternSpeed, 4.0));
    vec3 mirrorFlags = patterns[patternIndex];

    // Apply mirror effects
    vec2 finalTC_R = vec2(mirrorFlags.r > 0.5 ? 1.0 - rippleTC_R.x : rippleTC_R.x, rippleTC_R.y);
    vec2 finalTC_G = vec2(mirrorFlags.g > 0.5 ? 1.0 - rippleTC_G.x : rippleTC_G.x, rippleTC_G.y);
    vec2 finalTC_B = vec2(mirrorFlags.b > 0.5 ? 1.0 - rippleTC_B.x : rippleTC_B.x, rippleTC_B.y);

    // Sample channels with combined effects
    vec4 originalColor = texture(samp, tc);
    originalColor.r = texture(samp, finalTC_R).r;
    originalColor.g = texture(samp, finalTC_G).g;
    originalColor.b = texture(samp, finalTC_B).b;

    color = originalColor;
}
