
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Object_Toggle : UdonSharpBehaviour
{

    public GameObject targetObject;
    private Animator anim;
    void Start()
    {
        anim = targetObject.GetComponent<Animator>();    
    }

    void Interact(){
        // targetObject.SetActive(!targetObject.activeSelf);
        anim.SetBool("isActive", !anim.GetBool("isActive"));
    }
}
