#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    float spiralSpeed = 2.0;
    float inwardSpeed = 0.5;
    float drainRadius = 8.0;
    float loopDuration = 20.0;
    float currentTime = mod(time_f, loopDuration);
    float progress = clamp(currentTime / loopDuration * inwardSpeed, 0.0, 1.0);

    vec2 normCoord = (tc - m) * ar;
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);

    angle += (1.0 - smoothstep(0.0, drainRadius, dist)) * currentTime * spiralSpeed;
    dist *= mix(1.0, 0.0, progress);

    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * dist;
    vec2 uv = spiralCoord / ar + m;

    color = texture(samp, uv);
}
