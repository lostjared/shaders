#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// --- Helper Functions ---

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec4 blur(sampler2D image, vec2 uv, vec2 resolution) {
    vec2 texelSize = 1.0 / resolution;
    vec4 result = vec4(0.0);
    
    // 7x7 Gaussian Kernel
    float kernel[49];
    kernel[0] = 0.5; kernel[1] = 1.0; kernel[2] = 2.0; kernel[3] = 2.5; kernel[4] = 2.0; kernel[5] = 1.0; kernel[6] = 0.5;
    kernel[7] = 1.0; kernel[8] = 2.0; kernel[9] = 3.0; kernel[10] = 3.5; kernel[11] = 3.0; kernel[12] = 2.0; kernel[13] = 1.0;
    kernel[14] = 2.0; kernel[15] = 3.0; kernel[16] = 4.0; kernel[17] = 4.5; kernel[18] = 4.0; kernel[19] = 3.0; kernel[20] = 2.0;
    kernel[21] = 2.5; kernel[22] = 3.5; kernel[23] = 4.5; kernel[24] = 5.0; kernel[25] = 4.5; kernel[26] = 3.5; kernel[27] = 2.5;
    kernel[28] = 2.0; kernel[29] = 3.0; kernel[30] = 4.0; kernel[31] = 4.5; kernel[32] = 4.0; kernel[33] = 3.0; kernel[34] = 2.0;
    kernel[35] = 1.0; kernel[36] = 2.0; kernel[37] = 3.0; kernel[38] = 3.5; kernel[39] = 3.0; kernel[40] = 2.0; kernel[41] = 1.0;
    kernel[42] = 0.5; kernel[43] = 1.0; kernel[44] = 2.0; kernel[45] = 2.5; kernel[46] = 2.0; kernel[47] = 1.0; kernel[48] = 0.5;

    float kernelSum = 272.0;

    for (int x = -3; x <= 3; ++x) {
        for (int y = -3; y <= 3; ++y) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(image, uv + offset) * kernel[(y + 3) * 7 + (x + 3)];
        }
    }

    return result / kernelSum;
}

// --- Logic Adapted from CUDA Input ---

// Applies contrast boost and an overall brightness multiplier
vec3 applyContrastAndBrightness(vec3 col) {
    float contrastBoost = 1.8;
    float midpoint = 0.5; 
    
    // === BRIGHTNESS CONTROL ===
    // Adjust this value. 1.0 = original, > 1.0 = brighter.
    float brightnessScale = 1.5; 
    
    vec3 result;
    // Apply Contrast first
    result.r = midpoint + (col.r - midpoint) * contrastBoost;
    result.g = midpoint + (col.g - midpoint) * contrastBoost;
    result.b = midpoint + (col.b - midpoint) * contrastBoost;
    
    // Apply Brightness scale next
    result *= brightnessScale;
    
    return clamp(result, 0.0, 1.0);
}

// Emulates: curB ^ (unsigned char)(1 + sumB)
vec3 cudaXorLogic(vec3 current, vec3 averaged, float sum_simulator) {
    ivec3 iCur = ivec3(current * 255.0);
    
    // Simulate "Sum" growing over frames by multiplying the average by time
    ivec3 iSum = ivec3(averaged * 255.0 * sum_simulator); 
    
    ivec3 iXor;
    // The bitwise XOR
    iXor.r = iCur.r ^ int((1 + iSum.r) % 255);
    iXor.g = iCur.g ^ int((1 + iSum.g) % 255);
    iXor.b = iCur.b ^ int((1 + iSum.b) % 255);
    
    // Ensure we stay in byte range before converting back to float
    return vec3(iXor % 255) / 255.0;
}

void main(void) {
    // 1. Get the Sharp Image (represents 'currentFrame')
    vec4 sharpColor = texture(samp, tc);
    
    // 2. Get the Blurred Image (represents 'average' of frames)
    vec4 blurredColor = blur(samp, tc, iResolution);
    
    // 3. Setup Time variable to simulate the "Sum" accumulation
    float time_t = pingPong(time_f, 10.0) + 2.0;
    
    // 4. Perform the XOR Logic
    vec3 xorResult = cudaXorLogic(sharpColor.rgb, blurredColor.rgb, time_t);
    
    // 5. Blend: (XOR * 0.5) + (Avg * 0.5)
    vec3 blendResult = (xorResult * 0.5) + (blurredColor.rgb * 0.5);
    
    // 6. Apply Contrast and Brightness Boost
    color = vec4(applyContrastAndBrightness(blendResult), 1.0);
}