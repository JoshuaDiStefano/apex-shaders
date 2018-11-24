#version 120

#include "/lib/math.glsl"

#define WAVING_CAMERA
#define GRASS_SHADOWS

attribute vec4 mc_Entity;

uniform   mat4          shadowProjectionInverse;
uniform   mat4          shadowProjection;
uniform   mat4          shadowModelViewInverse;
uniform   mat4          shadowModelView;

uniform   vec3          cameraPosition;

uniform   float         frameTimeCounter;

uniform   int           entityID;
uniform   int           blockEntityID;

varying   vec4          texcoord;
varying   vec4          color;

varying   float         isPlayer;
varying   float         isBeacon;
varying   float         isFire;
varying   float         isTransparent;

float getIsTransparent(in float materialId) {
    if (materialId == 13000.0) { // water
      return 1.0;
    }
    if (materialId == 13011.0) { // stained glass
      return 1.0;
    }
    if (materialId == 13010.0) { // other
      return 1.0;
    }
    if (entityID == 55) {        // slime
        return 1.0;
    }
    return 0.0;
}

float getIsPlayer() {
    return float(mc_Entity.x == 0.0 && entityID <= 0);
}

float getIsBeacon() {
    return float(blockEntityID == 138 && mc_Entity.x == 0.0);
}

float getIsFire() {
    return float(mc_Entity.x == 51.0 || mc_Entity.x == 10.0 || mc_Entity.x == 11.0);
}

void main() {
    color = gl_Color;
    isPlayer = getIsPlayer();
    isBeacon = getIsBeacon();
    isFire = getIsFire();

    isTransparent = getIsTransparent(mc_Entity.x);

    float displacement;

    gl_Position = ftransform();

    vec4 position = gl_Position;
    position = shadowProjectionInverse * position;
    position = shadowModelViewInverse * position;
    
    if (mc_Entity.x == 13000.0) { // water
      vec3 worldpos = position.xyz + cameraPosition;

        float fy = fract(worldpos.y + 0.001);
        
        if (fy > 0.002) {
            float wave = 0.05 * sin(2 * pi * (frameTimeCounter * 0.75 + worldpos.x /  7.0 + worldpos.z / 13.0))
                    + 0.05 * sin(2 * pi * (frameTimeCounter * 0.6 + worldpos.x / 11.0 + worldpos.z /  5.0));
            displacement = clamp(wave, -fy, 1.0 - fy);
            position.y += displacement;
        }
    }

    #ifdef WAVING_CAMERA
        position.xy += vec2(0.01 * sin(frameTimeCounter * 2.0), 0.01 * cos(frameTimeCounter * 3.0));
    #endif

    position = shadowModelView * position;
	position = shadowProjection * position;

    gl_Position = position;

    float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	  float distortFactor = (1.0f - 0.85) + dist * 0.85;

    gl_Position.xy *= 1.0f / distortFactor;

    #ifndef GRASS_SHADOWS
        if (mc_Entity.x >= 11000.0 && mc_Entity.x < 12000.0 && mc_Entity.x != 11075.0) gl_Position = vec4(100.0);
    #endif

    texcoord = gl_MultiTexCoord0;
}
