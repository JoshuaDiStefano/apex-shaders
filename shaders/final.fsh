#version 120

#define MC_GL_ARB_shader_texture_lod

//#define CINEMATIC_MODE
#define   BLOOM
#define   DOF
#define   APERTURE                                  0.015 // [0.01 0.015 0.02 0.025 0.05 0.06 0.075 0.08 0.1 0.15 0.2 0.25 0.5] Bigger values for shallower depth of field
#define   DOF_FALLOFF_STRENGTH                      2.5   // [1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]
//#define   TILT_SHIFT
#define   VIGNETTE

const     float         dofStrength               = DOF_FALLOFF_STRENGTH;
const     float         GA                        = 2.399;
const     float         blurclamp                 = 3.0;   // max blur amount
const     float         aperture                  = APERTURE;
const     float      	centerDepthHalflife       = 2.0f;  // [0.0f 0.2f 0.4f 0.6f 0.8f 1.0f 1.2f 1.4f 1.6f 1.8f 2.0f] Transition speed for focus.

const     mat2          rot                       = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;
uniform   sampler2D     gdepth;
uniform   sampler2D     depthtex1;

uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferProjectionMatrix;

uniform   float         viewHeight;
uniform   float         viewWidth;
uniform   float         centerDepthSmooth;

varying   vec4          texcoord;

void vignette(inout vec3 color) {
    float dist = distance(texcoord.st, vec2(0.5)) * 2.0;
    dist /= 1.5142f;
    dist = pow(dist, 1.1);

    color.rgb *= (1.0f - dist / 1.75);
}

vec3 convertToHDR(in vec3 color) {
    vec3 HDRImage;

    vec3 overExposed = color * 1.0f;
    vec3 underExposed = color / 1.25f;

    HDRImage = mix(underExposed, overExposed, color);

    return HDRImage;
}

vec3 getExposure(in vec3 color) {
    vec3 retColor;
    color *=  1.1;
    retColor = color;

    return retColor;
}

vec3 reinhard(in vec3 color) {
    color /= 1.0 + color;

    return pow(color, vec3(1.0 / 2.2));
}

vec3 burgess(in vec3 color) {
    vec3 maxColor = max(vec3(0.0), color - 0.004);
    vec3 retColor = (maxColor * (6.2 * maxColor + 0.05)) / (maxColor * (6.2 * maxColor + 2.7) + 0.05);

    return retColor;
}

float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 11.2;

vec3 uncharted2Math(in vec3 x) {

    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 uncharted2Tonemap(in vec3 color) {
    vec3 retColor;
    float exposureBias = 2.0;

    vec3 cur = uncharted2Math(exposureBias * color);

    vec3 whiteScale = vec3(1.0) / uncharted2Math(vec3(W));
    retColor = cur * whiteScale;

    return pow(retColor, vec3(1.0 / 2.2));
}

vec3 testTonemap(in vec3 color) {
    vec3 retColor = color;

    retColor *= retColor;
    retColor = sqrt(retColor / (retColor + 1.0));

    return pow(retColor, vec3(1.0 / 2.2));
}

void dither(inout vec3 color) {
    vec3 lestynRGB = vec3(dot(vec2(171.0, 231.0), gl_FragCoord.xy));
         lestynRGB = fract(lestynRGB.rgb / vec3(103.0, 71.0, 97.0));

    color += lestynRGB.rgb / 255.0;
}

float getDofFactor(in float sample1, in float sample2) {
    return abs(sample1 - sample2);
}

void weightSample(inout float tempSample, inout float tempFactor, inout float sampleCount, inout vec3 color, in vec2 temp, in float fragSample) {
    tempSample = min(texture2D(depthtex1, temp).r / dofStrength, 1.0);
    tempFactor = 1.0 - getDofFactor(tempSample, fragSample);
    color += texture2D(colortex0, temp).rgb * tempFactor;
    sampleCount += tempFactor;
}

void bloom(inout vec3 color, in float strength) {
    color += texture2D(colortex1, texcoord.st).rgb * strength;
}

void main() {
    #ifdef CINEMATIC_MODE
    float isBlack = float(texcoord.t <= 0.1 || texcoord.t >= 0.9);
    #else
    float isBlack = 0.0;
    #endif

    vec3 color = vec3(0.0);

    if (isBlack == 0.0) {
        color = texture2D(colortex0, texcoord.st).rgb;

        // DOF //
        #include "/lib/dof.glsl"

        color = getExposure(color);

        #ifdef VIGNETTE
            vignette(color);
        #endif

        #ifdef BLOOM
            bloom(color, texture2D(colortex2, texcoord.st).r * 0.5);
        #endif

        color = reinhard(color);
        dither(color);
    } else {
        color = vec3(0.0);
    }

    gl_FragColor = vec4(color, 1.0);
}
