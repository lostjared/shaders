#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

mat3 rotX(float a) {
    float s = sin(a), c = cos(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}
mat3 rotY(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}
mat3 rotZ(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

vec3 compositeEffect(vec2 uv) {
    float offset = 0.01;
    vec3 col;
    col.r = texture(samp, uv + vec2(offset, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(offset, 0.0)).b;
    float noise = fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
    col += noise * 0.05;
    float scanline = sin(uv.y * iResolution.y * 1.5) * 0.1;
    col -= scanline;
    float bleed = sin(uv.y * iResolution.y * 0.2 + time_f * 5.0) * 0.005;
    col.r += bleed * 0.002;
    col.b -= bleed * 0.002;
    return col;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p = (tc - m) * ar;
    vec3 q = vec3(p, 1.0);
    float ax = 0.25 * sin(time_f * 0.7);
    float ay = 0.25 * cos(time_f * 0.6);
    float az = 0.15 * sin(time_f * 0.9);
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    q = R * q;

    float persp = 0.7;
    float zf = 1.0 / (1.0 + q.z * persp);
    vec2 uv = (q.xy * zf) / ar + m;
    uv = clamp(uv, 0.0, 1.0);

    vec3 col = compositeEffect(uv);
    color = vec4(col, 1.0);
}
