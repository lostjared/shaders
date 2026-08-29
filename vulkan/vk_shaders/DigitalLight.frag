#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define seed ext.custom_uniforms[2].z
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;

// STRICT UNIFORM LIST
layout(set = 0, binding = 0) uniform sampler2D samp;







void main(void) {
    // --- STEP 1: SETUP ---
    // Calculate overall intensity based on audio levels
    // amp = smoothed volume, uamp = raw/instant volume
    float intensity = clamp(amp * 0.5 + uamp * 1.0, 0.0, 3.0);
    
    // Calculate the distortion amount. 
    // If audio is quiet (0.0), distortion is 0.0.
    float distAmt = 0.05 * intensity; 

    // --- STEP 2: CALCULATE CHANNEL OFFSETS ---
    vec2 uv = tc;
    
    // We use sine waves based on the texture coordinates, time, and seed
    // to create a "waving" distortion pattern.
    
    // Red Channel Offset
    // seed is added to phase to change the pattern
    float rR = sin(uv.y * 10.0 + time_f * 5.0 + seed) * distAmt;
    
    // Green Channel Offset
    // Different frequency (12.0) and phase offset (seed * 1.3) ensures it moves differently
    float rG = sin(uv.x * 12.0 + time_f * 4.0 + seed * 1.3) * distAmt;
    
    // Blue Channel Offset
    float rB = sin(uv.y * 8.0  + time_f * 6.0 + seed * 0.7) * distAmt;

    // Apply the offsets to the UV coordinates
    // We offset them in different directions for a chaotic look
    vec2 tcR = uv + vec2(rR, 0.0);      // Red moves horizontally
    vec2 tcG = uv + vec2(0.0, rG);      // Green moves vertically
    vec2 tcB = uv + vec2(rB, rB * 0.5); // Blue moves diagonally

    // --- STEP 3: SAMPLE TEXTURE ---
    vec4 texR = texture(samp, tcR);
    vec4 texG = texture(samp, tcG);
    vec4 texB = texture(samp, tcB);

    // --- STEP 4: RECOMBINE ---
    // Take the Red component from the Red sample, Green from Green, etc.
    vec3 finalCol = vec3(texR.r, texG.g, texB.b);
    
    // Preserve the alpha from the original coordinate or one of the shifted ones
    float alpha = texture(samp, tc).a;

    color = vec4(finalCol, alpha);
}