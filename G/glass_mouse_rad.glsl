#version 330 core
out vec4 color;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

void main(void) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 c = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    float distortionStrength = 0.25;
    float noiseFactor = sin(uv.x * 10.0 + time_f) * cos(uv.y * 10.0 + time_f);

    float radius = 0.75; 
    float w = 1.0 - smoothstep(0.0, radius, length(uv - c));

    vec2 dir = normalize(uv - c + 1e-5);
    vec2 distortedCoord = uv + distortionStrength * noiseFactor * w * dir;

    distortedCoord = clamp(distortedCoord, 0.0, 1.0);
    color = texture(samp, distortedCoord);
}
