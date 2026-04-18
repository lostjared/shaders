#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

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
