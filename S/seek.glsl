#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

void main(void) {
    vec2 uv = tc;
    vec2 mouse = iMouse.xy / iResolution.xy;
    float mouseDown = step(0.5, iMouse.z);

    // Base wave distortion (original intensity)
    vec2 wave = vec2(
        sin(uv.y * 10.0 + time_f * 3.0) * 0.03,
        cos(uv.x * 8.0 + time_f * 2.5) * 0.02);

    // Mouse interaction
    vec2 toMouse = uv - mouse;
    float mouseDist = length(toMouse);
    vec2 mouseOffset = toMouse * sin(mouseDist * 20.0 - time_f * 4.0) * 0.1 * mouseDown;

    // Radial twist effect (original strength)
    float angle = sin(time_f * 2.0 + mouseDist * 10.0) * 0.4 * mouseDown;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 twistedUV = mix(uv, rot * (uv - mouse) + mouse, mouseDown);

    uv = twistedUV + wave + mouseOffset;

    // Subtle chromatic aberration
    float chromaIntensity = 0.003;
    vec4 texR = texture(samp, uv + vec2(chromaIntensity, -chromaIntensity));
    vec4 texG = texture(samp, uv);
    vec4 texB = texture(samp, uv - vec2(chromaIntensity, -chromaIntensity));

    // Brightness-preserving ripple
    float ripple = 0.0;
    if (mouseDown > 0.5) {
        float dist = distance(uv, mouse);
        ripple = sin(dist * 30.0 - time_f * 10.0) * 0.08 * smoothstep(0.3, 0.0, dist);
    }

    // Combine colors with additive ripple instead of multiplicative
    color = vec4(texR.r, texG.g, texB.b, 1.0) + abs(ripple);

    // Very subtle vignette (mostly removed)
    vec2 vigUV = uv * (1.0 - uv.xy);
    float vignette = pow(vigUV.x * vigUV.y * 5.0, 0.7);
    color *= mix(1.0, vignette, 0.2); // Only 20% vignette effect

    // Gentle brightness pulse
    color *= 0.95 + 0.05 * sin(time_f * 2.0);

    // Maintain original color range
    color = clamp(color, 0.8, 1.2);
}