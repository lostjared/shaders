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
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);

    // Peaks trigger shockwave rings that expand outward
    float waveSpeed = 3.0;
    float waveTime = mod(time_f, 2.0);
    float waveRadius = waveTime * waveSpeed * (0.5 + amp_peak * 1.0);

    // Ring distortion
    float ringWidth = 0.15 + amp_low * 0.1;
    float ringDist = abs(dist - waveRadius);
    float ring = smoothstep(ringWidth, 0.0, ringDist);

    // Displacement from ring
    float displacement = ring * (0.05 + amp_peak * 0.08);
    vec2 shockUV = tc + normalize(uv + 0.001) * displacement;
    shockUV = clamp(shockUV, 0.0, 1.0);

    vec4 tex = texture(samp, shockUV);

    // Ring visible glow - mids color it
    float hue = fract(time_f * 0.2 + amp_mid);
    vec3 ringColor = vec3(
        0.5 + 0.5 * sin(hue * 6.28),
        0.5 + 0.5 * sin(hue * 6.28 + 2.09),
        0.5 + 0.5 * sin(hue * 6.28 + 4.18));
    tex.rgb += ring * ringColor * (0.3 + amp_peak * 0.5);

    // Treble adds a second faster ring
    float wave2Radius = mod(time_f * 1.5, 1.5) * waveSpeed * 1.5;
    float ring2 = smoothstep(0.08, 0.0, abs(dist - wave2Radius));
    tex.rgb += ring2 * amp_high * 0.3 * vec3(0.3, 0.5, 1.0);

    // Smooth brightness
    tex.rgb *= 1.0 + amp_smooth * 0.15;

    color = tex;
}
