#version 330 core
// ant_gem_metal_lattice
// Metallic lattice grid with spectrum-reactive warping and prismatic color

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Rotating lattice driven by mid
    vec2 latticeUV = rot(time_f * 0.3 + mid * 1.0) * uv;

    // Grid scale reacts to bass
    float gridScale = 6.0 + bass * 4.0;
    vec2 grid = fract(latticeUV * gridScale) - 0.5;
    vec2 gridID = floor(latticeUV * gridScale);

    // Cross-shaped bars
    float barWidth = 0.08 + treble * 0.05;
    float hBar = smoothstep(barWidth, barWidth - 0.02, abs(grid.y));
    float vBar = smoothstep(barWidth, barWidth - 0.02, abs(grid.x));
    float lattice = max(hBar, vBar);

    // Second rotated layer
    vec2 latticeUV2 = rot(time_f * 0.3 + mid * 1.0 + 0.785) * uv;
    vec2 grid2 = fract(latticeUV2 * gridScale * 0.7) - 0.5;
    float hBar2 = smoothstep(barWidth * 0.7, barWidth * 0.7 - 0.02, abs(grid2.y));
    float vBar2 = smoothstep(barWidth * 0.7, barWidth * 0.7 - 0.02, abs(grid2.x));
    float lattice2 = max(hBar2, vBar2);

    // Combined lattice
    float finalLattice = max(lattice, lattice2 * 0.6);

    // Texture through lattice cells
    vec2 sampUV = tc + grid * 0.02 * (1.0 + mid);

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Metallic bar coloring
    float barHash = fract(sin(dot(gridID, vec2(12.9898, 78.233))) * 43758.5453);
    vec3 barColor = metalSpectrum(barHash + time_f * 0.15 + r * 0.5);

    vec3 finalColor = mix(baseTex, barColor, finalLattice * (0.5 + hiMid * 0.4));

    // Junction glow at intersections
    float junction = hBar * vBar;
    finalColor += metalSpectrum(time_f * 0.2 + r) * junction * (1.0 + bass * 2.0);

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.97, 0.93) * center * (1.5 + amp_peak * 2.0);

    color = vec4(finalColor, 1.0);
}
