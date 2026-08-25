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
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;   // current frame
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif



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
    vec4 f1 = texture(history, vec3(rippleUV + glitchOff * 0.5, float(CACHE_HISTORY_LAYER(0))));
    vec4 f2 = texture(history, vec3(rippleUV + glitchOff * 1.0, float(CACHE_HISTORY_LAYER(1))));
    vec4 f3 = texture(history, vec3(rippleUV - glitchOff * 0.5, float(CACHE_HISTORY_LAYER(2))));
    vec4 f4 = texture(history, vec3(rippleUV - glitchOff * 1.0, float(CACHE_HISTORY_LAYER(3))));

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
