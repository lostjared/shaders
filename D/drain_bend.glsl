#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

void main(void) {
    float loopDuration = 25.0;
    float currentTime = mod(time_f, loopDuration);
    vec2 aspect = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 normCoord = (tc * 2.0 - 1.0) * aspect;
    normCoord.x = abs(normCoord.x);
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);
    float spiralSpeed = 5.0;
    float inwardSpeed = currentTime / loopDuration;
    angle += (1.0 - smoothstep(0.0, 8.0, dist)) * currentTime * spiralSpeed;
    dist *= 1.0 - inwardSpeed;
    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * tan(dist);
    spiralCoord = (spiralCoord / aspect + 1.0) * 0.5;

    vec2 uv = spiralCoord;
    vec2 c = uv - 0.5;
    float r = length(c);
    float t = time_f;
    float k1 = 0.25 * sin(t * 0.6);
    float k2 = 0.10 * cos(t * 0.4);
    float rd = 1.0 + k1 * r * r + k2 * r * r * r * r;
    c *= rd;
    c.x += 0.015 * sin(8.0 * c.y + t * 1.3);
    c.y += 0.015 * sin(8.0 * c.x - t * 1.1);
    uv = clamp(c + 0.5, 0.0, 1.0);

    color = texture(samp, uv);
}
