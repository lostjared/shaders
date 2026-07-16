#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 grid = tc * vec2(5.0, 5.0);
    vec2 cell = floor(grid);
    vec2 local = fract(grid);
    if (mod(cell.x + cell.y, 2.0) > 0.5) {
        local = local.yx;
    }
    if (local.y < local.x) {
        local = local.yx;
    }
    vec2 uv = (cell + local) / vec2(5.0, 5.0);
    color = texture(samp, uv);
}
