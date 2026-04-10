#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(void) {
    vec2 ar = vec2(1.0, iResolution.y / iResolution.x);
    vec2 iar = vec2(1.0, iResolution.x / iResolution.y);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 p = (tc - m) * ar;
    float r = length(p);
    float r0 = 0.35;
    float k = 2.5 + 1.5 * sin(time_f * 0.5);
    float t = k * (r0 - r);
    float c = cos(t), s = sin(t);
    vec2 pr = mat2(c, -s, s, c) * p;
    vec2 tcoord = m + pr * iar;

    vec2 uv = tcoord * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float wave = sin(uv.x * 10.0 + time_f * 2.0) * 0.1;
    float angle = atan(uv.y + wave, uv.x) + time_f * 2.0;

    vec3 rainbow_color = rainbow(angle / (2.0 * 3.14159));
    vec4 original_color = texture(samp, tcoord);
    vec3 blended_color = mix(original_color.rgb, rainbow_color, 0.5);

    color = vec4(sin(blended_color * time_f), original_color.a);
}
