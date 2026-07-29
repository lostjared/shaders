#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
			vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);
    float angle1 = atan(uv.y - 0.5, uv.x - 0.5);
    float modulatedTime1 = pingPong(time_f, 3.0);
    angle1 += modulatedTime1;

    float angle2 = atan(uv.x - 0.5, uv.y - 0.5);
    float modulatedTime2 = pingPong(time_f * 0.5, 2.5);
    angle2 += modulatedTime2;

    float angle3 = atan(uv.y - 0.5 + modulatedTime2, uv.x - 0.5 + modulatedTime1);
    float modulatedTime3 = pingPong(time_f * 1.5, 4.0);
    angle3 += modulatedTime3;

    vec2 rotatedTC;
    rotatedTC.x = cos(angle3) * (uv.x - 0.5) - sin(angle3) * (uv.y - 0.5) + 0.5;
    rotatedTC.y = sin(angle3) * (uv.x - 0.5) + cos(angle3) * (uv.y - 0.5) + 0.5;
    
    rotatedTC = sin(rotatedTC * (modulatedTime1 * modulatedTime2 * modulatedTime3));

    color = texture(samp, rotatedTC);
}
