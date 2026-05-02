#version 330 core
// CGA cyan/magenta/white palette - DOS era vibe.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 p0 = vec3(0.0, 0.0, 0.0);
    vec3 p1 = vec3(0.0, 1.0, 1.0);
    vec3 p2 = vec3(1.0, 0.0, 1.0);
    vec3 p3 = vec3(1.0, 1.0, 1.0);
    vec3 q;
    if (lum < 0.25)
        q = p0;
    else if (lum < 0.5)
        q = p1;
    else if (lum < 0.75)
        q = p2;
    else
        q = p3;
    color = vec4(q, 1.0);
}
