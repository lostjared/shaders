#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
uniform float alpha;
uniform vec4 optx;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
uniform vec2 iResolution;

uniform float restore_black;
in vec2 iResolution_;
uniform vec4 inc_valuex;
uniform vec4 inc_value;
uniform sampler2D mat_samp;

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898, 78.233))) *
                 43758.5453123);
}

void main(void) {
    color = texture(samp, tc);
    vec4 txt = texture(mat_samp, tc);
    vec2 pos = gl_FragCoord.xy / iResolution_.xy * (inc_valuex.xy * 0.5);
    float r = random(pos);
    color = color * sin(fract(vec4(pos * 2, 0, 1))) * txt * 6.0;
}
