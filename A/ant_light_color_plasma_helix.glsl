#version 330 core
// ant_light_color_plasma_helix
// Double helix plasma strands with spectrum-driven twist rate and neon glow

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 p = uv;

    // Plasma field
    float plasma = 0.0;
    plasma += sin((p.x * 5.0 + iTime) * (1.0 + bass));
    plasma += sin((p.y * 5.0 + iTime * 0.7) * (1.0 + mid));
    plasma += sin((p.x + p.y + iTime) * 3.0);
    plasma += cos(length(p * 10.0 + iTime) * (2.0 + treble * 3.0));
    plasma *= 0.25;

    // Double helix strands
    float helixA = sin(p.y * 15.0 + iTime * 3.0 + bass * 5.0) * 0.15;
    float helixB = sin(p.y * 15.0 + iTime * 3.0 + bass * 5.0 + 3.14159) * 0.15;
    float strandA = smoothstep(0.04, 0.0, abs(p.x - helixA));
    float strandB = smoothstep(0.04, 0.0, abs(p.x - helixB));

    // Warped texture sampling
    vec2 warpUV = tc + vec2(plasma * 0.05, plasma * 0.03);
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, warpUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, warpUV).g;
    col.b = texture(samp, warpUV - vec2(chroma, 0.0)).b;

    // Plasma color overlay
    vec3 plasmaCol = rainbow(plasma + iTime * 0.2 + bass);
    col = mix(col, col * plasmaCol * 2.0, 0.3 + mid * 0.3);

    // Helix neon glow
    col += rainbow(iTime * 0.3 + p.y) * strandA * (2.0 + air * 4.0);
    col += rainbow(iTime * 0.3 + p.y + 0.5) * strandB * (2.0 + air * 4.0);

    // Connecting rungs between helices
    float rung = step(0.9, fract(p.y * 8.0 + iTime));
    float between = smoothstep(abs(helixB), abs(helixA), abs(p.x));
    col += rainbow(p.y + iTime) * rung * between * bass * 2.0;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
