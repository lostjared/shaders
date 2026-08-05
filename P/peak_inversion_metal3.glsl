#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform float amp_peak;
uniform float amp_high;

void main(void) {
    vec4 source = texture(samp, tc);
    float luma = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    vec3 steel = mix(vec3(luma), source.rgb, 0.28);
    steel = smoothstep(vec3(0.08), vec3(0.92), steel);
    float sheen = 0.82 + 0.28 * sin((tc.x + tc.y) * 38.0 - time_f * 2.0);
    steel *= vec3(0.78, 0.9, 1.08) * sheen;
    float peak = clamp(max(amp_peak, amp_high * 0.75), 0.0, 1.0);
    float invert = smoothstep(0.58, 0.92, peak);
    vec3 result = mix(steel, vec3(1.0) - steel, invert);
    color = vec4(clamp(result, 0.0, 1.0), source.a);
}
