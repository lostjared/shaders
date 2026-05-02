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
    float mouseDown = step(0.5, iMouse.z); // 1 when mouse pressed

    // Base wave distortion
    vec2 wave = vec2(
        sin(uv.y * 10.0 + time_f * 3.0) * 0.03,
        cos(uv.x * 8.0 + time_f * 2.5) * 0.02);

    wave = (wave * (time_f * 0.25));

    // Mouse interaction distortion
    vec2 toMouse = uv - mouse;
    float mouseDist = length(toMouse);
    vec2 mouseOffset = toMouse * mouseDist * 20.0 - time_f * 4.0 * 0.1 * mouseDown;

    // Radial twist effect around mouse
    float angle = sin(time_f * 2.0 + mouseDist * 10.0) * 0.4 * mouseDown;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 twistedUV = mix(uv, rot * (uv - mouse) + mouse, mouseDown);

    // Combine distortions
    uv = cos(twistedUV * (0.1 * time_f)) + wave + mouseOffset;

    // Chromatic aberration
    float chromaIntensity = 0.005 + sin(time_f) * 0.003;
    vec4 texR = texture(samp, uv + vec2(chromaIntensity, -chromaIntensity));
    vec4 texG = texture(samp, uv + vec2(-chromaIntensity, 0.0));
    vec4 texB = texture(samp, uv + vec2(0.0, chromaIntensity));

    // Ripple effect when mouse is pressed
    float ripple = 0.0;
    if (mouseDown > 0.5) {
        float dist = distance(uv, mouse);
        ripple = sin(dist * 30.0 - time_f * 10.0) * 0.1 * smoothstep(0.3, 0.0, dist);
    }

    // Combine color channels with ripple
    color = vec4(texR.r, texG.g, texB.b, 1.0) * (1.0 - ripple);
    // color = vec4(sin(color.rgb * time_f), 1.0);
    //  Vignette effect
    vec2 vigUV = uv * (1.0 - uv.xy);
    float vignette = vigUV.x * vigUV.y * 15.0;
    vignette = pow(vignette, 0.3);
    // color *= vignette;

    // Color pulse based on time
    //    color *= 0.9 + 0.3 * sin(time_f * 2.0);
}