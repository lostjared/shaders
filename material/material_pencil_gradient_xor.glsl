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
uniform sampler2D mat_samp;

uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
uniform vec2 iResolution;
uniform float restore_black;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    color = texture(samp, tc);
    vec4 color21;
    color21 = texture(mat_samp, tc);
    ivec3 source;
    for(int i = 0; i < 3; ++i) {
        source[i] = int(255 * color[i]);
    }
    if(color21[0] < 0.7 && color21[1] < 0.7 && color21[2] < 0.7) {
        
        vec2 uv = tc;
        uv[0] = uv[0] / alpha_r;
        uv[1] = uv[1] / alpha_g;
        uv[0] = tc[0]/uv[0];
        uv[1] = tc[1]/uv[1];
        
        vec4 color2 = texture(samp, uv);
        
        color[0] = (color[0] * color2[0]) / uv[0];
        color[1] = (color[1] * color2[1]) / uv[1];
        color[2] = (color[0] * color2[0]) / (uv[0]+uv[1]);

        ivec3 int_color;
        for(int i = 0; i < 3; ++i) {
            int_color[i] = int(255 * color[i]);
            int_color[i] = int_color[i]^source[i];
            if(int_color[i] > 255)
                int_color[i] = int_color[i]%255;
            color[i] = float(int_color[i])/255;
        }

    } else {
        
    }
}

