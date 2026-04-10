#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i]^isource[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i]%255;
        icolor[i] = float(int_color[i])/255;
    }
    icolor.a = 1.0;
    return icolor;
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec4 blur(sampler2D image, vec2 uv, vec2 resolution) {
    vec2 texelSize = 1.0 / resolution;
    vec4 result = vec4(0.0);
    float kernel[100];
    float kernelVals[100] = float[](0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5,
                                    1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
                                    1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
                                    2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
                                    2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
                                    2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
                                    2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
                                    1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
                                    1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
                                    0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5);
    for (int i = 0; i < 100; i++) kernel[i] = kernelVals[i];
    float kernelSum = 842.0;
    for (int x = -5; x <= 4; ++x) {
        for (int y = -5; y <= 4; ++y) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(image, uv + offset) * kernel[(y + 5) * 10 + (x + 5)];
        }
    }
    return result / kernelSum;
}

void main(void) {
    vec2 m = (iMouse.z > 0.5 ? iMouse.xy : 0.5 * iResolution) / iResolution;
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    float d = length((tc - m) * ar);
    float focus = 1.0 - smoothstep(0.15, 0.45, d);
    vec4 base = texture(samp, tc);
    vec4 tcolor = blur(samp, tc, iResolution);
    float time_t = pingPong(time_f, 10.0) + 2.0;
    vec4 fx = xor_RGB(tcolor, tcolor * time_t);
    color = mix(base, fx, focus);
}
