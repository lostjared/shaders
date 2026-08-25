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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// Current Frame
layout(set = 0, binding = 0) uniform sampler2D samp;

// 8 History Buffers
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif



// Helper to select one of the cached textures dynamically
vec4 getHistoryFrame(int index, vec2 uv) {
    // A sampler2DArray natively accepts the layer index as the z-component.
    // The macro evaluates the integer math dynamically without needing branches.
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(index))));
}

void main(void) {
    // 1. Calculate the Strobe/Cycle Index based on time
    // Controls how fast the color assignments cycle through the history buffer
    int speed = 10; 
    int strobe = int(time_f * float(speed));
    
    // 2. Sample Current Frame
    vec4 current = texture(samp, tc);
    
    // 3. Define Offsets for R, G, B channels
    // This creates the "Trail" separation. 
    // We space them out in the history buffer using the SIZE macro.
    int r_idx = (strobe + 0) % SIZE;
    int g_idx = (strobe + 3) % SIZE;
    int b_idx = (strobe + 6) % SIZE;
    
    // 4. Sample the specific history frames for each channel
    vec4 histR = getHistoryFrame(r_idx, tc);
    vec4 histG = getHistoryFrame(g_idx, tc);
    vec4 histB = getHistoryFrame(b_idx, tc);
    
    // 5. Apply the Kernel Logic: 50% Current + 50% History
    // We apply this individually per channel
    float newR = (0.5 * current.r) + (0.5 * histR.r);
    float newG = (0.5 * current.g) + (0.5 * histG.g);
    float newB = (0.5 * current.b) + (0.5 * histB.b);
    
    // 6. Output Final Color
    color = vec4(newR, newG, newB, current.a);
}