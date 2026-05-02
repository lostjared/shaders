#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Convert an HSV color to RGB.
vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0),
                             6.0) -
                         3.0) -
                         1.0,
                     0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main(void) {
    // Start with the texture coordinate.
    vec2 uv = tc;

    // Center the coordinate system around (0,0)
    uv = uv * 2.0 - 1.0;

    // Convert to polar coordinates.
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);

    // Compute a swirl offset that changes with both the radius and time.
    // Adjust the multiplier (10.0) and time factor (3.0) to tune the effect.
    float swirl = sin(radius * 10.0 - time_f * 3.0) * 0.5;

    // Optionally, modulate swirl strength with the mouse's x position.
    float mouseFactor = (iMouse.x > 0.0) ? (iMouse.x / iResolution.x) : 1.0;
    swirl *= mouseFactor;

    // Add the swirl offset to the polar angle.
    angle += swirl;

    // Convert back to Cartesian coordinates.
    uv = vec2(cos(angle), sin(angle)) * radius;

    // Transform back to standard texture coordinate space [0,1].
    uv = (uv + 1.0) * 0.5;

    // Sample the texture using the distorted coordinates.
    vec4 texColor = texture(samp, uv);

    // Create a dynamic hue based on the radius and time.
    // This produces a hue that continuously cycles for a vivid color effect.
    float hue = fract(time_f * 0.1 + radius);
    vec3 hsv = vec3(hue, 1.0, 1.0);
    vec3 psychedelicColor = hsv2rgb(hsv);

    // Mix the original texture color with the psychedelic color.
    // The mix factor (0.7) can be adjusted for more or less color dominance.
    vec3 finalColor = mix(texColor.rgb, psychedelicColor, 0.7);

    color = vec4(finalColor, texColor.a);
}
