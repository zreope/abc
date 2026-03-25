Shader "Custom/VolumetricFogShader"
{
    Properties
    {
        _Color ("Fog Color", Color) = (0.6, 0.6, 0.6, 1)
        _Density ("Fog Density", Range(0.01, 0.5)) = 0.1
        _NoiseStrength ("Noise Strength", Range(0, 1)) = 0.2
        _NoiseScale ("Noise Scale", Float) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
        LOD 200

        // 开启混合模式，让雾能半透明显示
        Blend SrcAlpha OneMinusSrcAlpha
        // 关闭深度写入（关键！防止遮挡后面的物体）
        ZWrite Off
        // 剔除背面（只渲染正面，防止内部看内部时的黑边）
        Cull Off

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            // --- 属性变量 ---
            fixed4 _Color;
            float _Density;
            float _NoiseStrength;
            float _NoiseScale;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0; // 传递世界坐标用于计算距离
            };

            // 简单的噪声函数（模拟雾气的不均匀）
            float SimpleNoise(float3 p)
            {
                return frac(sin(dot(p, float3(12.9898, 78.233, 45.164))) * 43758.5453);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 计算视线方向（从摄像机到当前像素）
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                
                // 2. 计算视线长度（距离）
                // 这就是实现“近清远糊”的核心：距离越长，雾越浓
                float dist = length(_WorldSpaceCameraPos - i.worldPos);

                // 3. 计算基础透明度
                // 使用指数衰减模拟真实雾气：Transmittance = e^(-density * distance)
                // 我们反过来算雾的浓度：1 - e^(-density * distance)
                float fogFactor = 1.0 - exp(-_Density * dist);

                // 4. 添加噪声（让雾看起来像云一样有体积感，而不是死板的玻璃）
                float noise = SimpleNoise(i.worldPos * _NoiseScale) * _NoiseStrength;
                fogFactor += noise;
                
                // 限制范围 0-1
                fogFactor = saturate(fogFactor);

                // 5. 输出颜色
                // 雾的颜色 * 雾的浓度
                fixed4 col = _Color;
                col.a = fogFactor; // 将计算出的浓度赋值给透明度

                return col;
            }
            ENDCG
        }
    }
}
