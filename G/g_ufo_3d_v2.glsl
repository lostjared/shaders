#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
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

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p2 = (tc - m) * ar;
    float ax = 0.25 * sin(time_f * 0.7 + tc.x * 10.0); // Rotate around X-axis with ping pong effect and direction based on texture coordinate x
    float ay = 0.25 * cos(time_f * 0.6 - tc.y * 10.0); // Rotate around Y-axis with ping pong effect and direction based on texture coordinate y
    float az = time_f * 0.5;                           // Rotate around Z-axis over time

    vec3 p3 = vec3(p2, 1.0);
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    vec3 r = R * p3;

    float k = 0.6;
    float zf = 1.0 / (1.0 + r.z * k);
    vec2 q = r.xy * zf;

    // Ping pong effect for scaling factor
    float dist = length(p2);
    float scale_factor = 0.2 * sin(dist * 15.0 - time_f * 2.0 + tc.x * 5.0 + tc.y * 5.0); // Add texture coordinate contributions for more complex ping pong effects
    q *= (1.0 + scale_factor);

    vec2 uv = q / ar + m;
    uv = clamp(uv, 0.0, 1.0);
    color = texture(samp, uv);
}
