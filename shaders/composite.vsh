#version 120

uniform   vec3          shadowLightPosition;

uniform   float         sunAngle;

varying   vec4          texcoord;

varying   vec3          lightVector;
varying   vec3          lightColor;
varying   vec3          skyColor;

varying   float         isNight;

void main() {
    gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);

    texcoord = gl_MultiTexCoord0;

    lightVector = normalize(shadowLightPosition);

    if (sunAngle <= 0.5) {
        lightColor = vec3(vec2(1.0), 0.5) * 15.0;
        skyColor = vec3(0.15, 0.15, 0.2) /  25.0;
        isNight = 0.0;
    } else {
        lightColor = vec3(vec2(0.025), 0.075);
        skyColor = vec3(0.15, 0.15, 0.5) / 100.0;
        isNight = 1.0;
    }
}
