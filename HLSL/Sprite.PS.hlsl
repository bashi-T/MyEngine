#include "Sprite.hlsli"

struct Material{
float32_t4 color;
int32_t enableLighting;
float32_t4x4 uvTransform;
float32_t shininess;
};
ConstantBuffer<Material> gMaterial:register(b0);

struct DirectionalLight{
  float32_t4 color;
  float32_t3 direction;
  float intensity;
};
ConstantBuffer<DirectionalLight> gDirectionalLight : register(b2);

struct Camera
{
  float32_t3 worldPosition;
};
ConstantBuffer<Camera> gCamera : register(b1);

struct PixelShaderOutput
{
  float32_t4 color : SV_TARGET0;
};
Texture2D<float32_t4> gTexture : register(t0);
SamplerState gSampler : register(s0);

PixelShaderOutput main(VertexShaderOutput input)
{
  PixelShaderOutput output;
  float4 transformedUV = mul(float32_t4(input.texcoord, 0.0f, 1.0f), gMaterial.uvTransform);
  float32_t4 textureColor = gTexture.Sample(gSampler, transformedUV.xy);
  if (gMaterial.enableLighting != 0)
  {
    float NdotL = dot(normalize(input.normal), -gDirectionalLight.direction);
    float cos = pow(NdotL * 0.5f + 0.5f, 2.0f);

    float32_t3 toEye = normalize(gCamera.worldPosition - input.worldPosition);
    float32_t3 halfVector = normalize(-gDirectionalLight.direction + toEye);
    float NDotH = dot(normalize(input.normal), halfVector);
    float specularPow = pow(saturate(NDotH),gMaterial.shininess);

    float32_t3 diffuse = 
     gMaterial.color.rgb * textureColor.rgb * gDirectionalLight.color.rgb * cos * gDirectionalLight.intensity;
    float32_t3 specular = 
     gDirectionalLight.color.rgb * gDirectionalLight.intensity * specularPow * float32_t3(1.0f,1.0f,1.0f);

   output.color.rgb = diffuse + specular;
    output.color.a = gMaterial.color.a * textureColor.a;
  } else {
    output.color = gMaterial.color * textureColor;
  }

return output;
}