#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/positionVars.glsl"

#define WAVING_CAMERA
#define SUN_POSITION_FIX

uniform   vec3          shadowLightPosition;

uniform   float         sunAngle;

uniform   int           worldTime;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   vec3          lightVector;
varying   vec3          tintColor;
varying   vec3          normal;

varying   float         isNight;

#ifdef SUN_POSITION_FIX
    varying vec3 sunPosNorm;
#endif

#ifdef SUN_POSITION_FIX
    const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994)); //Used for manually calculating the sun's position, since the sunPosition uniform is inaccurate in the skybasic stage.
#endif

void main() {
    #include "/lib/shakingCamera.glsl"

    float isStar = float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0);

    if (isStar > 0.9) {
        gl_Position.xyz = vec3(100.0);
    }

    #ifdef SUN_POSITION_FIX
        //minecraft's native calculateCelestialAngle() function, ported to GLSL.
        float ang = fract(worldTime / 24000.0 - 0.25);
        ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959; //0-2pi, rolls over from 2pi to 0 at noon.

        sunPosNorm = normalize((gbufferModelView * vec4(sin(ang) * -100.0, (cos(ang) * 100.0) * sunRotationData, 1.0)).xyz);
    #endif


    if (sunAngle <= 0.5) {
        isNight = 0.0;
        lightVector = normalize(sunPosNorm);
    } else {
        isNight = 1.0;
        lightVector = normalize(-sunPosNorm);
    }

    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
