/**
 * HDR
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Not actual HDR - It just tries to mimic an HDR look (relatively high performance cost)
 */

#include "ReShadeUI.fxh"

uniform float HDRPower < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "强度";
> = 1.30;
uniform float radius1 < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "半径 1";
> = 0.793;
uniform float radius2 < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "半径 2";
	ui_tooltip = "提高这一比例似乎会使效果更强，也更明显。";
> = 0.87;

#include "ReShade.fxh"

float3 HDRPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 bloom_sum1 = tex2D(ReShade::BackBuffer, texcoord + float2(1.5, -1.5) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * radius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * radius1 * BUFFER_PIXEL_SIZE).rgb;

	bloom_sum1 *= 0.005;

	float3 bloom_sum2 = tex2D(ReShade::BackBuffer, texcoord + float2(1.5, -1.5) * radius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * radius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * radius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * radius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * radius2 * BUFFER_PIXEL_SIZE).rgb;	
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * radius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * radius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * radius2 * BUFFER_PIXEL_SIZE).rgb;

	bloom_sum2 *= 0.010;

	float dist = radius2 - radius1;
	float3 HDR = (color + (bloom_sum2 - bloom_sum1)) * dist;
	float3 blend = HDR + color;
	color = pow(abs(blend), abs(HDRPower)) + HDR; // pow - don't use fractions for HDRpower
	
	return saturate(color);
}

technique HDR
< 
	ui_label = "伪HDR(伪高动态光照渲染)";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = HDRPass;
	}
}
