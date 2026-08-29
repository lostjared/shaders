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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define iTimeDelta ext.u1.x
#define iamp ext.u1.z
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;


layout(set = 0, binding = 0) uniform sampler2D samp; // input video frame texture













// Produce a tileable, seam-free version of an arbitrary input texture so it
// can be wrapped onto 3D geometry without a visible edge. This uses the
// classic "offset-and-blend" trick: we sample the source at the original uv
// and at a half-texture offset, then blend the two using weights that drop
// to zero near the tile boundary. The result is fully periodic in both u
// and v, meaning the left edge matches the right edge and the top edge
// matches the bottom edge regardless of the source image content.
vec4 seamlessSample(vec2 uv) {
    // Wrap into [0,1) so the shader is periodic.
    vec2 u = fract(uv);

    // Primary sample at the tile's own coordinates.
    vec4 a = texture(samp, u);

    // Secondary sample offset by half a tile. Because this sample uses the
    // same fract() domain, its seams land in the middle of our tile, where
    // the primary sample is strongest - so its seams are hidden.
    vec4 b = texture(samp, fract(u + vec2(0.5)));

    // Weight that is 1 at the tile center and smoothly fades to 0 at the
    // tile edges. Multiplying by a similarly shaped weight on the offset
    // sample (which peaks at the edges) gives a partition of unity, so the
    // final color is continuous across the seam.
    vec2 d = abs(u - 0.5) * 2.0;               // 0 at center, 1 at edges
    float wCenter = (1.0 - smoothstep(0.35, 0.5, d.x))
                  * (1.0 - smoothstep(0.35, 0.5, d.y));
    float wEdge   = 1.0 - wCenter;

    return a * wCenter + b * wEdge;
}

void main(void) {
    color = seamlessSample(tc);
}

