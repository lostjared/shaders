#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length){
    float m = mod(x, length*2.0);
    return m <= length ? m : length*2.0 - m;
}

vec3 hsv2rgb(vec3 c){
    vec4 K=vec4(1.0,2.0/3.0,1.0/3.0,3.0);
    vec3 p=abs(fract(c.xxx+K.xyz)*6.0-K.www);
    return c.z*mix(K.xxx,clamp(p-K.xxx,0.0,1.0),c.y);
}

void main(void){
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    float radius = mix(0.8, 1.2, 0.5 + 0.5 * sin(time_f * 1.3));
    radius *= 2;
    float r = length(uv);
    float glow = smoothstep(radius, radius - 0.25, r) * pingPong(time_f, 5.0);
    float ang = atan(uv.y, uv.x);
    vec3 grad = hsv2rgb(vec3(fract(ang / (2.0 * PI) + time_f * 0.05), 0.8, 1.0));
    vec4 base = texture(samp, tc);
    vec3 aura = grad * glow * (0.8 + 0.2 * sin(time_f * 2.0));
    color = vec4(base.rgb + aura * (1.0 - base.rgb), base.a);
}
