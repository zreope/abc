using UnityEngine;

[ExecuteInEditMode] // 允许在编辑器模式下运行，方便调试
public class VolumetricFogController : MonoBehaviour
{
    [Header("雾气参数")]
    public Color fogColor = Color.gray; // 雾气颜色
    [Range(0.01f, 1.0f)] public float fogDensity = 0.3f; // 雾气浓度（核心参数）
    [Range(10, 200)] public int stepCount = 60; // 步进次数（越高越细腻，越耗性能）
    public float noiseScale = 0.5f; // 噪声大小
    public float noiseSpeed = 0.2f; // 噪声流动速度

    private Material fogMaterial;
    private Shader fogShader;

    void Start()
    {
        // 动态加载 Shader，防止找不到路径
        fogShader = Shader.Find("Custom/VolumetricFogShader");
        if (fogShader == null)
        {
            Debug.LogError("找不到 VolumetricFogShader，请确保 Shader 已创建且名字正确！");
            return;
        }
        fogMaterial = new Material(fogShader);

        // 确保摄像机开启深度纹理，否则无法计算距离
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (fogMaterial == null) return;

        // 将 C# 中的参数传递给 Shader
        fogMaterial.SetColor("_FogColor", fogColor);
        fogMaterial.SetFloat("_FogDensity", fogDensity);
        fogMaterial.SetInt("_StepCount", stepCount);
        fogMaterial.SetFloat("_NoiseScale", noiseScale);
        fogMaterial.SetFloat("_NoiseSpeed", noiseSpeed);

        // 传递摄像机信息给 Shader
        // 这一步是为了让 Shader 知道如何从屏幕像素反推世界坐标
        Matrix4x4 frustumCorners = GetFrustumCorners();
        fogMaterial.SetMatrix("_FrustumCorners", frustumCorners);
        fogMaterial.SetVector("_CameraWorldPos", transform.position);

        // 执行全屏渲染
        Graphics.Blit(source, destination, fogMaterial);
    }

    // 计算视锥体四个角的世界坐标方向
    Matrix4x4 GetFrustumCorners()
    {
        Matrix4x4 corners = Matrix4x4.identity;
        Camera cam = GetComponent<Camera>();

        Vector3[] frustumCorners = new Vector3[4];
        // 计算远裁剪面的四个角
        cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1), cam.farClipPlane, cam.stereoActiveEye, frustumCorners);

        for (int i = 0; i < 4; i++)
        {
            // 转换为世界空间的方向向量
            Vector3 worldCorner = cam.transform.TransformDirection(frustumCorners[i]);
            corners.SetRow(i, worldCorner);
        }
        return corners;
    }
}
