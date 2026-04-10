#version 330 core

in vec2 tc;                  // Texcoords passed from vertex shader
out vec4 color;              // Final color output of the fragment

uniform float time_f;        // Time (in seconds, typically)
uniform sampler2D samp;      // The texture we're sampling
uniform vec2 iResolution;    // Resolution of the window/viewport
uniform vec4 iMouse;         // Mouse data (if needed)
uniform float amp;           // Total amplitude
uniform float uamp;          // Current amplitude * sensitivity

// (Optional) swirl function for more controlled “twisting”
vec2 swirl(vec2 uv, float centerRadius, float swirlAmount) {
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    // The 'f' blend factor makes the swirl die off
    // outside of 'centerRadius'
    float f = smoothstep(centerRadius, 0.0, r);
    a += swirlAmount * f;
    return r * vec2(cos(a), sin(a));
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void)
{
    // Combine your amplitude inputs (adjust to taste)
    float A = uamp * amp / time_f;

    // Normalized device coordinates in range [-1, +1],
    // preserving the aspect ratio
    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    // Add swirling based on time and amplitude
    uv = swirl(uv, 0.8, 2.0 * A * sin(time_f * 0.5));

    // Convert back to [0,1] range for sampling
    uv.x /= aspect;
    uv = uv * 0.5 + 0.5;

    // Read the base texture
    vec4 baseColor = texture(samp, uv);

    // Add a color-shift effect that pulsates with time and amplitude
    // The sin() terms use different frequencies for each color channel
    float pulseR = 0.3 * sin(time_f * 3.0 + A * 4.0);
    float pulseG = 0.3 * sin(time_f * 5.0 + A * 6.0);
    float pulseB = 0.3 * sin(time_f * 7.0 + A * 2.0);

    // Blend them into the sampled texture
    baseColor.r += pulseR;
    baseColor.g += pulseG;
    baseColor.b += pulseB;

    // Optional: Additional offset or “kaleidoscopic” swirl
    // This can be turned up if you want extreme distortion
    uv = swirl(uv - 0.5, 1.0, A * 10.0) + 0.5;
    baseColor *= texture(samp, uv);

    // Output the final color
    float t_amp = pingPong(amp, 8.0);
    color = sin(baseColor * (t_amp + uamp));
    color.a = 1.0;  // Opaque, or adjust if needed
}
