#version 330
in vec2 tc; 
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
void main(void)
{

		 vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);     
    vec2 normCoord = ((tc.xy / iResolution.xy) * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);

    float distanceFromCenter = length(normCoord);
    float wave = sin(distanceFromCenter * 12.0 - time_f * 4.0);

    vec2 tcAdjusted = uv + (normCoord * 0.301 * wave);

    vec4 textureColor = texture(samp, tcAdjusted);
    color = textureColor;
}
