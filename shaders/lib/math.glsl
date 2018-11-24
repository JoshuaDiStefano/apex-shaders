const     float         pi                        = 3.14159265359;

#define HASHSCALE1 0.1031
#define HASHSCALE3 vec3(0.1031, 0.1030, 0.0973)
#define HASHSCALE4 vec4(0.1031, 0.1030, 0.0973, 0.1099)

vec3 hash33(vec3 p3) {  //                        Hash functions from https://www.shadertoy.com/view/4djSRW
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz + 19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float hash11(float p) {
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
