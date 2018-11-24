#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"

const     int           noiseTextureResolution    = 512;

uniform   sampler2D     gdepthtex;
uniform   sampler2D     noisetex;
uniform   sampler2D     colortex0;
uniform   sampler2D     colortex7;

uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferModelViewInverse;
uniform   mat4          gbufferModelView;

uniform   vec3          sunPosition;

uniform   float         rainStrength;
uniform   float         sunAngle;
uniform   float         viewWidth;
uniform   float         viewHeight;

uniform   int           worldTime;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   vec3          lightVector;
varying   vec3          tintColor;
varying   vec3          normal;
varying   vec3          sunPosNorm;

varying   float         isNight;

vec4 getDepth(in vec2 coord) {
  return texture2D(gdepthtex, coord);
}

vec4 getWorldSpacePositionSky(in vec2 coord) {
    vec4 tmp = gbufferProjectionInverse * vec4(coord * 2.0 - 1.0, 1.0, 1.0);
    vec3 viewPos = tmp.xyz / tmp.w;
    vec4 positionCameraSpace = vec4(viewPos, 1.0);
    vec4 positionWorldSpace = gbufferModelViewInverse * vec4(positionCameraSpace);

    return positionWorldSpace;
}

vec4 getCameraSpacePositionSky(in vec2 coord) {
    float depth = getDepth(coord).r;
    vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
    vec4 positionCameraSpace = normalize(gbufferProjectionInverse * positionNdcSpace);
  
    return positionCameraSpace / positionCameraSpace.w;
}

#include "/lib/sky.glsl"

/* DRAWBUFFERS:645 */

void main() {
    vec3 upPosNorm = gbufferModelView[1].xyz;

    vec2 coord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

    float fac;
    vec3 world = normalize(getWorldSpacePositionSky(coord).xyz);

    if (sunAngle > 0.5 && sunAngle <= 0.75) {
        fac = smoothstep(0.5, 0.55, sunAngle);
    } else if (sunAngle > 0.75) {
        fac = 1.0 - smoothstep(0.95, 1.0, sunAngle);
    } else {
        fac = 0.0;
    }

    vec3 skyCol = getSky(coord, fac, world, upPosNorm, lightVector);
    vec3 sunCol = getSun(coord, fac, sunPosNorm);
    vec3 moonCol = getMoon(coord, fac, sunPosNorm);

    FragData0 = vec4(skyCol, 1.0);
    FragData1 = vec4(0.0);
    FragData3 = vec4(0.0, 1.0, 0.0, 1.0);
}
