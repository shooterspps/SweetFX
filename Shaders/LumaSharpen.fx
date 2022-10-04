/**
   LumaSharpen version 1.5.0
   by Christian Cann Schuldt Jensen ~ CeeJay.dk
  
   It blurs the original pixel with the surrounding pixels and then subtracts this blur to sharpen the image.
   It does this in luma to avoid color artifacts and allows limiting the maximum sharpning to avoid or lessen halo artifacts.
   This is similar to using Unsharp Mask in Photoshop.

   Version 1.5.1
  - UI improvements for Reshade 3.x
 */

#include "ReShadeUI.fxh"

uniform float sharp_strength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 3.0;
	ui_label = "锐化强度";
	ui_tooltip = "锐化的强度";

> = 0.65;
uniform float sharp_clamp < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.005;
	ui_label = "锐化极限";
	ui_tooltip = "限制像素接收到的最大锐化量\n这有助于避免当强度提高太多时出现的“光晕”现象。";
> = 0.035;
uniform int pattern <
	ui_type = "combo";
	ui_items =	"快" "\0"
				"正常" "\0"
				"广泛"	"\0"
				"金字塔状" "\0";
	ui_label = "样本模式";
	ui_tooltip = "选择一个样本模式。\n"
	"快是更快，但质量稍低。\n"
	"正常是正常的。\n"
	"广泛对噪音不太敏感,但是也讲究细节。\n"
	"金字塔的外观略显奇怪。";
> = 1;
uniform float offset_bias < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 6.0;
	ui_label = "偏移偏差";
	ui_tooltip = "偏移偏差调整采样模式的半径。我为1.0的偏移量设计了这个模式，但是可以自由地进行试验。";
> = 1.0;
uniform bool show_sharpen <
	ui_label = "显示锐化模式";
	ui_tooltip = "可视化锐化的强度\n这对于查看锐化对哪些区域影响最大很有用";
> = false;

#include "ReShade.fxh"

   /*-----------------------------------------------------------.
  /                      Developer settings                     /
  '-----------------------------------------------------------*/
#define CoefLuma float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
//#define CoefLuma float3(0.299, 0.587, 0.114)       // BT.601 luma coefficient (SD Television)
//#define CoefLuma float3(1.0/3.0, 1.0/3.0, 1.0/3.0) // Equal weight coefficient

   /*-----------------------------------------------------------.
  /                          Main code                          /
  '-----------------------------------------------------------*/

float3 LumaSharpenPass(float4 position : SV_Position, float2 tex : TEXCOORD) : SV_Target
{
	// -- Get the original pixel --
	float3 ori = tex2D(ReShade::BackBuffer, tex).rgb; // ori = original pixel

	// -- Combining the strength and luma multipliers --
	float3 sharp_strength_luma = (CoefLuma * sharp_strength); //I'll be combining even more multipliers with it later on

	/*-----------------------------------------------------------.
	/                       Sampling patterns                     /
	'-----------------------------------------------------------*/
	float3 blur_ori;

	//   [ NW,   , NE ] Each texture lookup (except ori)
	//   [   ,ori,    ] samples 4 pixels
	//   [ SW,   , SE ]

	// -- Pattern 1 -- A (fast) 7 tap gaussian using only 2+1 texture fetches.
	if (pattern == 0)
	{
		// -- Gaussian filter --
		//   [ 1/9, 2/9,    ]     [ 1 , 2 ,   ]
		//   [ 2/9, 8/9, 2/9]  =  [ 2 , 8 , 2 ]
		//   [    , 2/9, 1/9]     [   , 2 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + (BUFFER_PIXEL_SIZE / 3.0) * offset_bias).rgb;  // North West
		blur_ori += tex2D(ReShade::BackBuffer, tex + (-BUFFER_PIXEL_SIZE / 3.0) * offset_bias).rgb; // South East

		//blur_ori += tex2D(ReShade::BackBuffer, tex + (BUFFER_PIXEL_SIZE / 3.0) * offset_bias); // North East
		//blur_ori += tex2D(ReShade::BackBuffer, tex + (-BUFFER_PIXEL_SIZE / 3.0) * offset_bias); // South West

		blur_ori /= 2;  //Divide by the number of texture fetches

		sharp_strength_luma *= 1.5; // Adjust strength to aproximate the strength of pattern 2
	}

	// -- Pattern 2 -- A 9 tap gaussian using 4+1 texture fetches.
	if (pattern == 1)
	{
		// -- Gaussian filter --
		//   [ .25, .50, .25]     [ 1 , 2 , 1 ]
		//   [ .50,   1, .50]  =  [ 2 , 4 , 2 ]
		//   [ .25, .50, .25]     [ 1 , 2 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) * 0.5 * offset_bias).rgb; // South East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * 0.5 * offset_bias).rgb;  // South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * 0.5 * offset_bias).rgb; // North East
		blur_ori += tex2D(ReShade::BackBuffer, tex - float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) * 0.5 * offset_bias).rgb; // North West

		blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches
	}

	// -- Pattern 3 -- An experimental 17 tap gaussian using 4+1 texture fetches.
	if (pattern == 2)
	{
		// -- Gaussian filter --
		//   [   , 4 , 6 ,   ,   ]
		//   [   ,16 ,24 ,16 , 4 ]
		//   [ 6 ,24 ,   ,24 , 6 ]
		//   [ 4 ,16 ,24 ,16 ,   ]
		//   [   ,   , 6 , 4 ,   ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * float2(0.4, -1.2) * offset_bias).rgb;  // South South East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * float2(1.2, 0.4) * offset_bias).rgb; // West South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * float2(1.2, 0.4) * offset_bias).rgb; // East North East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * float2(0.4, -1.2) * offset_bias).rgb; // North North West

		blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches

		sharp_strength_luma *= 0.51;
	}

	// -- Pattern 4 -- A 9 tap high pass (pyramid filter) using 4+1 texture fetches.
	if (pattern == 3)
	{
		// -- Gaussian filter --
		//   [ .50, .50, .50]     [ 1 , 1 , 1 ]
		//   [ .50,    , .50]  =  [ 1 ,   , 1 ]
		//   [ .50, .50, .50]     [ 1 , 1 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + float2(0.5 * BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y * offset_bias)).rgb;  // South South East
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(offset_bias * -BUFFER_PIXEL_SIZE.x, 0.5 * -BUFFER_PIXEL_SIZE.y)).rgb; // West South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(offset_bias * BUFFER_PIXEL_SIZE.x, 0.5 * BUFFER_PIXEL_SIZE.y)).rgb; // East North East
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(0.5 * -BUFFER_PIXEL_SIZE.x, BUFFER_PIXEL_SIZE.y * offset_bias)).rgb; // North North West

		//blur_ori += (2 * ori); // Probably not needed. Only serves to lessen the effect.

		blur_ori /= 4.0;  //Divide by the number of texture fetches

		sharp_strength_luma *= 0.666; // Adjust strength to aproximate the strength of pattern 2
	}

	 /*-----------------------------------------------------------.
	/                            Sharpen                          /
	'-----------------------------------------------------------*/

	// -- Calculate the sharpening --
	float3 sharp = ori - blur_ori;  //Subtracting the blurred image from the original image

#if 0 //older 1.4 code (included here because the new code while faster can be difficult to understand)
	// -- Adjust strength of the sharpening --
	float sharp_luma = dot(sharp, sharp_strength_luma); //Calculate the luma and adjust the strength

	// -- Clamping the maximum amount of sharpening to prevent halo artifacts --
	sharp_luma = clamp(sharp_luma, -sharp_clamp, sharp_clamp);  //TODO Try a curve function instead of a clamp

#else //new code
	// -- Adjust strength of the sharpening and clamp it--
	float4 sharp_strength_luma_clamp = float4(sharp_strength_luma * (0.5 / sharp_clamp),0.5); //Roll part of the clamp into the dot

	//sharp_luma = saturate((0.5 / sharp_clamp) * sharp_luma + 0.5); //scale up and clamp
	float sharp_luma = saturate(dot(float4(sharp,1.0), sharp_strength_luma_clamp)); //Calculate the luma, adjust the strength, scale up and clamp
	sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp; //scale down
#endif

	// -- Combining the values to get the final sharpened pixel	--
	float3 outputcolor = ori + sharp_luma;    // Add the sharpening to the the original.

	 /*-----------------------------------------------------------.
	/                     Returning the output                    /
	'-----------------------------------------------------------*/

	if (show_sharpen)
	{
		//outputcolor = abs(sharp * 4.0);
		outputcolor = saturate(0.5 + (sharp_luma * 4.0)).rrr;
	}

	return saturate(outputcolor);
}

technique LumaSharpen
< 
	ui_label = "亮度锐化";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LumaSharpenPass;
	}
}
