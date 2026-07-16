#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash22(vec2 p) {
    return vec2(hash21(p), hash21(p + 23.17));
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float twist = log(radius + 0.04) * 3.1 - time_f * 0.35;
    vec2 spiralP = rotation(twist) * p * 11.0;
    vec2 cell = floor(spiralP);
    vec2 local = fract(spiralP);
    float nearest = 10.0;
    float second = 10.0;
    vec2 offset = vec2(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 grid = vec2(x, y);
            vec2 point = grid + hash22(cell + grid);
            float distanceToPoint = length(local - point);
            if (distanceToPoint < nearest) {
                second = nearest;
                nearest = distanceToPoint;
                offset = local - point;
            } else if (distanceToPoint < second) {
                second = distanceToPoint;
            }
        }
    }

    float edge = 1.0 - smoothstep(0.0, 0.10, second - nearest);
    vec2 refractOffset = normalize(offset + vec2(0.0001)) * (0.008 + nearest * 0.006);
    vec3 source = texture(samp, mirrorUV(tc + refractOffset)).rgb;
    vec3 result = source * vec3(0.91, 0.98, 1.05) + vec3(0.20, 0.31, 0.38) * edge * 0.38;
    color = vec4(result, texture(samp, tc).a);
}
