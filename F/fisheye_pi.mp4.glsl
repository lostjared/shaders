#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s, 0,1,0, -s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0, s,c,0, 0,0,1);}


float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}



void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 p = (tc - m) * ar;

    float ax = 0.28 * sin(time_f * 0.7);
    float ay = 0.28 * cos(time_f * 0.6);
    float az = 0.5 * time_f;
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);

    vec3 q3 = R * vec3(p, 1.0);
    float persp = 0.7;
    float zf = 1.0 / (1.0 + q3.z * persp);
    vec2 q = q3.xy * zf;

    float d = length(q);
    float w = 1.0 - smoothstep(0.0, 0.55, length((tc - m) * ar));
    float s = 0.5 + 4.0 * sin(pingPong(time_f * PI, 15.0));
    float ang = atan(q.y, q.x);
    float radius = d * (1.0 + s * w * (d * d));
    vec2 r = vec2(cos(ang), sin(ang)) * sin(radius * time_f);
    vec2 uv = r / ar + m;
    uv = clamp(uv, 0.0, 1.0);

    color = texture(samp, uv);
}
