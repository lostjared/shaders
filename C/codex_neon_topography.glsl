#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main(void) {
    float t = time_f * 0.8;
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec3 src = texture(samp, tc).rgb;
    float mouseEdge = smoothstep(1.0, 0.0, distance(tc, mouseUV));
    float l = luminance(src);
    float gx = luminance(texture(samp, tc + vec2(px.x, 0.0)).rgb) - luminance(texture(samp, tc - vec2(px.x, 0.0)).rgb);
    float gy = luminance(texture(samp, tc + vec2(0.0, px.y)).rgb) - luminance(texture(samp, tc - vec2(0.0, px.y)).rgb);
    float edge = smoothstep(0.04, 0.28, length(vec2(gx, gy)));
    float bands = smoothstep(0.88, 1.0, sin((l + tc.y * 0.7) * 55.0 - t * 3.0) * 0.5 + 0.5);
    vec3 neon = 0.55 + 0.45 * cos(vec3(0.0, 2.2, 4.4) + l * 8.0 + t);
    vec3 c = src * 0.42 + neon * (bands * 0.55 + edge * 0.85);
    c += mouseEdge * vec3(0.1, 0.04, 0.14);
    color = vec4(c, 1.0);
}
