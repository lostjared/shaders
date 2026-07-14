#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 24.0);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float block = floor(uv.x * 28.0);
    float segmentNoise = hash21(vec2(block + frame * 0.17, line));
    float damagedLine = step(0.965, hash21(vec2(line, floor(frame * 0.5))));
    float dropout = damagedLine * step(0.42, segmentNoise);

    float lineShift = (hash21(vec2(line, frame)) - 0.5) * damagedLine * 0.075;
    uv.x += lineShift + sin(uv.y * 190.0 + time_f * 2.7) * 0.0012;
    uv = clamp(uv, 0.001, 0.999);

    vec3 image = texture(samp, uv).rgb;
    vec3 separated;
    separated.r = texture(samp, uv + vec2(0.0025, 0.0)).r;
    separated.g = image.g;
    separated.b = texture(samp, uv - vec2(0.003, 0.0)).b;
    image = mix(image, separated, 0.65);

    float grain = hash21(gl_FragCoord.xy + frame * 13.0) - 0.5;
    vec3 dropoutColor = vec3(0.62 + grain * 0.7);
    image = mix(image, dropoutColor, dropout * 0.78);
    image += grain * 0.035;
    image *= 0.96 + 0.04 * sin(line * 3.14159265);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
