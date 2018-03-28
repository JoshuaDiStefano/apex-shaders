const     float         pi                        = 3.14159265359;

#define HASHSCALE3 vec3(0.1031, 0.1030, 0.0973)

vec3 hash33(vec3 p3) {  //                        From https://www.shadertoy.com/view/4djSRW
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz + 19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}
