using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MouseLook : MonoBehaviour
{

    [SerializeField] Vector2 sensitivity = Vector3.one * 5;
    [SerializeField] float smoothing = 2;
    [SerializeField] Transform cameraTrans = null;

    float xRotate = 0;
    Vector2 smoothV;
    Vector2 mouseLook;

    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
    }
    void Update()
    {
        Vector2 md = new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"));
        md = Vector2.Scale(md, new Vector2(sensitivity.x * smoothing, sensitivity.y * smoothing));
        // the interpolated float result between the two float values
        smoothV.x = Mathf.Lerp(smoothV.x, md.x, 1f / smoothing);
        smoothV.y = Mathf.Lerp(smoothV.y, md.y, 1f / smoothing);
        // incrementally add to the camera look
        mouseLook += smoothV;
        mouseLook.y = Mathf.Clamp(mouseLook.y, -90, 90);

        // vector3.right means the x-axis
        cameraTrans.localRotation = Quaternion.AngleAxis(-mouseLook.y, Vector3.right);
        transform.Rotate(Vector3.up, smoothV.x); 
    }
}
