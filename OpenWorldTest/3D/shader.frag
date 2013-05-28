uniform sampler2D colorTexture;
uniform sampler2D depthTexture;
varying vec2 TexCoord;

uniform vec2 LensCenter;
uniform vec2 ScreenCenter;
uniform vec2 ScaleIn;
uniform vec2 Scale;
uniform vec4 HmdWarpParam;

vec2 HmdWarp(vec2 p)
{
    vec2 theta  = (p - LensCenter) * ScaleIn; // Scales to [-1, 1]
    float  rSq    = theta.x * theta.x + theta.y * theta.y;
    vec2 rvector= theta * (HmdWarpParam.x + HmdWarpParam.y * rSq +
                           HmdWarpParam.z * rSq * rSq +
                           HmdWarpParam.w * rSq * rSq * rSq);
    return LensCenter + Scale * rvector;
}

void main (void)
{
    vec2 p = TexCoord;
    vec2 tc = HmdWarp(TexCoord);
    if (any(greaterThan(tc, vec2(1))) || any(lessThan(tc, vec2(0))))
    {
        discard;
    }
    gl_FragColor = texture2D(colorTexture, tc);
}