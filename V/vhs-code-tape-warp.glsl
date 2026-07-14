#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash11(float p) {
    return fract(sin(p * 91.3458) * 47453.5453);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 20.0);
    float broadWarp = sin(uv.y * 13.0 + time_f * 1.7) * 0.006;
    broadWarp += sin(uv.y * 47.0 - time_f * 3.1) * 0.0025;

    float creaseCenter = fract(time_f * 0.09 + 0.2);
    float creaseDistance = abs(uv.y - creaseCenter);
    float crease = exp(-creaseDistance * 95.0);
    float creaseDirection = hash11(frame) * 2.0 - 1.0;
    uv.x += broadWarp + crease * creaseDirection * 0.055;
    uv.y += sin(uv.x * 31.0 + time_f) * crease * 0.006;
    uv = clamp(uv, 0.002, 0.998);

    float separation = 0.0015 + crease * 0.004;
    vec3 image;
    image.r = texture(samp, uv + vec2(separation, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(separation, 0.0)).b;

    float scan = sin(uv.y * max(iResolution.y, 1.0) * 3.14159265);
    float wrinkleShade = 1.0 - crease * (0.18 + 0.12 * scan);
    image *= wrinkleShade * (0.96 + scan * 0.035);
    image += (hash11(gl_FragCoord.x + frame * 19.0 + gl_FragCoord.y) - 0.5) * 0.03;

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
