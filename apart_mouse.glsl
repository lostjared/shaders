#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

mat3 rotX(float a){float s=sin(a),c=cos(a);return mat3(1,0,0, 0,c,-s, 0,s,c);}
mat3 rotY(float a){float s=sin(a),c=cos(a);return mat3(c,0,s, 0,1,0,-s,0,c);}
mat3 rotZ(float a){float s=sin(a),c=cos(a);return mat3(c,-s,0, s,c,0, 0,0,1);}

vec2 pseudoRandomDirection(float t){
    vec2 v = vec2(sin(t * 1.3), cos(t * 1.7));
    return normalize(v);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

   
    float zoom = mix(0.1, 1.4, 0.5 + 0.5 * sin(time_f * 0.6));
    vec2 p = (tc - m) * ar / zoom;
    float ax = 0.3 * sin(time_f * 0.7);
    float ay = 0.25 * cos(time_f * 0.6);
    float az = 0.4 * time_f;
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);

    vec3 q = R * vec3(p, 1.0);
    float zf = 1.0 / (1.0 + q.z * 0.8);
    vec2 pr = q.xy * zf;

    float dist = length(pr);
    float ang = atan(pr.y, pr.x) + time_f * 2.0;
    float radius = dist * (1.0 + 0.1 * sin(time_f * 3.0 + dist * 10.0));
    vec2 dir = pseudoRandomDirection(time_f + dist * 5.0);

    vec2 spiral = vec2(cos(ang), sin(ang)) * radius * 0.5 + dir * 0.1 * sin(time_f * 2.0);
    vec2 uv = spiral / ar + m;
    uv = clamp(uv, 0.0, 1.0);

    color = texture(samp, uv);
}
