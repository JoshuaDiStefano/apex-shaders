#version 120

#include "/lib/positionVars.glsl"

#define WAVING_CAMERA

void main() {
    #include "/lib/shakingCamera.glsl"
}