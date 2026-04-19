#version 330 core
// ant_light_color_hologram_pulse
// Holographic scanlines with RGB phase separation and bass pulse waves

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

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;

    // Scanline distortion
    float scanFreq = 300.0 + treble * 200.0;
    float scan = sin(uv.y * scanFreq + iTime * 10.0) * 0.5 + 0.5;
    scan = pow(scan, 8.0);

    // Bass-driven horizontal wave distortion
    float wave = sin(uv.y * 20.0 + iTime * 3.0) * bass * 0.02;
    wave += sin(uv.y * 50.0 - iTime * 7.0) * treble * 0.008;

    // Phase-separated RGB channels
    float phase = iTime * 0.5 + bass * 2.0;
    vec3 col;
    col.r = texture(samp, uv + vec2(wave + 0.005 * sin(phase), 0.0)).r;
    col.g = texture(samp, uv + vec2(wave, 0.003 * cos(phase))).g;
    col.b = texture(samp, uv + vec2(wave - 0.005 * sin(phase), 0.0)).b;

    // Holographic rainbow sheen
    float sheen = sin(uv.y * 100.0 + uv.x * 50.0 + iTime * 5.0) * 0.5 + 0.5;
    vec3 holoColor = rainbow(uv.y * 3.0 + iTime * 0.3 + sheen);
    col = mix(col, col * holoColor, 0.2 + mid * 0.3);

    // Scanline glow
    col += rainbow(uv.y + iTime * 0.2) * scan * (0.3 + air * 0.5);

    // Pulse wave: horizontal light band
    float pulse = exp(-pow((uv.y - fract(iTime * 0.3)) * 8.0, 2.0));
    col += vec3(0.7, 0.9, 1.0) * pulse * (0.5 + bass * 1.5);

    // Edge static
    float edgeNoise = fract(sin(dot(floor(uv * vec2(iResolution.x, scanFreq)), vec2(12.9898, 78.233))) * 43758.5453);
    col += vec3(edgeNoise) * scan * treble * 0.3;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
