#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec4 iMouse;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float a = random(ip);
    float b = random(ip + vec2(1.0, 0.0));
    float c = random(ip + vec2(0.0, 1.0));
    float d = random(ip + vec2(1.0, 1.0));
    fp = fp * fp * (3.0 - 2.0 * fp);
    return mix(a, b, fp.x) + (c - a) * fp.y * (1.0 - fp.x) + (d - b) * fp.x * fp.y;
}

float fractalNoise(vec2 p) {
    float v = 0.0;
    v += noise(p * 1.0) * 1.0;
    v += noise(p * 2.0) * 0.5;
    v += noise(p * 4.0) * 0.25;
    v += noise(p * 8.0) * 0.125;
    return v / 1.875;
}

void main(void) {
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = tc;

    // Mouse influence
    vec2 mouse = iMouse.xy;
    float mouseInfluence = 0.0;
    if (iMouse.z > 0.0) {
        mouseInfluence = 1.0 - smoothstep(0.0, 0.5, length(mouse - uv));
    }

    // Base distortion
    float time = time_f * 2.0;
    vec2 tcFromCenter = uv - center;
    float distance = length(tcFromCenter);
    float angle = atan(tcFromCenter.y, tcFromCenter.x);

    // Intense twirl effect
    float twirl = 10.0 * (1.0 - smoothstep(0.0, 0.8, distance)) + time * 5.0;
    angle += twirl * (0.5 + sin(time * 0.7) * 0.5 + mouseInfluence * 2.0);

    // Chaotic displacement
    vec2 displacement = vec2(
                            fractalNoise(uv * 10.0 + time * 2.0) - 0.5,
                            fractalNoise(uv * 10.0 + time * 1.5) - 0.5) *
                        0.2 * (0.5 + mouseInfluence * 2.0);

    // Radial wave distortion
    float radialWave = sin(distance * 30.0 - time * 10.0) * 0.1;
    radialWave += sin(angle * 5.0 + time * 5.0) * 0.05;

    // Combine distortions
    float radius = distance * (1.0 + radialWave * 2.0 + mouseInfluence);
    vec2 distortedTC = center + vec2(cos(angle), sin(angle)) * radius;
    distortedTC += displacement * (1.0 + sin(time * 10.0) * 0.5);

    // Glitch jumps
    float glitchIntensity = (sin(time * 3.0) * 0.5 + 0.5) * 0.3 + mouseInfluence * 0.5;
    if (random(vec2(time)) > 0.7) {
        distortedTC.x += (random(vec2(time)) - 0.5) * glitchIntensity;
        distortedTC.y += (random(vec2(time * 0.7)) - 0.5) * glitchIntensity;
    }

    // Color channel splitting
    vec4 color1 = texture(samp, distortedTC + vec2(glitchIntensity * 0.02, 0.0));
    vec4 color2 = texture(samp, distortedTC - vec2(glitchIntensity * 0.02, 0.0));
    color = vec4(color1.r, color2.g, color1.b, 1.0);

    // Scan line effect
    float scanLine = sin(uv.y * 800.0 + time * 10.0) * 0.1;
    color.rgb += scanLine * glitchIntensity;

    // Chromatic aberration
    vec2 chromaOffset = vec2(
        fractalNoise(uv * 50.0 + time) * 0.02,
        fractalNoise(uv * 50.0 + time * 1.2) * 0.02);
    color.r = texture(samp, distortedTC + chromaOffset).r;
    color.b = texture(samp, distortedTC - chromaOffset).b;

    // Contrast boost
    color.rgb = mix(color.rgb, smoothstep(0.0, 1.0, color.rgb * 1.2), 0.5);

    // Random black flashes
    if (random(vec2(time * 0.3)) > 0.97) {
        color.rgb *= 0.1;
    }

    // Vignette
    float vignette = 1.0 - smoothstep(0.4, 0.8, distance);
    //   color.rgb *= vignette;
}