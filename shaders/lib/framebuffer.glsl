#define MC_GL_ARB_shader_texture_lod

const     int           RGBA                      = 0;
const     int           RGBA16                    = 1;

const     vec3          clayColor                 = vec3(1.0);

//   OPTIFINE SETTINGS
/*
const     int           gdepthFormat              = RGBA32F;
const     int           gcolorFormat              = RGBA16F;
const     int           gnormalFormat             = RGBA16F;

const     bool          colortex0MipmapEnabled    = true;
const     bool          colortex1MipmapEnabled    = true;
*/

#define   FragData0    gl_FragData[0]
#define   FragData1    gl_FragData[1]
#define   FragData2    gl_FragData[2]
#define   FragData3    gl_FragData[3]
#define   FragData4    gl_FragData[4]

#define   RANDOM_ROTATION
//#define   RANDOM_ROTATION_FILTER

#define   PCF_SAMPLE_COUNT                          2      // [1 2 3 4 5]
#define   PCSS_SAMPLE_COUNT                         3      // [1 2 3 4 5]
#define   MIN_PENUMBRA_SIZE                         0.5    // [0.0 0.1 0.25 0.5]
#define   LIGHT_SIZE                                75     // [50 75 100 125 150]
#define   BLOOM_STRENGTH                            5.0    // [1.0 2.0 2.5 3.0 4.0 5.0 7.5 10.0]
#define   PCSS

//#define   CLAY
