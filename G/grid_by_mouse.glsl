#version 330
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;

float sstep(float a, float b, float x){x=clamp((x-a)/(b-a),0.0,1.0);return x*x*(3.0-2.0*x);}

void main(void) {
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec4 texColor = texture(samp, tc);
    float sparkle = abs(sin(time_f * 10.0 + tc.x * 100.0) * cos(time_f * 15.0 + tc.y * 100.0));
    vec2 d = tc - m;
    float dist = length(d);
    float r = mix(0.08, 0.35, clamp(amp,0.0,1.0));
    float fall = 1.0 - sstep(0.0, r, dist);
    float pulse = 0.5 + 0.5 * sin(time_f * 6.0 + dist * 40.0);
    float mask = fall * pulse;
    vec3 magicalColor = vec3(sin(time_f * 2.0) * 0.5 + 0.5, cos(time_f * 3.0) * 0.5 + 0.5, sin(time_f * 4.0) * 0.5 + 0.5);
    vec3 glow = magicalColor * sparkle * mask;
    color = vec4(texColor.rgb + glow, texColor.a);
}
