#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 24.0);
    float scanY = uv.y * max(iResolution.y, 1.0);

    float rollCenter = fract(time_f * 0.13);
    float rollDistance = abs(fract(uv.y - rollCenter + 0.5) - 0.5);
    float rollBand = 1.0 - smoothstep(0.015, 0.09, rollDistance);
    float lineNoise = hash21(vec2(floor(scanY), frame));
    float wobble = sin(scanY * 0.11 + time_f * 7.0) * 0.0015;

    uv.x += wobble + rollBand * (lineNoise - 0.5) * 0.085;
    uv.y = fract(uv.y + (hash21(vec2(frame, 8.0)) - 0.5) * 0.004);
    uv = clamp(uv, 0.001, 0.999);

    vec3 image;
    image.r = texture(samp, uv + vec2(0.0025, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(0.0035, 0.0)).b;

    float snow = hash21(vec2(gl_FragCoord.xy) + frame * 17.0) - 0.5;
    image += snow * (0.035 + rollBand * 0.18);
    image *= 0.94 + 0.06 * sin(scanY * 3.14159265);
    image *= 1.0 - rollBand * 0.22;

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
