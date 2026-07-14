#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 30.0);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float lineDrift = (hash21(vec2(line, frame)) - 0.5) * 0.002;
    float weave = sin(uv.y * 210.0 + time_f * 3.5) * 0.0015;
    uv.x += lineDrift + weave;

    vec2 chromaOffset = vec2(0.005 + 0.002 * sin(time_f * 0.7), 0.0);
    vec3 center = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    vec3 left = texture(samp, clamp(uv - chromaOffset, 0.0, 1.0)).rgb;
    vec3 right = texture(samp, clamp(uv + chromaOffset, 0.0, 1.0)).rgb;

    float luma = dot(center, vec3(0.299, 0.587, 0.114));
    float redChroma = right.r - dot(right, vec3(0.299, 0.587, 0.114));
    float blueChroma = left.b - dot(left, vec3(0.299, 0.587, 0.114));
    vec3 image = vec3(luma + redChroma, luma - 0.35 * redChroma - 0.25 * blueChroma,
                      luma + blueChroma);

    vec3 echoColor = texture(samp, clamp(uv - vec2(0.012, 0.0), 0.0, 1.0)).rgb;
    image = mix(image, echoColor, 0.08);
    float noise = hash21(gl_FragCoord.xy + frame * 9.0) - 0.5;
    image += noise * 0.025;
    image *= 0.96 + 0.04 * sin(uv.y * iResolution.y * 3.14159265);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
