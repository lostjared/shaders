#version 330 core
// Psychedelic power-up: sin warp + boosted saturation + slow hue rotation.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec3 hueRotate(vec3 c, float a) {
    const mat3 toYIQ = mat3(
        0.299, 0.596, 0.211,
        0.587, -0.274, -0.523,
        0.114, -0.322, 0.312);
    const mat3 toRGB = mat3(
        1.0, 1.0, 1.0,
        0.956, -0.272, -1.106,
        0.621, -0.647, 1.703);
    vec3 yiq = toYIQ * c;
    float ca = cos(a), sa = sin(a);
    yiq.yz = mat2(ca, -sa, sa, ca) * yiq.yz;
    return toRGB * yiq;
}

void main(void) {
    vec2 uv = tc;
    uv.x += sin(uv.y * 14.0 + time_f * 1.7) * 0.012;
    uv.y += sin(uv.x * 11.0 + time_f * 1.3) * 0.012;
    vec3 c = texture(samp, uv).rgb;
    c = hueRotate(c, time_f * 0.8);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(lum), c, 1.7);
    color = vec4(clamp(c, 0.0, 1.5), 1.0);
}
