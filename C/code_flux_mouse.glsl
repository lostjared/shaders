#version 330 core
uniform float time_f;
uniform vec2 iResolution;
uniform sampler2D samp;
uniform vec4 iMouse;
in vec2 tc;
out vec4 color;

vec4 xor_RGB(vec4 icolor, vec4 source){
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255.0);
    for(int i=0;i<3;++i){
        int_color[i] = int(255.0*icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if(int_color[i]>255) int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255.0;
    }
    icolor.a = 1.0;
    return icolor;
}

float pingPong(float x,float length){
    float m = mod(x, length*2.0);
    return m <= length ? m : length*2.0 - m;
}

void main(){
    vec2 center = (iMouse.z>0.5 || iMouse.w>0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 p = (tc - center) * vec2(1.0, iResolution.y / iResolution.x);
    float intensity = pingPong(time_f, 10.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float swirl = sin(time_f*0.5)*0.5+0.5;
    angle += intensity * swirl * sin(radius*10.0 + time_f);
    vec2 q = vec2(cos(angle), sin(angle)) * radius;
    vec2 uv = q * vec2(1.0, iResolution.x / iResolution.y) + center;
    vec4 texColor = texture(samp, uv);
    float fluctuation = sin(time_f*2.0)*0.5+0.5;
    vec4 fluctuatedColor = vec4(mix(vec3(1.0,0.0,0.0), vec3(0.0,0.0,1.0), fluctuation), 1.0);
    vec4 xorResult = xor_RGB(texColor, fluctuatedColor);
    color = mix(texColor, xorResult, 0.5);
}
