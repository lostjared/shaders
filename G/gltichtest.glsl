#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

void main(void) {
    // Flip texture coordinates upside down
    vec2 uv = vec2(tc.x, 1.0 - tc.y);

    // Center coordinates and calculate polar form
    vec2 centeredUV = uv - 0.5;
    float radius = length(centeredUV);
    float angle = atan(centeredUV.y, centeredUV.x);

    // Tornado spiral effect with time
    float spiralStrength = 10.0;
    float spiralFactor = radius * spiralStrength + time_f * 2.0;
    angle += spiralFactor;

    // Create vertical tornado stretching
    float verticalStretch = radius * 0.5;
    radius = pow(radius, 0.9);

    // Convert back to Cartesian coordinates
    vec2 distorted = vec2(cos(angle), sin(angle)) * radius;
    distorted.y -= verticalStretch;

    // Tear drop effect (stronger at top)
    float tearShape = pow(uv.y, 2.0);
    distorted.y -= tearShape * 0.3;

    // Ice cube refraction effect
    float iceRefract = sin(distorted.x * 50.0 + time_f * 4.0) * 0.01;
    iceRefract += cos(distorted.y * 40.0 + time_f * 3.0) * 0.01;
    distorted += iceRefract * tearShape;

    // Final UV adjustment
    distorted += 0.5;

    // RGB channel separation
    float colorSplit = 0.02;
    vec4 r = texture(samp, distorted + vec2(-colorSplit, 0.0));
    vec4 g = texture(samp, distorted);
    vec4 b = texture(samp, distorted + vec2(colorSplit, 0.0));

    // Combine channels with fading edges
    float edgeFade = 1.0 - smoothstep(0.4, 0.5, radius);
    color = vec4(r.r, g.g, b.b, 1.0);
}