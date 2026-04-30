#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform sampler1D spectrum; // Audio spectrum input
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec4 blur(sampler2D image, vec2 uv, vec2 resolution, float intensity) {
    // We can scale the blur offset based on audio intensity
    vec2 texelSize = (1.0 / resolution) * intensity; 
    vec4 result = vec4(0.0);
    
    float kernelVals[100] = float[](0.5, 1.0, 1.5, 2.0, 2.5, 2.5, 2.0, 1.5, 1.0, 0.5,
                                    1.0, 2.0, 2.5, 3.0, 3.5, 3.5, 3.0, 2.5, 2.0, 1.0,
                                    1.5, 2.5, 3.0, 3.5, 4.0, 4.0, 3.5, 3.0, 2.5, 1.5,
                                    2.0, 3.0, 3.5, 4.0, 4.5, 4.5, 4.0, 3.5, 3.0, 2.0,
                                    2.5, 3.5, 4.0, 4.5, 5.0, 5.0, 4.5, 4.0, 3.5, 2.5,
                                    2.5, 3.5, 4.0, 4.5, 5.0, 5.0, 4.5, 4.0, 3.5, 2.5,
                                    2.0, 3.0, 3.5, 4.0, 4.5, 4.5, 4.0, 3.5, 3.0, 2.0,
                                    1.5, 2.5, 3.0, 3.5, 4.0, 4.0, 3.5, 3.0, 2.5, 1.5,
                                    1.0, 2.0, 2.5, 3.0, 3.5, 3.5, 3.0, 2.5, 2.0, 1.0,
                                    0.5, 1.0, 1.5, 2.0, 2.5, 2.5, 2.0, 1.5, 1.0, 0.5);
    
    float kernelSum = 250.0; // Optimized: sum of kernelVals above

    for (int x = -5; x <= 4; ++x) {
        for (int y = -5; y <= 4; ++y) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(image, uv + offset) * kernelVals[(y + 5) * 10 + (x + 5)];
        }
    }

    return result / kernelSum;
}

vec4 colorShift(vec4 col, float audioMod) {
    // Use audioMod to rotate the phase of the cosine wave
    return vec4(
        0.5 + 0.5 * cos((col.r + audioMod) * 3.14159265 * 0.5),
        0.5 + 0.5 * cos((col.g + audioMod) * 3.14159265 * 0.5),
        0.5 + 0.5 * cos((col.b + audioMod) * 3.14159265 * 0.5),
        col.a
    );
}

void main(void) {
    // Sample the spectrum at different frequencies (0.0 = Bass, 0.5 = Mids, 1.0 = Highs)
    float bass = texture(spectrum, 0.05).r;  // Bass hit
    float mids = texture(spectrum, 0.5).r;   // Mid-range activity
    
    // Smooth the reaction or exaggerate it
    float pulse = bass * 2.0; 
    
    float time_t = pingPong(time_f, 10.0) + 1.0 + pulse;
    
    // We pass the bass pulse into the blur to make it "shake" or bloom on beat
    vec4 pix = blur(samp, tc, iResolution, 1.0 + (pulse * 0.5));
    
    pix = pix * time_t;
    
    // Shift colors based on mid-range audio activity
    pix = colorShift(pix, mids);
    
    pix.rgb = mix(vec3(1.0), pix.rgb, 0.8);
    color = pix;
}