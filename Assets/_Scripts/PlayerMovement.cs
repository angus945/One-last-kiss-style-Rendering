using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{

    [SerializeField] CharacterController controller = null;
    [SerializeField] float speed = 5;

    [Space]
    [SerializeField] float gravity = -9.8f;

    [Space]
    [SerializeField] Transform groundCheck = null;
    [SerializeField] float groundDis = 0.4f;
    [SerializeField] LayerMask groundMask = 0;

    [Space]
    [SerializeField] float jump = 3;

    Vector3 velocity;
    bool isGround;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 axis = Vector3.zero;
        axis.x = Input.GetAxisRaw("Horizontal");
        axis.z = Input.GetAxisRaw("Vertical");

        Vector3 motion = (transform.right * axis.x + transform.forward * axis.z).normalized;
        controller.Move(motion * speed * Time.deltaTime);

        isGround = Physics.CheckSphere(groundCheck.position, groundDis, groundMask);
        if (isGround && velocity.y < 0) velocity.y = -2;

        if(Input.GetButtonDown("Jump") && isGround)
        {
            velocity.y = Mathf.Sqrt(jump * -2f * gravity);
        }

        velocity.y += gravity * Time.deltaTime;
        controller.Move(velocity * Time.deltaTime);
    }
    public void MoveDirection(Vector3 dire)
    {
        controller.Move(dire * Time.deltaTime);
    }

}
