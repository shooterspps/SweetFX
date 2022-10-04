/**
 * Vignette version 1.3
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Darkens the edges of the image to make it look more like it was shot with a camera lens.
 * May cause banding artifacts.
 */

#include "ReShadeUI.fxh"

uniform int Type <
	ui_type = "combo";
	ui_label = "类型";
	ui_items = "原始\0新\0电视风格\0无题 1\0无题 2\0无题 3\0无题 4\0";
> = 0;
uniform float Ratio < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.15; ui_max = 6.0;
	ui_label = "比例";
	ui_tooltip = "设置宽高比。1.00(1/1)是完美的圆形，而1.60(16/10)比它的高宽60%";
> = 1.0;
uniform float Radius < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.0; ui_max = 3.0;
	ui_label = "半径";
	ui_tooltip = "值越低=中心辐射效应越强";
> = 2.0;
uniform float Amount < __UNIFORM_SLIDER_FLOAT1
	ui_min = -2.0; ui_max = 1.0;
	ui_label = "数量";
	ui_tooltip = "黑色强度。-2.00 = 最黑, 1.00 = 最白。";
> = -1.0;
uniform int Slope < __UNIFORM_SLIDER_INT1
	ui_min = 2; ui_max = 16;
	ui_label = "斜率";
	ui_tooltip = "距离中心有多远的改变应该开始变得更强大(奇数比偶数造成更大的fps下降)。";
> = 2;
uniform float2 Center < __UNIFORM_SLIDER_FLOAT2
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "中心";
	ui_tooltip = "“原始”插图类型的效果中心。“新”和“电视风格”不服从这个设置。";
> = float2(0.5, 0.5);

#include "ReShade.fxh"

float4 VignettePass(float4 vpos : SV_Position, float2 tex : TexCoord) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, tex);

	if (Type == 0)
	{
		// Set the center
		float2 distance_xy = tex - Center;

		// Adjust the ratio
		distance_xy *= float2((BUFFER_RCP_HEIGHT / BUFFER_RCP_WIDTH), Ratio);

		// Calculate the distance
		distance_xy /= Radius;
		float distance = dot(distance_xy, distance_xy);

		// Apply the vignette
		color.rgb *= (1.0 + pow(distance, Slope * 0.5) * Amount); //pow - multiply
	}

	if (Type == 1) // New round (-x*x+x) + (-y*y+y) method.
	{
		tex = -tex * tex + tex;
		color.rgb = saturate(((BUFFER_RCP_HEIGHT / BUFFER_RCP_WIDTH)*(BUFFER_RCP_HEIGHT / BUFFER_RCP_WIDTH) * Ratio * tex.x + tex.y) * 4.0) * color.rgb;
	}

	if (Type == 2) // New (-x*x+x) * (-y*y+y) TV style method.
	{
		tex = -tex * tex + tex;
		color.rgb = saturate(tex.x * tex.y * 100.0) * color.rgb;
	}
		
	if (Type == 3)
	{
		tex = abs(tex - 0.5);
		float tc = dot(float4(-tex.x, -tex.x, tex.x, tex.y), float4(tex.y, tex.y, 1.0, 1.0)); //XOR

		tc = saturate(tc - 0.495);
		color.rgb *= (pow((1.0 - tc * 200), 4) + 0.25); //or maybe abs(tc*100-1) (-(tc*100)-1)
	}
  
	if (Type == 4)
	{
		tex = abs(tex - 0.5);
		float tc = dot(float4(-tex.x, -tex.x, tex.x, tex.y), float4(tex.y, tex.y, 1.0, 1.0)); //XOR

		tc = saturate(tc - 0.495) - 0.0002;
		color.rgb *= (pow((1.0 - tc * 200), 4) + 0.0); //or maybe abs(tc*100-1) (-(tc*100)-1)
	}

	if (Type == 5) // MAD version of 2
	{
		tex = abs(tex - 0.5);
		float tc = tex.x * (-2.0 * tex.y + 1.0) + tex.y; //XOR

		tc = saturate(tc - 0.495);
		color.rgb *= (pow((-tc * 200 + 1.0), 4) + 0.25); //or maybe abs(tc*100-1) (-(tc*100)-1)
		//color.rgb *= (pow(((tc*200.0)-1.0),4)); //or maybe abs(tc*100-1) (-(tc*100)-1)
	}

	if (Type == 6) // New round (-x*x+x) * (-y*y+y) method.
	{
		//tex.y /= float2((BUFFER_RCP_HEIGHT / BUFFER_RCP_WIDTH), Ratio);
		float tex_xy = dot(float4(tex, tex), float4(-tex, 1.0, 1.0)); //dot is actually slower
		color.rgb = saturate(tex_xy * 4.0) * color.rgb;
	}

	return color;
}

technique Vignette
<
	ui_label = "装饰图案";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = VignettePass;
	}
}
