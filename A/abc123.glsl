#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float uamp;
uniform float amp;
uniform vec4 iMouse;

void main(void) {
    vec2 mousePos = iMouse.xy / iResolution.xy; 
    float dist = distance(tc, mousePos);
    float glitchStrength = exp(-dist * 10.0) * (uamp) * 4.0;
    vec2 glitchOffset = vec2(
        sin(time_f * 10.0 + tc.y * 20.0) * glitchStrength,
        cos(time_f * 15.0 + tc.x * 25.0) * glitchStrength
    );

    vec2 distortedTc = tc + glitchOffset;
    color = texture(samp, distortedTc);
    vec4 originalColor = texture(samp, tc);
    float blendFactor = smoothstep(0.0, 0.1, glitchStrength);
    color = mix(originalColor, color, blendFactor);
    color = vec4(sin(color.rgb * time_f), 1.0);
}
