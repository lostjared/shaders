#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
in float timeval;
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

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898, 78.233))) *
                 43758.5453123);
}

void main(void) {
    color = texture(samp, tc);
    vec2 pos = gl_FragCoord.xy / iResolution_.xy * timeval;

    float value1 = max(color[0], color[2]);
    float value2 = max(color[1], color[2]);

    vec4 val = vec4(value1, value2, color[2], 1);

    color += 0.01;

    color[0] = sin(color[0]) * sin(val[0] / 3 * timeval);
    color[1] = sin(color[1]) * sin(val[1] / 3 * timeval);
    color[2] = sin(color[2]) * sin(fract(color[2] / 3 * timeval));

    color = color * 2.0;
}
