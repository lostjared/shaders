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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

// ant_light_color_cyber_grid
// Retro cyber grid with perspective warp, neon scan beams, and bass pulse lines
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 neonPink(float t) {
    return vec3(1.0, 0.2, 0.6) * (0.5 + 0.5 * sin(t * TAU));
}

vec3 neonCyan(float t) {
    return vec3(0.1, 0.8, 1.0) * (0.5 + 0.5 * cos(t * TAU));
}

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;

    // Perspective grid transformation
    vec2 grid = uv;
    grid.y = 1.0 / (1.5 - uv.y + 0.01);
    grid.x = (uv.x - 0.5) * grid.y * 2.0;
    grid.y -= iTime * (1.0 + bass * 2.0);

    // Grid lines
    vec2 gridFrac = fract(grid * 5.0);
    float hLine = smoothstep(0.04, 0.0, abs(gridFrac.y - 0.5));
    float vLine = smoothstep(0.04, 0.0, abs(gridFrac.x - 0.5));
    float gridLine = max(hLine, vLine);

    // Texture sample with subtle grid warp
    vec2 sampUV = uv + vec2(gridLine * 0.005 * sin(iTime), 0.0);
    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Neon grid overlay
    vec3 gridColor = mix(neonPink(grid.x + iTime * 0.2), neonCyan(grid.y + iTime * 0.3), 0.5);
    col += gridColor * gridLine * (0.3 + mid * 0.5) * step(0.3, uv.y);

    // Scan beam moving forward
    float beam = exp(-pow((gridFrac.y - fract(iTime * 0.5)) * 10.0, 2.0));
    col += rainbow(grid.x + iTime) * beam * step(0.3, uv.y) * (0.5 + air * 1.0);

    // Horizon glow
    float horizon = exp(-pow((uv.y - 0.35) * 15.0, 2.0));
    col += rainbow(uv.x + iTime * 0.3) * horizon * (0.8 + bass * 1.5);

    // Bass pulse horizontal lines
    float pulseLine = smoothstep(0.01, 0.0, abs(fract(uv.y * 30.0 - iTime * 2.0) - 0.5));
    col += neonPink(iTime * 0.5) * pulseLine * bass * 0.5;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
