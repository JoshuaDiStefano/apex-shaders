#version 120

#include "/lib/positionVars.glsl"

#define WAVING_CAMERA

#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, mat[2].z)

#define transMAD(mat, v) (     mat3(mat) * (v) + (mat)[3].xyz)
#define  projMAD(mat, v) (diagonal3(mat) * (v) + (mat)[3].xyz)

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform   vec3          cameraPosition;

uniform   mat4          gbufferProjection;

varying   vec3          tintColor;
varying   vec3          normal;
varying   vec3          headPosition;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isWater;
varying   float         isTransparent;
varying   float         isNPortal;

vec3 getHeadPosition() {
    vec3 temp = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
    temp.y -= 1.62;
    return temp;
}

void main() {
    if (mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
        isWater = 1.0;
    } else {
        isWater = 0.0;
    }

    isTransparent = float(mc_Entity.x == 160.0 ||
                          mc_Entity.x == 95.0  ||
                          mc_Entity.x == 79.0  ||
                          mc_Entity.x == 174.0 ||
                          mc_Entity.x == 8.0   ||
                          mc_Entity.x == 9.0   ||
                          mc_Entity.x == 90.0  ||
                          mc_Entity.x == 165.0
                          );

    isNPortal = float(mc_Entity.x == 90.0);

    #include "/lib/shakingCamera.glsl"

    headPosition = getHeadPosition();

    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
