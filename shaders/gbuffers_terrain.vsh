#version 120

#include "/lib/positionVars.glsl"

#define WAVING_CAMERA

attribute vec4 mc_Entity;

uniform   sampler2D     normals;

varying   vec3          tintColor;
varying   vec3          normalOut;
varying   vec3          pos;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isEmissive;
varying   float         isFire;
varying   float         isLava;

void main() {
    #include "/lib/shakingCamera.glsl"

    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    normalOut = normalize(gl_NormalMatrix * gl_Normal);

    float id = mc_Entity.x;

    isEmissive = float(id == 6.0 ||
                        id == 18.0 ||
                        id == 30.0 ||
                        id == 31.0 ||
                        id == 32.0 ||
                        id == 37.0 ||
                        id == 38.0 ||
                        id == 39.0 ||
                        id == 40.0 ||
                        id == 55.0 ||
                        id == 59.0 ||
                        id == 83.0 ||
                        id == 104.0 ||
                        id == 105.0 ||
                        id == 106.0 ||
                        id == 132.0 ||
                        id == 141.0 ||
                        id == 142.0 ||
                        id == 161.0 ||
                        id == 175.0
                        );

    isFire = float(mc_Entity.x == 51.0);
    isLava = float(mc_Entity.x == 10.0 || mc_Entity.x == 11.0);
}