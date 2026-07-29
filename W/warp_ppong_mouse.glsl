#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

float pingPong(float x, float length){
    float m = mod(x, length*2.0);
    return m <= length ? m : length*2.0 - m;
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect){
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect){
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

vec2 fractalZoom(vec2 uv, float zoom, float t, vec2 c, float aspect){
    vec2 p = uv;
    for(int i=0;i<5;i++){
        p = abs((p - c) * zoom) - 0.5 + c;
        p = rotateUV(p, t*0.1, c, aspect);
    }
    return p;
}

void main(){
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 uv = tc;
    vec4 originalTexture = texture(samp, tc);

    vec2 kaleidoUV = reflectUV(uv, 6.0, m, aspect);
    float zoom = 1.5 + 0.5 * sin(time_f * 0.5);
    kaleidoUV = fractalZoom(kaleidoUV, zoom, time_f, m, aspect);
    kaleidoUV = rotateUV(kaleidoUV, time_f * 0.2, m, aspect);

    vec2 p = (kaleidoUV - m) * ar;
    float base = 1.72;
    float period = log(base);
    float tz = time_f * 0.5;
    float r = length(p) + 1e-6;
    float ang = atan(p.y, p.x) + tz * 0.3;
    float k = fract((log(r) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;
    vec2 zoomUV = fract(pwrap / ar + m);

    vec4 kaleidoColor = texture(samp, zoomUV);
    float blendFactor = 0.6;
    vec4 blendedColor = mix(kaleidoColor, originalTexture, blendFactor);

    blendedColor.rgb *= 0.5 + 0.5 * sin(zoomUV.xyx + time_f);

    color = sin(blendedColor * pingPong(time_f, 8.0));
    vec4 t = texture(samp, tc);
    color = sin(color * pingPong(time_f, 8.0)) * t * 0.8;
    vec4 color2 =  tan(color * pingPong(time_f, 8.0));
    color = ((0.5 * color2) + (0.5 * color));
    if(color[0] < 0.1 && color[1] < 0.1 && color[2] < 0.1)
        color = texture(samp, tc);
    color.a = 1.0;
}
