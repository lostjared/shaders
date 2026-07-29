#version 330 core

in vec2 tc;                 // texture coordinates passed from vertex shader
out vec4 color;             // output fragment color

uniform float time_f;       // time in seconds
uniform sampler2D samp;     // input texture
uniform vec2 iResolution;   // resolution (width, height)
uniform vec4 iMouse;        // mouse data (not used in this example)

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
