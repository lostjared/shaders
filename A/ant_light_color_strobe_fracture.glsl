#version 330 core
// ant_light_color_strobe_fracture
// Strobing fracture lines with XOR patterns and bass-reactive color bombs

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
    vec2 res = iResolution;

    // Pixelate for XOR pattern
    float pixSize = 4.0 + floor(bass * 8.0);
    vec2 px = floor(uv * res / pixSize) * pixSize;
    ivec2 ipx = ivec2(px);

    // XOR fracture pattern
    int xorVal = ipx.x ^ ipx.y ^ int(iTime * 5.0);
    float xorF = float(xorVal % 256) / 255.0;

    // Fracture lines from XOR edges
    float dx = abs(fract(uv.x * res.x / pixSize) - 0.5);
    float dy = abs(fract(uv.y * res.y / pixSize) - 0.5);
    float fracture = smoothstep(0.48, 0.5, max(dx, dy));

    // Base texture
    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, uv + vec2(chroma * xorF, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(chroma * xorF, 0.0)).b;

    // XOR color overlay
    vec3 xorColor = rainbow(xorF + iTime * 0.2);
    col = mix(col, col * xorColor, 0.2 + mid * 0.4);

    // Fracture line neon glow
    col += rainbow(xorF + iTime * 0.3) * fracture * (1.5 + air * 2.5);

    // Strobe: bass-triggered flash
    float strobe = step(0.8, bass) * step(0.5, fract(iTime * 8.0));
    col += rainbow(iTime) * strobe * 0.5;

    // Color bomb: expanding ring on peak
    vec2 center = (uv - 0.5) * vec2(res.x / res.y, 1.0);
    float bombR = length(center);
    float bombWave = fract(iTime * 0.5) * 2.0;
    float bomb = smoothstep(0.05, 0.0, abs(bombR - bombWave)) * amp_peak;
    col += rainbow(bombR + iTime) * bomb * 3.0;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
