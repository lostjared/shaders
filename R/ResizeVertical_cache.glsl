#version 330

in vec2 tc;
out vec4 color;

// Current Frame
uniform sampler2D samp;

// History/Cache Frames (1-8)
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform vec2 iResolution;
uniform float time_f;

void main(void) {
    // --- 1. Parameter Setup ---
    int square_size = 64;

    // Updated to 8 slots
    int total_cache_slots = 8;

    // Speed of the cycling effect
    int start_index = int(time_f * 5.0);
    int start_dir = 1;

    // --- 2. Calculate Block & Index ---
    // Convert normalized UV to Pixel Y
    int y = int(tc.y * iResolution.y);
    int block_row = y / square_size;

    // period logic
    int period = 2 * (total_cache_slots - 1);
    if (period <= 0)
        period = 1;

    int start_pos = (start_dir == 1) ? start_index : (2 * (total_cache_slots - 1)) - start_index;

    int pos = (start_pos + block_row) % period;
    if (pos < 0)
        pos += period; // Handle negative mod

    int frame_index = (pos < total_cache_slots) ? pos : period - pos;

    // Clamp to be safe
    if (frame_index < 0)
        frame_index = 0;
    if (frame_index >= total_cache_slots)
        frame_index = total_cache_slots - 1;

    // --- 3. Sampling ---

    vec4 currentFrame = texture(samp, tc);
    vec4 historyFrame;

    // Explicit selection for 8 textures
    if (frame_index == 0) {
        historyFrame = texture(samp1, tc);
    } else if (frame_index == 1) {
        historyFrame = texture(samp2, tc);
    } else if (frame_index == 2) {
        historyFrame = texture(samp3, tc);
    } else if (frame_index == 3) {
        historyFrame = texture(samp4, tc);
    } else if (frame_index == 4) {
        historyFrame = texture(samp5, tc);
    } else if (frame_index == 5) {
        historyFrame = texture(samp6, tc);
    } else if (frame_index == 6) {
        historyFrame = texture(samp7, tc);
    } else {
        historyFrame = texture(samp8, tc);
    }

    // --- 4. Blending ---
    // 50% Current + 50% History
    color = (currentFrame * 0.5) + (historyFrame * 0.5);
    color.a = 1.0;
}