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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










void main(void) {
    vec2 uv = tc;

    // Grid resolution driven by RMS
    float gridSize = 8.0 + amp_rms * 24.0;
    vec2 grid = floor(uv * gridSize) / gridSize;
    vec2 gridFrac = fract(uv * gridSize);

    // Bass distorts each cell
    float bassWave = amp_low * 0.03 * sin(grid.x * 15.0 + time_f * 3.0);
    float midWave = amp_mid * 0.02 * cos(grid.y * 12.0 + time_f * 2.0);
    uv.x += bassWave;
    uv.y += midWave;

    // High frequencies add per-cell rotation
    float cellAngle = amp_high * sin(dot(grid, vec2(7.0, 13.0)) + time_f) * 0.3;
    vec2 cellCenter = grid + 0.5 / gridSize;
    vec2 off = uv - cellCenter;
    float c = cos(cellAngle), s = sin(cellAngle);
    uv = cellCenter + vec2(c * off.x - s * off.y, s * off.x + c * off.y);

    vec4 tex = texture(samp, clamp(uv, 0.0, 1.0));

    // Grid line overlay pulsing with peaks
    float lineWidth = 0.02 + amp_peak * 0.05;
    float gridLine = step(gridFrac.x, lineWidth) + step(gridFrac.y, lineWidth);
    gridLine = min(gridLine, 1.0);
    vec3 lineColor = vec3(0.1, 0.8, 1.0) * amp_smooth;
    tex.rgb = mix(tex.rgb, lineColor, gridLine * 0.5);

    // Peak flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.15;

    color = tex;
}
