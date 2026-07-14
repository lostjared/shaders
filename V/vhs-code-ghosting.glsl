#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 25.0);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    uv.x += sin(uv.y * 120.0 + time_f * 2.0) * 0.0018;
    uv.x += (hash21(vec2(line, frame)) - 0.5) * 0.0015;
    uv = clamp(uv, 0.0, 1.0);

    vec3 source = texture(samp, uv).rgb;
    vec3 ghostA = texture(samp, clamp(uv - vec2(0.008, 0.0), 0.0, 1.0)).rgb;
    vec3 ghostB = texture(samp, clamp(uv - vec2(0.018, 0.0), 0.0, 1.0)).rgb;
    vec3 ghostC = texture(samp, clamp(uv - vec2(0.032, 0.0), 0.0, 1.0)).rgb;
    vec3 image = source * 0.78 + ghostA * 0.13 + ghostB * 0.06 + ghostC * 0.03;

    image.r = mix(image.r, texture(samp, clamp(uv + vec2(0.003, 0.0), 0.0, 1.0)).r, 0.5);
    image.b = mix(image.b, texture(samp, clamp(uv - vec2(0.004, 0.0), 0.0, 1.0)).b, 0.5);

    float grain = hash21(gl_FragCoord.xy + frame * 23.0) - 0.5;
    float scan = sin(uv.y * iResolution.y * 3.14159265);
    image += grain * 0.025;
    image *= 0.95 + scan * 0.045;
    image = mix(vec3(dot(image, vec3(0.299, 0.587, 0.114))), image, 0.88);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
