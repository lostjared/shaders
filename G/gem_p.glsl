#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float amp;
uniform float uamp;

vec3 getRainbow(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 0.7, 0.4);
    vec3 d = vec3(0.0, 0.15, 0.20);
    return a + b * cos(6.28318 * (c * t + d + time_f * 0.5));
}

vec2 rotate(vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

void main(void) {
    // 1. Setup Coordinates
    vec2 uv = tc;
    vec2 centeredUV = (uv * 2.0 - 1.0);
    centeredUV.x *= iResolution.x / iResolution.y;

    // 2. Complex Polar Distortion (The "10x" complexity)
    float r = length(centeredUV);
    float angle = atan(centeredUV.y, centeredUV.x);

    // Create 3 layers of interference patterns
    float noise = sin(angle * 5.0 + time_f) * 0.1;
    noise += sin(r * 20.0 - time_f * 2.0) * 0.05;

    // Domain Warping: Use the spiral math to bend the texture coordinates
    float spiral = sin(15.0 * r - time_f * 4.0 + (angle * 4.0));
    float twist = cos(10.0 * r + time_f + spiral);

    // 3. Apply distortion back to the Texture UVs
    // This makes the "samp" texture melt and swirl
    vec2 distortedTC = tc;
    distortedTC.x += (spiral * 0.03) * cos(angle);
    distortedTC.y += (twist * 0.03) * sin(angle);

    // Sample the original texture with the distorted coordinates
    vec4 tex = texture(samp, distortedTC);

    // 4. Generate the "Fractal" Color Layer
    // Layering multiple sine waves for that oily, chromatic look
    float colorPattern = sin(r * 12.0 - time_f * 3.0 + angle * 2.0);
    colorPattern += cos(uv.x * 10.0 + time_f) * 0.5;
    colorPattern += sin(uv.y * 10.0 - time_f) * 0.5;

    vec3 psychedelicOverlay = getRainbow(colorPattern * 0.5 + r);

    // 5. Final Composite
    // Mix the original texture (distorted) with the rainbow patterns
    // We use "Screen" or "Addition" style blending for maximum vibrancy
    vec3 finalRGB = mix(tex.rgb, psychedelicOverlay, 0.6);

    // Add a glowing vignette based on the spiral strength
    finalRGB += psychedelicOverlay * (spiral * 0.2);

    color = vec4(finalRGB, tex.a);
}