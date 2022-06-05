#ifndef SH_LIGHTING
#define SH_LIGHTING


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(unityPerMaterial)

half _Smoothness;
half4 _SHArray[16];
CBUFFER_END


struct Attributes
{
    float4 positionOS    : POSITION;
    float3 normalOS      : NORMAL;
    float4 tangentOS     : TANGENT;
    float2 texcoord      : TEXCOORD0;
    float2 staticLightmapUV    : TEXCOORD1;
    float2 dynamicLightmapUV    : TEXCOORD2;
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;

    float3 positionWS                  : TEXCOORD1;    // xyz: posWS

    #ifdef _NORMALMAP
    half4 normalWS                 : TEXCOORD2;    // xyz: normal, w: viewDir.x
    half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: viewDir.y
    half4 bitangentWS              : TEXCOORD4;    // xyz: bitangent, w: viewDir.z
    #else
    half3  normalWS                : TEXCOORD2;
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    half4 fogFactorAndVertexLight  : TEXCOORD5; // x: fogFactor, yzw: vertex light
    #else
    half  fogFactor                 : TEXCOORD5;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord             : TEXCOORD6;
    #endif


    #ifdef DYNAMICLIGHTMAP_ON
    float2  dynamicLightmapUV : TEXCOORD8; // Dynamic lightmap UVs
    #endif

    float4 positionCS                  : SV_POSITION;
};




half3 SpecialLighting(half3 normalWS)
{
    Light light = GetMainLight();
    return light.color * step(abs(dot(normalWS, light.direction)), 0.5);
}

Varyings SH_Lighting_Vertex(Attributes input)
{
    Varyings output = (Varyings)0;


    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    return output;
}


half3 SHLinearL0L1(real3 N, real4 sh0, real4 sh1, real4 sh2, real4 sh3)
{
    real4 vA = real4(N, 1.0);

    real3 x1;
    // Linear (L1) + constant (L0) polynomial terms
    x1 = dot(sh0, vA) + dot(sh1, vA) + dot(sh2, vA) + dot(sh3, vA);

    return x1;
}

half3 SHLinearL1(real3 N, real3 shAr, real3 shAg, real3 shAb)
{
    real3 x1;
    x1.r = dot(shAr, N);
    x1.g = dot(shAg, N);
    x1.b = dot(shAb, N);

    return x1;
}

half3 SHLinearL2(real3 N, real4 shBr, real4 shBg, real4 shBb, real4 shC)
{
    real3 x2;
    // 4 of the quadratic (L2) polynomials
    real4 vB = N.xyzz * N.yzzx;
    x2.r = dot(shBr, vB);
    x2.g = dot(shBg, vB);
    x2.b = dot(shBb, vB);

    // Final (5th) quadratic (L2) polynomial
    real vC = N.x * N.x - N.y * N.y;
    real3 x3 = shC.rgb * vC;

    return x2 + x3;
}

half3 SHLinearL3(real3 N, real4 shBr, real4 shBg, real4 shBb, real4 shC)
{
    real3 x2;
    // 4 of the quadratic (L2) polynomials
    real4 vB = N.xyzz * N.yzzx;
    x2.r = dot(shBr, vB);
    x2.g = dot(shBg, vB);
    x2.b = dot(shBb, vB);

    // Final (5th) quadratic (L2) polynomial
    real vC = N.x * N.x - N.y * N.y;
    real3 x3 = shC.rgb * vC;

    return x2 + x3;
}


half3 SampleSH16(half3 normalWS)
{
    // l= 0, m = 0
    half3 res = _SHArray[0].xyz;
  
    // l = 1, m = 1
    res += half3(    dot(normalWS.x, _SHArray[1].x),
                     dot(normalWS.x, _SHArray[1].y),
                     dot(normalWS.x, _SHArray[1].z));

    // l = 1, m = -1
    res += half3(    dot(normalWS.y, _SHArray[2].x),
                     dot(normalWS.y, _SHArray[2].y),
                     dot(normalWS.y, _SHArray[2].z));

    // l = 1, m = 0
    res += half3(    dot(normalWS.z, _SHArray[3].x),
                     dot(normalWS.z, _SHArray[3].y),
                     dot(normalWS.z, _SHArray[3].z));

    
    // l = 2, m = -2
    res += half3(    dot(normalWS.y * normalWS.x, _SHArray[4].x),
                     dot(normalWS.y * normalWS.x, _SHArray[4].y),
                     dot(normalWS.y * normalWS.x, _SHArray[4].z));

    // l = 2, m = -1
    res += half3(    dot(normalWS.y * normalWS.z, _SHArray[5].x),
                     dot(normalWS.y * normalWS.z, _SHArray[5].y),
                     dot(normalWS.y * normalWS.z, _SHArray[5].z));
    
    // l = 2, m = 0
    res += half3(    dot(3 * normalWS.z * normalWS.z - 1, _SHArray[6].x),
                     dot(3 * normalWS.z * normalWS.z - 1, _SHArray[6].y),
                     dot(3 * normalWS.z * normalWS.z - 1, _SHArray[6].z));

    // l = 2, m = 1
    res += half3(    dot(normalWS.x * normalWS.z, _SHArray[7].x),
                     dot(normalWS.x * normalWS.z, _SHArray[7].y),
                     dot(normalWS.x * normalWS.z, _SHArray[7].z));

    // l = 2, m = 2
    res += half3(    dot(normalWS.x * normalWS.x - normalWS.y * normalWS.y, _SHArray[8].x),
                     dot(normalWS.x * normalWS.x - normalWS.y * normalWS.y, _SHArray[8].y),
                     dot(normalWS.x * normalWS.x - normalWS.y * normalWS.y, _SHArray[8].z));

   
   

    
    return   res;
}




half4 SH_Lighting_Fragment(Varyings input) : SV_Target
{
    half3 normalWS = SafeNormalize(input.normalWS);
   
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

    half4 indirectSpecular = 0;
    
    return half4(SampleSH16(normalWS), 1.0);
}



Varyings Special_Lighting_Vertex(Attributes input)
{
    Varyings output = (Varyings)0;


    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    return output;
}


half4 Special_Lighting_Fragment(Varyings input) : SV_Target
{
    half3 worldNormal = SafeNormalize(input.normalWS);
    return half4(SpecialLighting(worldNormal), 1.0);
}





#endif