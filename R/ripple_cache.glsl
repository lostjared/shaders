#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;   // current frame
uniform sampler2D samp1;  // older frame #1
uniform sampler2D samp2;  // older frame #2
uniform sampler2D samp3;  // older frame #3
uniform sampler2D samp4;  // older frame #4

uniform vec2 iResolution;
uniform float time_f;

// A quick pseudo-random noise function
float rand2D(in vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void)
{
    // "uv" coordinates (same as tc)
    vec2 uv = tc;

    // 1) Create a circular ripple effect centered in the middle (0.5,0.5)
    float dist     = length(uv - 0.5);
    float ripple   = sin(dist * 30.0 - time_f * 5.0); 
    // ripple: oscillates based on distance & time

    // 2) Distort the texture coordinates by the ripple
    //    The 0.02 factor is how strong you want the ripple displacement.
    //    normalize(uv - 0.5) points outward from the center.
    vec2 rippleUV  = uv + 0.02 * ripple * normalize(uv - 0.5);

    // 3) Add a glitch offset derived from time-based noise
    //    We shift coordinates differently for each texture, adding variation.
    float glitch   = rand2D(uv + time_f * 0.1) * 2.0 - 1.0; 
    vec2 glitchOff = 0.01 * vec2(glitch, glitch); // how big a glitch jump

    // 4) Sample from your 4 older frames with slightly shifted coords
    //    to produce a ghostly "delayed" or "rippled" effect
    vec4 f1 = texture(samp1, rippleUV + glitchOff * 0.5);
    vec4 f2 = texture(samp2, rippleUV + glitchOff * 1.0);
    vec4 f3 = texture(samp3, rippleUV - glitchOff * 0.5);
    vec4 f4 = texture(samp4, rippleUV - glitchOff * 1.0);

    // Combine them (averaging all four)
    vec4 combined = (f1 + f2 + f3 + f4) * 0.25;

    // 5) Grab the current frame (the "live" or most-recent texture)
    //    normally un-distorted, or you could also ripple it if you like:
    vec4 baseTex = texture(samp, uv);

    // 6) Blend them together in a “glitchy” dynamic way:
    //    We'll oscillate the blend factor over time (and also by y)
    float glitchFactor = sin(time_f * 2.0 + uv.y * 20.0) * 0.5 + 0.5;
    // glitchFactor moves between 0.0 and 1.0

    // 7) Final color
    color = mix(baseTex, combined, glitchFactor);
    color.a = 1.0;
}
