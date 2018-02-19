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
varying   vec3          worldSpacePosition;
varying   vec3          toCameraInTangentSpace;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isWater;
varying   float         isTransparent;
varying   float         isNPortal;

vec3 getWorldSpacePosition() {
    return mat3(gbufferModelViewInverse) * transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
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

    worldSpacePosition = getWorldSpacePosition();

    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);

    // PARALLAX
        // transform to world space
        vec4 worldPosition = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
        vec3 worldNormal = normal;
        vec3 worldTangent = normalize(gl_NormalMatrix * at_tangent.xyz);

        // calculate vectors to the camera
        vec3 worldDirectionToCamera	= normalize(cameraPosition - worldPosition.xyz);

        // calculate bitangent from normal and tangent
        vec3 worldBitangnent = cross(worldNormal, worldTangent) * at_tangent.w;

        // transform direction to the camera to tangent space
        toCameraInTangentSpace = vec3(
                dot(worldDirectionToCamera, worldTangent),
                dot(worldDirectionToCamera, worldBitangnent),
                dot(worldDirectionToCamera, worldNormal)
            );
}
