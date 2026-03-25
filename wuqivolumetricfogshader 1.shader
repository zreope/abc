Shader "Custom/VolumetricFogShader"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {} // 占位符，用于 Blit
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // --- 变量声明 ---
            sampler2D _MainTex; // 屏幕原图
            sampler2D _CameraDepthTexture; // 深度图
            float4 _FogColor;
            float _FogDensity;
            int _StepCount;
            float _NoiseScale;
            float _NoiseSpeed;
            
            // 摄像机信息
            float4x4 _FrustumCorners;
            float3 _CameraWorldPos;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 rayDir : TEXCOORD1; // 射线方向
            };

            // 顶点着色器：计算射线方向
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                // 根据 UV 坐标插值计算视锥体射线方向
                // UV (0,0) 是左下，(1,1) 是右上
                float2 uv = v.uv;
                float3 corner1 = _FrustumCorners[0].xyz; // 左下
                float3 corner2 = _FrustumCorners[1].xyz; // 右下
                float3 corner3 = _FrustumCorners[2].xyz; // 右上
                float3 corner4 = _FrustumCorners[3].xyz; // 左上

                float3 bottom = lerp(corner1, corner2, uv.x);
                float3 top = lerp(corner4, corner3, uv.x);
                float3 rayDir = lerp(bottom, top, uv.y);
                
                o.rayDir = normalize(rayDir);
                return o;
            }

            // 简单的伪噪声函数
            float SimpleNoise(float3 p)
            {
                return frac(sin(dot(p, float3(12.9898, 78.233, 45.164))) * 43758.5453);
            }

            // 片元着色器：核心体积雾算法
            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 获取屏幕原始颜色
                fixed4 originalColor = tex2D(_MainTex, i.uv);

                // 2. 获取当前像素的深度
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                depth = Linear01Depth(depth); // 转换为 0-1 线性深度

                // 3. 计算射线与场景物体的交点位置
                // 这里的 _ProjectionParams.z 是摄像机的远裁剪面距离
                float3 worldPos = _CameraWorldPos + i.rayDir * depth * _ProjectionParams.z;

                // 4. 光线步进
                float totalDensity = 0.0;
                // 步长 = 总距离 / 步数
                float stepLength = length(worldPos - _CameraWorldPos) / _StepCount;

                for(int j = 0; j < _StepCount; j++)
                {
                    float currentDist = j * stepLength;
                    float3 currentPos = _CameraWorldPos + i.rayDir * currentDist;

                    // 计算噪声
                    float noise = SimpleNoise(currentPos * _NoiseScale + _Time.y * _NoiseSpeed);
                    
                    // 累加密度
                    // 这里的 0.5 + 0.5 * noise 是为了让噪声在 0.5 到 1.0 之间波动
                    float density = _FogDensity * (0.5 + 0.5 * noise);
                    totalDensity += density * stepLength;
                }

                // 5. 混合颜色
                // 使用 Beer-Lambert 定律：透光率 = e^(-密度)
                float transmittance = exp(-totalDensity);
                
                // 最终颜色 = 雾色 * (1 - 透光率) + 原图颜色 * 透光率
                fixed3 finalColor = lerp(_FogColor.rgb, originalColor.rgb, transmittance);

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
