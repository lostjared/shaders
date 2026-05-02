#version 330

in vec2 tc;
out vec4 color;

// Current Frame
uniform sampler2D samp;

// 8 History Buffers
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

// Helper to select one of the 8 cached textures dynamically
vec4 getHistoryFrame(int index, vec2 uv) {
    // Clamp index to valid range 0-7 just in case
    int safe_idx = index % 8;

    if (safe_idx == 0)
        return texture(samp1, uv);
    if (safe_idx == 1)
        return texture(samp2, uv);
    if (safe_idx == 2)
        return texture(samp3, uv);
    if (safe_idx == 3)
        return texture(samp4, uv);
    if (safe_idx == 4)
        return texture(samp5, uv);
    if (safe_idx == 5)
        return texture(samp6, uv);
    if (safe_idx == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
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
    // We space them out in the history buffer (e.g., 0, 3, 6).
    int r_idx = (strobe + 0) % 8;
    int g_idx = (strobe + 3) % 8;
    int b_idx = (strobe + 6) % 8;

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
    color = vec4(newR, newG, newB, 1.0);
}