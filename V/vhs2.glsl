#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float rand(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
float nrand(vec2 p){return rand(p)*2.0-1.0;}

vec3 lumaChroma(vec3 c){
    float y = dot(c, vec3(0.299,0.587,0.114));
    vec2 cbcr = vec2((c.b - y)*0.565, (c.r - y)*0.713);
    return vec3(y, cbcr);
}
vec3 yc2rgb(vec3 yc){
    float y=yc.x, cb=yc.y, cr=yc.z;
    float r = y + 1.403*cr;
    float g = y - 0.344*cb - 0.714*cr;
    float b = y + 1.770*cb;
    return vec3(r,g,b);
}

vec3 chromaLowpass(sampler2D s, vec2 uv, vec2 px, float k){
    vec2 o = vec2(px.x*1.5, 0.0);
    vec3 c0 = texture(s, uv - o).rgb;
    vec3 c1 = texture(s, uv).rgb;
    vec3 c2 = texture(s, uv + o).rgb;
    vec3 m = (c0 + c1 + c2)/3.0;
    vec3 yc = lumaChroma(m);
    yc.yz *= k;
    return yc2rgb(yc);
}

void main(){
    vec2 uv = tc;

    float t = time_f;
    vec2 res = iResolution;
    vec2 px = 1.0 / res;

    float weave = 0.002*(sin(t*0.97)+sin(t*1.31+uv.y*3.3));
    float lineWobble = 0.0008*sin(uv.y*120.0 + t*40.0);
    uv.x += weave + lineWobble;

    float holdTrig = step(0.995, rand(vec2(floor(t*1.7), 0.123)));
    uv.y = fract(uv.y + holdTrig * rand(vec2(t,0.37)) * 0.18);

    float tearY = 0.84 + 0.04*rand(vec2(floor(t*0.6), 4.2));
    float tearBand = smoothstep(tearY-0.015, tearY, uv.y) * (1.0 - smoothstep(tearY, tearY+0.05, uv.y));
    float tear = tearBand * (0.08*nrand(vec2(uv.y*900.0, t*150.0)) + 0.03*sin(t*200.0));
    uv.x += tear;

    vec2 jitter = vec2(0.0015*nrand(vec2(t*3.0, uv.y*7.0)), 0.0);
    uv += jitter;

    float scanRate = 800.0;
    float line = floor(uv.y * res.y);
    float field = mod(line + floor(t*60.0), 2.0);
    float scanDark = mix(0.92, 0.78, field);
    float fineScan = 0.06*sin(uv.y*scanRate + t*12.0);
    float coarse = 0.03*sin(uv.y*6.28318*3.0 + t*2.0);

    float cx = (0.003 + 0.002*rand(vec2(line, t)));
    vec3 ca;
    ca.r = texture(samp, uv + vec2(cx,0.0)).r;
    ca.g = texture(samp, uv).g;
    ca.b = texture(samp, uv - vec2(cx,0.0)).b;

    vec3 bleed = chromaLowpass(samp, uv, px, 0.65);
    vec3 base = mix(ca, bleed, 0.45);

    vec3 hl = texture(samp, uv + vec2(px.x*0.75,0.0)).rgb;
    vec3 hr = texture(samp, uv - vec2(px.x*0.75,0.0)).rgb;
    base = mix(base, (base+hl+hr)/3.0, 0.35);

    float dropout = step(0.988, rand(vec2(line*0.73, floor(t*60.0)))) * smoothstep(0.0, 0.4, rand(vec2(line, t*0.23)));
    vec3 dropCol = vec3(0.15 + 0.85*rand(vec2(line*3.1, t)));
    base = mix(base, dropCol, dropout);

    float snow = 0.12*nrand(vec2(uv*res*1.3 + t*80.0)) + 0.08*nrand(vec2(uv*res*3.7 - t*50.0));
    base += snow;

    float track = step(0.9975, rand(vec2(line*0.11 + floor(t*25.0), 9.9)));
    base += track * (0.25 + 0.25*rand(vec2(line, t)));

    float hueDrift = 0.02*sin(t*0.7) + 0.02*sin(t*1.3 + uv.y*5.0);
    base.gb += vec2(hueDrift, -hueDrift);

    float flicker = 0.94 + 0.06*rand(vec2(floor(t*12.0)));
    base *= flicker;

    float vign = smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.75, uv.y);
    float edgeX = smoothstep(0.0, 0.05, uv.x) * smoothstep(1.0, 0.95, uv.x);
    float edge = mix(vign, vign*edgeX, 0.6);
    base *= mix(0.92, 1.0, edge);

    base *= scanDark;
    base -= fineScan + coarse;

    base = clamp(base, 0.0, 1.0);
    color = vec4(pow(base, vec3(1.05)), 1.0);
}
