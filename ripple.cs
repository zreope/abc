using UnityEngine;

public class RippleEffect : MonoBehaviour
{
    public float expandSpeed = 5f; // 扩散速度
    public float fadeSpeed = 2f;   // 消失速度
    public float lifeTime = 1.0f;  // 存活时间

    private Renderer myRenderer;
    private Vector3 startScale;
    private float timer = 0f;

    void Start()
    {
        myRenderer = GetComponent<Renderer>();
        startScale = transform.localScale;
        // 初始大小设为0
        transform.localScale = Vector3.zero;
    }

    void Update()
    {
        timer += Time.deltaTime;

        // 1. 变大逻辑
        // 随着时间推移，缩放越来越大
        float currentSize = timer * expandSpeed;
        transform.localScale = new Vector3(currentSize, currentSize, currentSize);

        // 2. 淡出逻辑
        // 计算透明度：随着时间推移，透明度从1降到0
        float alpha = 1.0f - (timer / lifeTime);
        if (alpha < 0) alpha = 0;

        Color color = myRenderer.material.color;
        color.a = alpha;
        myRenderer.material.color = color;

        // 3. 销毁逻辑
        if (timer >= lifeTime)
        {
            Destroy(gameObject); // 时间到了，销毁这个涟漪
        }
    }
}
