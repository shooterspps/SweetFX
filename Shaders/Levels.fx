/**
 * Levels version 1.2
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Allows you to set a new black and a white level.
 * This increases contrast, but clips any colors outside the new range to either black or white
 * and so some details in the shadows or highlights can be lost.
 *
 * The shader is very useful for expanding the 16-235 TV range to 0-255 PC range.
 * You might need it if you're playing a game meant to display on a TV with an emulator that does not do this.
 * But it's also a quick and easy way to uniformly increase the contrast of an image.
 *
 * -- Version 1.0 --
 * First release
 * -- Version 1.1 --
 * Optimized to only use 1 instruction (down from 2 - a 100% performance increase :) )
 * -- Version 1.2 --
 * Added the ability to highlight clipping regions of the image with #define HighlightClipping 1
 */

#include "ReShadeUI.fxh"

uniform int BlackPoint < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 255;
	ui_label = "黑色的点";
	ui_tooltip = "黑点是新的黑点——毫不夸张地说。任何比这更黑的东西都会变成完全的黑色。";
> = 16;

uniform int WhitePoint < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 255;
	ui_label = "白色的点";
	ui_tooltip = "新的白点。所有比这更亮的东西都变成了白色";
> = 235;

uniform bool HighlightClipping <
	ui_label = "突出显示裁剪像素";
	ui_tooltip = "两个点之间的颜色将被拉伸，这将增加对比度，但点上面和下面的细节将丢失(这称为剪切)。\n"
		"此设置将标记该剪辑的像素。\n"
		"红色:亮点中有些细节丢失了\n"
		"黄色: 所有的细节都在亮点中消失了\n"
		"蓝色: 一些细节在阴影中消失了\n"
		"青色: 所有的细节都消失在阴影中。";
> = false;

#include "ReShade.fxh"

float3 LevelsPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float black_point_float = BlackPoint / 255.0;
	float white_point_float = WhitePoint == BlackPoint ? (255.0 / 0.00025) : (255.0 / (WhitePoint - BlackPoint)); // Avoid division by zero if the white and black point are the same

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = color * white_point_float - (black_point_float *  white_point_float);

	if (HighlightClipping)
	{
		float3 clipped_colors;

		clipped_colors = any(color > saturate(color)) // any colors whiter than white?
			? float3(1.0, 0.0, 0.0)
			: color;
		clipped_colors = all(color > saturate(color)) // all colors whiter than white?
			? float3(1.0, 1.0, 0.0)
			: clipped_colors;
		clipped_colors = any(color < saturate(color)) // any colors blacker than black?
			? float3(0.0, 0.0, 1.0)
			: clipped_colors;
		clipped_colors = all(color < saturate(color)) // all colors blacker than black?
			? float3(0.0, 1.0, 1.0)
			: clipped_colors;

		color = clipped_colors;
	}

	return color;
}

technique Levels
<
	ui_label = "色阶调整";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LevelsPass;
	}
}
