/**
 * FilmGrain version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Computes a noise pattern and blends it with the image to create a film grain look.
 */

#include "ReShadeUI.fxh"

uniform float Intensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "强度";
	ui_tooltip = "可见纹理。越高越明显。";
> = 0.50;
uniform float Variance < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "方差";
	ui_tooltip = "控制高斯噪声的方差。较低的值看起来更平滑";
> = 0.40;
uniform float Mean < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "平均";
	ui_tooltip = "影响噪音的亮度。";
> = 0.5;

uniform int SignalToNoiseRatio < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 16;
	ui_label = "信噪比";
	ui_tooltip = "较高的信噪比值给更亮的像素更少的纹理。0禁用此特性。";
> = 6;

uniform float Timer < source = "timer"; >;

#include "ReShade.fxh"

float3 FilmGrainPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
  
	//float inv_luma = dot(color, float3(-0.2126, -0.7152, -0.0722)) + 1.0;
	float inv_luma = dot(color, float3(-1.0/3.0, -1.0/3.0, -1.0/3.0)) + 1.0; //Calculate the inverted luma so it can be used later to control the variance of the grain
  
	/*---------------------.
	| :: Generate Grain :: |
	'---------------------*/

	const float PI = 3.1415927;
	
	//time counter using requested counter from ReShade
	float t = Timer * 0.0022337;
	
	//PRNG 2D - create two uniform noise values and save one DP2ADD
	float seed = dot(texcoord, float2(12.9898, 78.233));// + t;
	float sine = sin(seed);
	float cosine = cos(seed);
	float uniform_noise1 = frac(sine * 43758.5453 + t); //I just salt with t because I can
	float uniform_noise2 = frac(cosine * 53758.5453 - t); // and it doesn't cost any extra ASM

	//Get settings
	float stn = SignalToNoiseRatio != 0 ? pow(abs(inv_luma), (float)SignalToNoiseRatio) : 1.0; // Signal to noise feature - Brighter pixels get less noise.
	float variance = (Variance*Variance) * stn;
	float mean = Mean;

	//Box-Muller transform
	uniform_noise1 = (uniform_noise1 < 0.0001) ? 0.0001 : uniform_noise1; //fix log(0)
		
	float r = sqrt(-log(uniform_noise1));
	r = (uniform_noise1 < 0.0001) ? PI : r; //fix log(0) - PI happened to be the right answer for uniform_noise == ~ 0.0000517.. Close enough and we can reuse a constant.
	float theta = (2.0 * PI) * uniform_noise2;
	
	float gauss_noise1 = variance * r * cos(theta) + mean;
	//float gauss_noise2 = variance * r * sin(theta) + mean; //we can get two gaussians out of it :)

	//gauss_noise1 = (ddx(gauss_noise1) - ddy(gauss_noise1)) * 0.50  + gauss_noise2;
  

	//Calculate how big the shift should be
	//float grain = lerp(1.0 - Intensity,  1.0 + Intensity, gauss_noise1);
	float grain = lerp(1.0 + Intensity,  1.0 - Intensity, gauss_noise1);
  
	//float grain2 = (2.0 * Intensity) * gauss_noise1 + (1.0 - Intensity);
	 
	//Apply grain
	color = color * grain;
  
	//color = (grain-1.0) *2.0 + 0.5;
  
	//color = lerp(color,colorInput.rgb,sqrt(luma));

	/*-------------------------.
	| :: Debugging features :: |
	'-------------------------*/

	//color.rgb = frac(gauss_noise1).xxx; //show the noise
	//color.rgb = (gauss_noise1 > 0.999) ? float3(1.0,1.0,0.0) : 0.0 ; //does it reach 1.0?
	
	return color.rgb;
}

technique FilmGrain
< 
	ui_label = "胶片颗粒1";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmGrainPass;
	}
}
