#version 120

#include "/lib/positionVars.glsl"

#define WAVING_CAMERA

varying   vec4          texcoord;

void main() {
    #include "/lib/shakingCamera.glsl"

    texcoord = gl_MultiTexCoord0;
}