vec4 gaussian(in sampler2D source, in vec2 resolution, in vec2 direction, in vec2 coord, in float radius) {
    vec4 sum = vec4(0.0);

    float blurVertical = radius/resolution.y;
    float blurHorizontal = radius/resolution.x;

    //(1.0, 0.0) -> x-axis blur
	//(0.0, 1.0) -> y-axis blur

    float hStep = direction.x;
    float vStep = direction.y;

	int lod = 1;

    sum += texture2DLod(source, vec2(coord.x - 4.0 * blurHorizontal * hStep, coord.y - 4.0 * blurVertical * vStep), lod) * 0.0162162162;
	sum += texture2DLod(source, vec2(coord.x - 3.0 * blurHorizontal * hStep, coord.y - 3.0 * blurVertical * vStep), lod) * 0.0540540541;
	sum += texture2DLod(source, vec2(coord.x - 2.0 * blurHorizontal * hStep, coord.y - 2.0 * blurVertical * vStep), lod) * 0.1216216216;
	sum += texture2DLod(source, vec2(coord.x - 1.0 * blurHorizontal * hStep, coord.y - 1.0 * blurVertical * vStep), lod) * 0.1945945946;
	
	sum += texture2DLod(source, vec2(coord.x, coord.y), lod) * 0.2270270270;
	
	sum += texture2DLod(source, vec2(coord.x + 1.0 * blurHorizontal * hStep, coord.y + 1.0 * blurVertical * vStep), lod) * 0.1945945946;
	sum += texture2DLod(source, vec2(coord.x + 2.0 * blurHorizontal * hStep, coord.y + 2.0 * blurVertical * vStep), lod) * 0.1216216216;
	sum += texture2DLod(source, vec2(coord.x + 3.0 * blurHorizontal * hStep, coord.y + 3.0 * blurVertical * vStep), lod) * 0.0540540541;
	sum += texture2DLod(source, vec2(coord.x + 4.0 * blurHorizontal * hStep, coord.y + 4.0 * blurVertical * vStep), lod) * 0.0162162162;

	return vec4(sum.rgb, 1.0);
}
