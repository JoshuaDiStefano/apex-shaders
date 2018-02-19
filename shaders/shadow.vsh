#version 120

#define WAVING_CAMERA

attribute vec4 mc_Entity;

uniform float frameTimeCounter;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;

uniform   int           entityID;
uniform   int           blockEntityID;

varying   vec4          texcoord;
varying   vec4          color;

varying   float         isPlayer;
varying   float         isBeacon;
varying   float         isFire;
varying   float         isTransparent;

//varying   float         beID;

float getIsTransparent(in float materialId) {
    if (materialId == 160.0) {  // stained glass panes
      return 1.0;
    }
    if (materialId == 95.0) {   // stained glass blocks
      return 1.0;
    }
    if (materialId == 79.0 || materialId == 174.0) {   // ice
      return 1.0;
    }
    if (materialId == 8.0 || materialId == 9.0) {   // water
      return 1.0;
    }
    if (materialId == 90.0) {   // portal
      return 1.0;
    }
    if (materialId == 165.0) {   // slime block
      return 1.0;
    }
    if (entityID == 55) {   //slime
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

    gl_Position = ftransform();

    vec4 position = gl_Position;
    position = shadowProjectionInverse * position;
    position = shadowModelViewInverse * position;

    #ifdef WAVING_CAMERA
        position.xy += vec2(0.01 * sin(frameTimeCounter * 2.0), 0.01 * cos(frameTimeCounter * 3.0));
    #endif

    position = shadowModelView * position;
	  position = shadowProjection * position;

    gl_Position = position;

    float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	  float distortFactor = (1.0f - 0.85) + dist * 0.85;

    gl_Position.xy *= 1.0f / distortFactor;

    texcoord = gl_MultiTexCoord0;
}