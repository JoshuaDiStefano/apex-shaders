#version 120

#include "/lib/positionVars.glsl"

#define WAVING_CAMERA

varying   vec4          color;


void main() {
	#include "/lib/shakingCamera.glsl"

    color = gl_Color;
}