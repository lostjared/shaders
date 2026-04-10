#version 330 core

in vec2 tc;               // Passed-in texture coordinates
out vec4 color;           // Final pixel color

uniform float time_f;     // Current time (seconds)
uniform sampler2D samp;   // Texture sampler
uniform vec2 iResolution; // Resolution (width, height)
uniform vec4 iMouse;      // Mouse data (not used in this example, but available)
uniform float amp;        // Amplitude for swirl
uniform float uamp;       // Additional amplitude or "speed" factor

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    // -------------------------------------------------------------
    // 1. Prepare UV coordinates and center them.
    // -------------------------------------------------------------
    // We’ll treat the center of the screen (0.5,0.5 in texture coords)
    // as the swirl origin.
    vec2 center = vec2(0.5, 0.5);

    // Shift texture coordinate so that (0.5, 0.5) is at origin
    vec2 uv = tc - center;

    // -------------------------------------------------------------
    // 2. Compute swirl angle.
    // -------------------------------------------------------------
    // length(uv) - distance from center
    // "amp" and "uamp" let you adjust swirl amount & swirl speed
    float swirlAngle = (time_f/amp) * length(uv) + time_f * uamp;
    float amp_t = pingPong(amp, 8.0) + 1.0;
    swirlAngle = sin(swirlAngle * amp_t);

    // Compute rotation via sin/cos
    float s = sin(swirlAngle);
    float c = cos(swirlAngle);
    mat2 rotation = mat2(c, -s,
                         s,  c);

    // Rotate around the origin
    uv = rotation * uv;

    // Move back so that the center is (0.5, 0.5)
    uv += center;

    // -------------------------------------------------------------
    // 3. Sample the base texture using the distorted UV.
    // -------------------------------------------------------------
    vec4 baseColor = texture(samp, uv);

    // -------------------------------------------------------------
    // 4. Create a psychedelic rainbow overlay.
    // -------------------------------------------------------------
    // This uses cosine waves with different phase shifts for R/G/B.
    // The factor "10.0" controls how many color bands appear;
    // increasing it intensifies the rainbow “frequency.”
    vec3 rainbow = 0.5 + 0.5 * cos( (uv.xyx + time_f) * 10.0 
                                   + vec3(0.0, 2.0, 4.0) );

    // -------------------------------------------------------------
    // 5. Blend the base texture with the rainbow for a psychedelic effect.
    // -------------------------------------------------------------
    // 0.5 here is the blend factor—feel free to adjust!
    vec3 finalColor = mix(baseColor.rgb, rainbow, 0.3);

    // Output the final color
    color = vec4(finalColor, 1.0);
}
