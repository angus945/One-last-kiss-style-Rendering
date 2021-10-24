Shader "Hidden/OneLastKiss"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : POSITION1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;

            float2 _MainTex_TexelSize;

            float _colorWigth;
            float _normalWight;
            float _depthWight;
            float _power;

            //
            float _plusValue;
            int _radius;
            float _scale;

            //common
            int _rednerType;
            sampler2D _backGruondTex;
            fixed4 _colorStart;
            fixed4 _colorEnd;
            float _angle;

            float _attenuation;


            #define deg2rad 0.0174532925



			float colorSobel(float2 uv)
			{
				float x = 0;
				float y = 0;
				float2 texelSize = _MainTex_TexelSize;

				x += tex2D(_MainTex, uv + float2(-texelSize.x, -texelSize.y)) * -1;
				x += tex2D(_MainTex, uv + float2(-texelSize.x, 			  0)) * -2;
				x += tex2D(_MainTex, uv + float2(-texelSize.x,  texelSize.y)) * -1;

				x += tex2D(_MainTex, uv + float2( texelSize.x, -texelSize.y)) *  1;
				x += tex2D(_MainTex, uv + float2( texelSize.x, 			  0)) *  2;
				x += tex2D(_MainTex, uv + float2( texelSize.x,  texelSize.y)) *  1;

				y += tex2D(_MainTex, uv + float2(-texelSize.x, -texelSize.y)) * -1;
				y += tex2D(_MainTex, uv + float2(			0, -texelSize.y)) * -2;
				y += tex2D(_MainTex, uv + float2( texelSize.x, -texelSize.y)) * -1;

				y += tex2D(_MainTex, uv + float2(-texelSize.x,  texelSize.y)) *  1;
				y += tex2D(_MainTex, uv + float2(			0,  texelSize.y)) *  2;
				y += tex2D(_MainTex, uv + float2( texelSize.x,  texelSize.y)) *  1;

				return sqrt(x * x + y * y);
			}
            float normalSobel(float2 uv)
			{

				float2 texelSize = _MainTex_TexelSize;

                // float3 worldNormal = tex2D(_CameraDepthNormalsTexture, uv);
                // return float4( worldNormal.xyz, 1);

                float3 normaBL = tex2D(_CameraDepthNormalsTexture, uv + float2(-texelSize.x,  -texelSize.y)).rgb;
                float3 normaTR = tex2D(_CameraDepthNormalsTexture, uv + float2( texelSize.x,   texelSize.y)).rgb;
                float3 normaBR = tex2D(_CameraDepthNormalsTexture, uv + float2( texelSize.x,  -texelSize.y)).rgb;
                float3 normaTL = tex2D(_CameraDepthNormalsTexture, uv + float2(-texelSize.x,   texelSize.y)).rgb;

                float3 normalFiniteDifference0 = normaTR - normaBL;
                float3 normalFiniteDifference1 = normaTL - normaBR;

                float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));

                return edgeNormal;
			}
            float depthSobel(float2 uv)
            {
                // fixed4 depth = tex2D(_CameraDepthTexture,  uv).r;
                // float depthLinear = Linear01Depth(depth);
                // return depthLinear;

				float2 texelSize = _MainTex_TexelSize;
                
                float depthBL = tex2D(_CameraDepthTexture, uv + float2(-texelSize.x,  -texelSize.y)).r;
                float depthTR = tex2D(_CameraDepthTexture, uv + float2( texelSize.x,   texelSize.y)).r;
                float depthBR = tex2D(_CameraDepthTexture, uv + float2( texelSize.x,  -texelSize.y)).r;
                float depthTL = tex2D(_CameraDepthTexture, uv + float2(-texelSize.x,   texelSize.y)).r;

                float3 depthFiniteDifference0 = depthTR - depthBL;
                float3 depthFiniteDifference1 = depthTL - depthBR;

                float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
                return edgeDepth;
            }
            float edgeValue(float2 uv)
            {                
                float colorEdge = colorSobel(uv) * _colorWigth;
                float normalEdge = normalSobel(uv) * _normalWight;
                float depthEdge = depthSobel(uv) * _depthWight;
                
                float value = colorEdge + normalEdge + depthEdge;
                value = pow(value, _power);

                return saturate(value);
            }

            //
            fixed4 gradualColor(float2 uv)
            {                
                float radian = _angle * deg2rad;
                float2 projLine = float2(cos(radian), sin(radian));      
                float2 pos = (uv - 0.5) * 2;   
                float value = abs(dot(projLine, pos));
                        
                fixed4 gradual = lerp(_colorStart, _colorEnd, value);
                return gradual;
            }

            fixed4 oneLastKiss_edgeDetect(float2 uv)
            {
                fixed4 gradual = gradualColor(uv);
                float edge = edgeValue(uv);
                fixed4 backGround = tex2D(_backGruondTex, uv);
                fixed4 edgeColor = lerp(backGround, gradual, edge);

                fixed4 linearDepth = Linear01Depth(tex2D(_CameraDepthTexture, uv).r);
                float depthAttenuation = pow(linearDepth, _attenuation);
                return lerp(edgeColor, backGround, depthAttenuation);
            }
            
            //filter
            float colorValue(float2 uv)
            {
                fixed4 col = tex2D(_MainTex, uv);
                float grayscale = (col.r + col.g + col.b) / 3;
                float negative = 1 - grayscale;
                return negative;
            }
            float lineDetect(float2 uv)
            {
                float value = colorValue(uv);
                float draftLine = colorValue(uv);
				float2 texelSize = _MainTex_TexelSize;

                for (int x = -_radius; x <= _radius; x++)
                {
                    for (int y = -_radius; y <= _radius; y++)
                    {
                        float2 pixelOffset = float2(x, y) * texelSize; 
                        draftLine = min(draftLine, colorValue(uv + pixelOffset));
                    }
                }
                float lineValue = (value - draftLine) * _scale;

                return saturate(lineValue);
            }
            float4 oneLastKiss_lineCatch(float2 uv)
            {
                fixed4 gradual = gradualColor(uv);
                float edge = lineDetect(uv);

                fixed4 backGround = tex2D(_backGruondTex, uv);
                fixed4 linearDepth = Linear01Depth(tex2D(_CameraDepthTexture, uv).r);

                fixed4 edgeColor = lerp(backGround, gradual, edge);
                float depthAttenuation = pow(linearDepth, _attenuation);
                return lerp(edgeColor, backGround, depthAttenuation);
            }


            fixed4 frag (v2f i) : SV_Target
            {              
                // return lineDetect(i.uv);

                
                fixed4 color = 0;
                switch (_rednerType)
                {
                    case 0:
                        color = tex2D(_MainTex, i.uv);
                        break;
                    
                    case 1:
                        color = oneLastKiss_edgeDetect(i.uv);
                        break;
                    case 2:
                        color = oneLastKiss_lineCatch(i.uv);
                        break;
                }
                // return lineDetect(i.uv);
                return color;


                //use edge detect
                // fixed4 color = oneLastKiss_edgeDetect(i.uv);
                // return color;
            }
            ENDCG
        }
    }
}
