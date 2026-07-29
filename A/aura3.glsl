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

void main(void){
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float radius = mix(0.8, 1.2, 0.5 + 0.5 * sin(time_f * 1.3));
    radius *= 2.0;

    float r = length(uv);
    float glow = smoothstep(radius, radius - 0.25, r);

    vec4 base = texture(samp, tc);

    vec3 pink = vec3(1.0, 0.2, 0.6);
    float pulse = 0.5 + 0.5 * sin(time_f * 3.0);
    vec3 aura = pink * glow * pulse * 1.5;

    vec3 blended = mix(base.rgb, aura + base.rgb * 0.6, glow);
    color = vec4(blended, base.a);
}
