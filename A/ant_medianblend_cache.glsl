#version 330 core
// ant_medianblend
// MedianBlend: Accumulates 8 frames with XOR blending

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

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;
uniform float time_f;

vec4 blur(sampler2D image, vec2 uv, vec2 resolution) {
    vec2 texelSize = 1.0 / resolution;
    vec4 result = vec4(0.0);
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

// Helper to select one of the 8 cached textures dynamically
vec4 getHistoryFrame(int index, vec2 uv) {
    // Clamp index to valid range 0-7 just in case
    int safe_idx = index % 8;
    
    if (safe_idx == 0) return texture(samp1, uv);
    else if (safe_idx == 1) return texture(samp2, uv);
    else if (safe_idx == 2) return texture(samp3, uv);
    else if (safe_idx == 3) return texture(samp4, uv);
    else if (safe_idx == 4) return texture(samp5, uv);
    else if (safe_idx == 5) return texture(samp6, uv);
    else if (safe_idx == 6) return texture(samp7, uv);
    else return texture(samp8, uv);
}


void main(void) {
    // Apply blur to current frame
    vec4 blurred = blur(samp, tc, iResolution);
    
    vec3 accumValue = vec3(0.0);
    for (int i = 0; i < 8; ++i) {
        vec4 histFrame = getHistoryFrame(i, tc);
        accumValue += histFrame.rgb;
    }
    
    // Sample spectrum at different frequencies for audio reactivity
    float specLow = texture(spectrum, 0.1 + amp_smooth * 0.1).r;
    float specMid = texture(spectrum, 0.4 + tc.x * 0.2 + amp_peak * 0.15).r;
    float specHigh = texture(spectrum, 0.8 + amp_peak * 0.2).r;
    
    // Create audio-reactive blend factor - boost it for visibility
    float audioBlend = mix(specLow, mix(specMid, specHigh, 0.5), 0.5) + 0.3;
    float timeWave = sin(iTime * audioBlend * 2.0 + tc.y * 10.0) * 0.5 + 0.5;
    
    // Modulate the XOR value intensity - stronger modulation
    uvec3 baseXorValue = uvec3(accumValue * 255.0) + uvec3(1u);
    uvec3 xorValue = uvec3(vec3(baseXorValue) * mix(0.3, 2.0, audioBlend));
    
    uvec3 pixelBits = uvec3(blurred.rgb * 255.0);
    uvec3 xorResult = (pixelBits ^ xorValue) % 255u;
    
    // Stronger blend - always apply some XOR, modulate with audio
    vec3 xorBlended = mix(blurred.rgb, vec3(xorResult) / 255.0, 0.5 + audioBlend * 0.8);
    vec3 result = xorBlended * 1.5; //mix(blurred.rgb, xorBlended, 0.5) * 1.1;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
