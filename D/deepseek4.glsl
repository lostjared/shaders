#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

float ramp(float t, float cycle) {
    float phase = mod(t, cycle * 2.0);
    return smoothstep(0.0, 1.0, phase / cycle) -
           smoothstep(1.0, 2.0, phase / cycle);
}

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.333, 0.666)));
}

void main() {
    vec2 uv = tc;

    // Wave timing parameters (6 second cycles)
    float hCycle = 6.0;
    float vCycle = 5.5;
    float dCycle = 6.5;

    // Horizontal wave movement
    float hPhase = time_f * 0.5;
    float hWave = ramp(hPhase, hCycle) * 2.0 - 1.0;

    // Vertical wave movement
    float vPhase = time_f * 0.45;
    float vWave = ramp(vPhase, vCycle) * 2.0 - 1.0;

    // Diagonal wave movement
    float dPhase = time_f * 0.6;
    float dWave = ramp(dPhase, dCycle) * 2.0 - 1.0;

    // Create sustained wave patterns
    float waveX = sin(uv.x * 8.0 + hWave * 20.0);
    float waveY = sin(uv.y * 6.0 + vWave * 15.0);
    float waveD = sin((uv.x + uv.y) * 10.0 + dWave * 25.0);

    // Combine waves with different frequencies
    float combined = (waveX + waveY + waveD) / 3.0;

    // Create color gradient
    vec3 waveColor = rainbow(combined * 0.5 + 0.5 + time_f * 0.05);

    // Texture manipulation
    vec2 distort = vec2(
        combined * 0.02 * hWave,
        combined * 0.02 * vWave);

    vec4 tex = texture(samp, uv + distort);

    // Create moving color bands
    float colorBand = smoothstep(0.3, 0.7,
                                 sin(uv.x * 3.0 - hPhase * 0.5) *
                                     sin(uv.y * 2.0 + vPhase * 0.3) *
                                     sin((uv.x - uv.y) * 4.0 + dPhase * 0.4));

    // Blend with original texture
    color = mix(tex, vec4(waveColor, 1.0), colorBand * 0.6);

    // Add directional glow
    vec2 flowDir = normalize(vec2(hWave, vWave));
    float flowMask = dot(uv - 0.5, flowDir);
    color.rgb += waveColor * smoothstep(-0.5, 0.5, flowMask) * 0.2;

    // Chromatic movement
    color.r = texture(samp, uv + distort * 0.3).r;
    color.b = texture(samp, uv - distort * 0.3).b;

    color = sin(color * pingPong(time_f, 25.0));
    // Maintain original alpha
    color.a = tex.a;
}