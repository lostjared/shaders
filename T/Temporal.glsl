#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    // --- 1. Parameter Setup (Simulating FilterParams) ---
    // Controls the height of the horizontal bands
    int square_size = 64;

    // Simulate the buffer size
    int numFrames = 30;

    // Simulate start_index moving over time
    int start_index = int(time_f * 20.0);
    int start_dir = 1;

    // --- 2. C++ Logic Translation ---

    // Convert normalized UV (0.0-1.0) to Pixel Y (0-Height)
    int y = int(tc.y * iResolution.y);

    int block_row = y / square_size;

    // period = 2 * (params.numFrames - 1);
    int period = 2 * (numFrames - 1);
    if (period <= 0) {
        period = 1;
    }

    // int start_pos = ...
    int start_pos = (start_dir == 1) ? start_index : (2 * (numFrames - 1)) - start_index;

    // int pos = (start_pos + block_row) % period;
    // Note: GLSL mod can be negative for negative inputs, so we ensure positivity
    int pos = (start_pos + block_row) % period;
    if (pos < 0)
        pos += period; // Safety for negative modulo results

    // int frame_index = ...
    int frame_index = (pos < numFrames) ? pos : period - pos;

    // Clamping checks
    if (frame_index < 0)
        frame_index = 0;
    if (frame_index >= numFrames)
        frame_index = numFrames - 1;

    // --- 3. Sampling & Blending ---

    // Sample Current Frame
    vec4 currentFrame = texture(samp, tc);

    // Simulate History Frame:
    // Since we don't have previous textures, we simulate "past time"
    // by offsetting the X coordinate based on the calculated frame_index.
    // This creates the "shifting bands" look.
    float timeDisplacement = float(frame_index) * 0.005; // 0.005 is the offset strength
    vec2 historyUV = tc;
    historyUV.x += timeDisplacement;

    // Wrap UVs if they go off screen
    if (historyUV.x > 1.0)
        historyUV.x -= 1.0;

    vec4 historyFrame = texture(samp, historyUV);

    // Blend: 50% Current + 50% History
    color = (currentFrame * 0.5) + (historyFrame * 0.5);

    // Ensure alpha is solid
    color.a = 1.0;
}