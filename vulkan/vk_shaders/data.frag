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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;                 // texture coordinates passed from vertex shader
layout(location = 0) out vec4 color;             // output fragment color

layout(set = 0, binding = 0) uniform sampler2D samp;     // input texture



// Simple 2D hash function to produce pseudo-random values
float hash(vec2 p) {
    // you can replace the constants with other prime-ish values if you want
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main(void)
{
    //-----------------------------------------------------
    // 1) Basic UV coordinates
    //-----------------------------------------------------
    vec2 uv = tc;  // copy the input texture coordinate
    
    //-----------------------------------------------------
    // 2) Block-based “glitch shift”
    //-----------------------------------------------------
    //
    //  - We divide the texture into blocks of a chosen size
    //  - Each block gets a pseudo-random float from `hash`
    //  - If that float is above a threshold, we shift that block
    //    horizontally by a time-based offset.
    //
    float blockSize = 0.02;                         // size of glitch blocks
    vec2 blockIndex = floor(uv / blockSize);        // which block are we in?
    float blockHash  = hash(blockIndex + floor(time_f)); // random per block + time
    
    // If blockHash is above 0.9, shift horizontally
    if (blockHash > 0.9) {
        // offset can be increased or decreased
        float xOffset = 0.1 * sin(time_f * 10.0);
        uv.x += xOffset;
    }
    
    //-----------------------------------------------------
    // 3) Subtle wave distortion
    //-----------------------------------------------------
    //
    //  - Add a sinusoidal wave along X or Y
    //  - Helps break up the image more “glitchily.”
    //
    float waveFreq = 20.0; 
    float waveAmp  = 0.01;  
    uv.x += waveAmp * sin((uv.y + time_f) * waveFreq);
    
    //-----------------------------------------------------
    // 4) Sample the texture with the “glitched” UV
    //-----------------------------------------------------
    color = texture(samp, uv);
}
