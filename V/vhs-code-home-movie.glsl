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
    float frame = floor(time_f * 29.97);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float handheld = sin(time_f * 2.3) * 0.0015 + sin(time_f * 5.7) * 0.0008;
    uv.x += handheld + sin(uv.y * 145.0 + time_f * 2.2) * 0.0012;
    uv.y += (hash21(vec2(frame, 6.0)) - 0.5) * 0.0025;
    uv = clamp(uv, 0.002, 0.998);

    vec3 image;
    image.r = texture(samp, uv + vec2(0.0022, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(0.0032, 0.0)).b;

    float luma = dot(image, vec3(0.299, 0.587, 0.114));
    image = mix(vec3(luma), image, 0.82);
    image *= vec3(1.08, 0.99, 0.84);
    image = (image - 0.5) * 0.92 + 0.54;

    float grain = hash21(gl_FragCoord.xy + frame * 11.0) - 0.5;
    float scan = sin(line * 3.14159265);
    float vignette = 1.0 - smoothstep(0.25, 0.78, length((tc - 0.5) * vec2(1.15, 1.0)));
    float exposureFlicker = 0.96 + 0.04 * hash21(vec2(floor(frame * 0.5), 3.0));
    image = image * exposureFlicker + grain * 0.035;
    image *= 0.96 + scan * 0.025;
    image *= mix(0.76, 1.0, vignette);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
