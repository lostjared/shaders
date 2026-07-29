#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float pingPong(float x, float length){
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec4 blur(sampler2D image, vec2 uv, vec2 resolution){
    vec2 texelSize = 1.0 / resolution;
    vec4 result = vec4(0.0);
    float kernel[100];
    float kernelVals[100] = float[](
        0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5,
        1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
        1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
        2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
        2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
        2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
        2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
        1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
        1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
        0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5
    );
    for(int i=0;i<100;i++) kernel[i]=kernelVals[i];

    float kernelSum = 0.0;
    for(int i=0;i<100;i++) kernelSum += kernel[i];

    for(int x=-5;x<=4;++x){
        for(int y=-5;y<=4;++y){
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(image, uv + offset) * kernel[(y+5)*10 + (x+5)];
        }
    }
    return result / kernelSum;
}

void main(void){
    float time_t = pingPong(time_f, 10.0) + 2.0;

    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = vec2(0.5);

    vec2 p = (tc - m) * ar;

    float eps = 1e-6;
    float base = 1.65;
    float period = log(base);
    float t = time_f * 0.5;

    float r = length(p) + eps;
    float theta = atan(p.y, p.x) + t * 0.25 * 6.28318530718;

    float k = fract((log(r) - t) / period);
    float rw = exp(k * period);

    vec2 wrapped = vec2(cos(theta), sin(theta)) * rw;

    vec2 uv = wrapped / ar + m;
    uv = fract(uv);

    float glitchStrength = 0.001;
    vec2 uvGlitch = uv;
    uvGlitch.x += (rand(uv + time_f) - 0.5) * glitchStrength;
    uvGlitch.y += (rand(uv + time_f * 1.5) - 0.5) * glitchStrength;

    vec4 texColor = blur(samp, uvGlitch, iResolution);

    vec4 colorShift = vec4(texColor.r,
                           texColor.g * 0.5 + 0.5,
                           texColor.b * 0.5 + 0.5,
                           texColor.a);

    colorShift = sin(colorShift * time_t);

    float glitchNoise = rand(uv + time_f);
    vec4 glitchColor = vec4(vec3(glitchNoise), 1.0) * glitchStrength;

    color = mix(colorShift, glitchColor, glitchStrength * glitchNoise);
    color = sin(color * time_t);
    color.a = 1.0;
}
