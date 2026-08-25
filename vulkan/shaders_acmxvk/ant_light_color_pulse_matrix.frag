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

// ant_light_color_pulse_matrix
// Digital matrix rain with pulsing brightness columns and spectrum-colored characters
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float TAU = 6.28318530718;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 matrix(float t) {
    return mix(vec3(0.0, 1.0, 0.3), vec3(0.3, 0.6, 1.0), fract(t));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc;

    // Column grid
    float cols = 40.0;
    float rows = 30.0;
    vec2 cell = vec2(floor(uv.x * cols), floor(uv.y * rows));
    vec2 cellUV = fract(vec2(uv.x * cols, uv.y * rows));

    // Rain speed per column
    float colHash = hash(vec2(cell.x, 0.0));
    float speed = 1.0 + colHash * 3.0 + bass * 2.0;
    float rain = fract(-iTime * speed * 0.2 + colHash * 10.0);

    // Character hash (changing over time)
    float charHash = hash(cell + floor(iTime * speed));

    // Lead brightness (brightest at rain front)
    float distFromHead = fract(uv.y + rain);
    float trail = smoothstep(0.5, 0.0, distFromHead) * step(0.0, distFromHead);
    float head = smoothstep(0.03, 0.0, abs(distFromHead)) * 3.0;
    float bright = trail + head;

    // Character shape simulation (simple cross-hatch)
    float charShape = step(0.3, charHash) * step(0.2, cellUV.x) * step(cellUV.x, 0.8);
    charShape *= step(0.15, cellUV.y) * step(cellUV.y, 0.85);

    // Texture sample
    vec3 col = texture(samp, uv).rgb;

    // Matrix color overlay
    vec3 matCol = matrix(cell.x * 0.05 + iTime * 0.1 + mid);
    col += matCol * bright * charShape * (0.5 + air * 1.0);

    // Column pulse on bass
    float pulse = sin(cell.x * 0.5 + iTime * 8.0) * 0.5 + 0.5;
    pulse = pow(pulse, 8.0);
    col += matCol * pulse * bass * charShape * 0.5;

    // Spectrum color shift per column
    float specBand = cell.x / cols;
    float specVal = texture(spectrum, specBand).r;
    col += matrix(specBand + iTime * 0.2) * specVal * trail * charShape * 0.3;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
