#version 330 core
// ant_light_color_neon_rain
// Neon raindrop streaks with puddle splash ripples and spectrum-colored reflections

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 neon(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;

    // Rain streaks
    float rain = 0.0;
    vec3 rainColor = vec3(0.0);
    for (float i = 0.0; i < 15.0; i++) {
        float colX = hash(vec2(i, 0.0));
        float speed = 2.0 + hash(vec2(i, 1.0)) * 3.0 + bass * 2.0;
        float headY = fract(-iTime * speed * 0.15 + hash(vec2(i, 2.0)));
        float streakLen = 0.05 + hash(vec2(i, 3.0)) * 0.1;

        float dx = abs(uv.x - colX);
        float streakDist = dx * 100.0;
        float inStreak = smoothstep(1.0, 0.0, streakDist);

        float dy = uv.y - headY;
        float tail = smoothstep(streakLen, 0.0, dy) * step(0.0, dy);

        float drop = inStreak * tail;
        rainColor += neon(i * 0.07 + iTime * 0.1) * drop;
        rain += drop;
    }

    // Puddle ripples at bottom
    float puddle = smoothstep(0.2, 0.0, uv.y);
    float ripple = 0.0;
    for (float i = 0.0; i < 6.0; i++) {
        float rx = hash(vec2(i, 5.0));
        float rt = fract(iTime * 0.8 + hash(vec2(i, 6.0)));
        float rr = rt * 0.3;
        float d = length(vec2(uv.x - rx, uv.y * 3.0));
        ripple += sin(d * 50.0 - rt * 20.0) * (1.0 - rt) * smoothstep(rr + 0.05, rr, d);
    }

    // Texture with rain distortion
    vec2 distort = vec2(rain * 0.02, ripple * 0.01 * puddle);
    vec2 sampUV = uv + distort;

    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Rain neon overlay
    col += rainColor * (0.8 + air * 1.5);

    // Puddle neon reflections
    col += neon(uv.x + iTime * 0.2) * ripple * puddle * (0.3 + mid * 0.5);

    // Wet surface sheen
    col *= 1.0 + puddle * 0.3 * bass;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
