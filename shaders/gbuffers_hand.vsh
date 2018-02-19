#version 120

#include "/lib/positionVars.glsl"

#define WAVING_HAND

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

void main() {
    #ifdef WAVING_HAND
        vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        position.xy += vec2(0.01 * sin(frameTimeCounter), 0.01 * cos(frameTimeCounter * 2.0));

        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    #else
        #include "/lib/shakingCamera.glsl"
    #endif

    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
