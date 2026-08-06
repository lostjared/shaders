#version 330 core
in vec2 tc;
out vec4 color;

uniform sampler2D samp; 
uniform float time_f; 
uniform float uamp; 
uniform float time_speed;

void main(void) {
    vec2 step = 1.0 / vec2(textureSize(samp, 0));
    vec4 center = texture(samp, tc);
    vec4 up     = texture(samp, tc + vec2(0.0, step.y));
    vec4 down   = texture(samp, tc + vec2(0.0, -step.y));
    vec4 left   = texture(samp, tc + vec2(-step.x, 0.0));
    vec4 right  = texture(samp, tc + vec2(step.x, 0.0));
    vec3 sharpened = (center.rgb * 5.0) - (up.rgb + down.rgb + left.rgb + right.rgb);
    color = vec4(sharpened, center.a);    
}