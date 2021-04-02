
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Object_Toggle_Collider : UdonSharpBehaviour
{
    public GameObject targetObject;
    private Animator anim;
    void Start()
    {
        anim = targetObject.GetComponent<Animator>();    
    }

    private void OnTriggerEnter(Collider other) {
        // targetObject.SetActive(!targetObject.activeSelf);
        anim.SetBool("isActive", true);
    }

    private void OnTriggerExit(Collider other) {
        // targetObject.SetActive(!targetObject.activeSelf);
        anim.SetBool("isActive", false);
    }

}
