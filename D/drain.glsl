#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
void main(void) {
    vec2 normCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);
    float spiralSpeed = 2.0;
    float inwardSpeed = 0.5;
    float drainRadius = 8.0;

    float loopDuration = 20.0;
    float currentTime = mod(time_f, loopDuration);

    angle += (1.0 - smoothstep(0.0, drainRadius, dist)) * currentTime * spiralSpeed;
    dist *= mix(1.0, 0.0, currentTime * inwardSpeed);
    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * dist;
    spiralCoord = (spiralCoord / vec2(iResolution.x / iResolution.y, 1.0) + 1.0) / 2.0;
    color = texture(samp, spiralCoord);
}
