#version 330
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

void main(void) {
    float yPos = 1.0 - (gl_FragCoord.y / iResolution.y);
    
    // Mouse-based control: use normalized mouse Y to influence wave amplitude
    float mouseY = (iMouse.z > 0.5) ? (iMouse.y / iResolution.y) : 0.5;
    float waveAmplitude = mix(0.05, 0.35, mouseY);
    
    float wavePhase = sin(yPos * 10.0 + time_f * 2.0 + mouseY * 6.2831);
    
    vec2 tcAdjusted = tc + vec2(0.0, wavePhase * waveAmplitude);
    color = texture(samp, tcAdjusted);
}
