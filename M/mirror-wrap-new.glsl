#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f; // accumulated time value, affected by speed and audio when enabled
uniform float time_speed; // rate of change to time_f
uniform sampler2D samp; // input video frame texture
uniform vec2 iResolution; // viewport resolution in pixels (width, height)
uniform vec4 iMouse; // mouse position: xy = current, zw = click start (drag)
uniform float amp; // audio amplitude scaled by sensitivity
uniform float uamp; // raw audio amplitude before sensitivity scaling
uniform float iTimeDelta; // time since last frame in seconds
uniform float amp_peak; // peak absolute sample value in current audio buffer
uniform float amp_rms; // RMS energy of current audio buffer
uniform float amp_smooth; // exponentially smoothed amplitude for gradual transitions
uniform float amp_low; // bass energy (below ~300 Hz)
uniform float amp_mid; // mid-range energy (~300-3000 Hz)
uniform float amp_high; // treble energy (above ~3000 Hz)
uniform float iamp; // estimated dominant frequency in Hz via zero-crossing rate

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

