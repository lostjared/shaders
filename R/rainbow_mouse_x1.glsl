#version 330
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec2 iMouse;

vec3 rainbow(float t){
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(){
    vec2 mouse = (iMouse.x + iMouse.y > 0.0) ? (iMouse / iResolution) : vec2(0.5);
    vec2 ar = vec2(1.0, iResolution.y / iResolution.x);
    vec2 p = (tc - mouse) * ar;
    float angle = atan(p.y, p.x) + time_f * 8.0;
    float r = length(p);
    vec3 rc = rainbow(angle / (2.0 * 3.14159265359));
    vec4 tex = texture(samp, tc);
    float falloff = smoothstep(0.5, 0.0, r);
    vec3 outc = mix(tex.rgb, rc, falloff);
    color = vec4(outc, tex.a);
}
