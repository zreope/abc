using UnityEngine;

[RequireComponent(typeof(Camera))]
public class GhostCameraController : MonoBehaviour
{
    [Header("基础移动")]
    public float moveSpeed = 5f;
    public float fastSpeed = 15f;
    public float slowSpeed = 2f;

    [Header("鼠标视角")]
    public float mouseSensitivity = 2f;
    public float upLimit = 89f;
    public float downLimit = -89f;

    [Header("上下飞行")]
    public KeyCode riseKey = KeyCode.Space;
    public KeyCode fallKey = KeyCode.Z;

    [Header("鼠标切换键")]
    public KeyCode toggleMouseKey = KeyCode.LeftAlt;

    private float pitch = 0f;
    private float yaw = 0f;
    private bool isMouseLocked = true;

    private void Start()
    {
        yaw = transform.eulerAngles.y;
        pitch = transform.eulerAngles.x;
        SetMouseLock(true);
    }

    private void Update()
    {
        // 按 LeftAlt 切换鼠标锁定/解锁
        if (Input.GetKeyDown(toggleMouseKey))
        {
            isMouseLocked = !isMouseLocked;
            SetMouseLock(isMouseLocked);
        }

        if (isMouseLocked)
        {
            MouseLook();
            MoveControl();
        }
    }

    private void MouseLook()
    {
        float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;

        yaw += mouseX;
        pitch -= mouseY;
        pitch = Mathf.Clamp(pitch, downLimit, upLimit);

        transform.eulerAngles = new Vector3(pitch, yaw, 0f);
    }

    private void MoveControl()
    {
        float speed = moveSpeed;

        if (Input.GetKey(KeyCode.LeftShift))
            speed = fastSpeed;
        else if (Input.GetKey(KeyCode.LeftControl))
            speed = slowSpeed;

        float h = Input.GetAxisRaw("Horizontal");
        float v = Input.GetAxisRaw("Vertical");

        Vector3 dir = transform.right * h + transform.forward * v;

        if (Input.GetKey(riseKey))
            dir += transform.up;
        if (Input.GetKey(fallKey))
            dir -= transform.up;

        dir.Normalize();

        transform.position += dir * speed * Time.deltaTime;
    }

    void SetMouseLock(bool locked)
    {
        if (locked)
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }
        else
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
    }
}