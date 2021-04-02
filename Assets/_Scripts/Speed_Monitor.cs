
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Speed_Monitor : UdonSharpBehaviour
{   
    public Material mat;
    Rigidbody rb;
    private Vector3 lastPos;
    private Vector3 lastRot;

    private float speedBuffer;
    private float rotBuffer;

    public float rotDeadZoneLimit = 0.1f;

    float _maxSpeed = 0.05f;
    private float _bufferInc = 1.0f;
    private bool showShader = true;
 

    void Start() {
        rb = GetComponent<Rigidbody>();
        speedBuffer = 0.0f; 
        rotBuffer = 0.0f; 
        lastPos = transform.position;
        lastRot = transform.rotation.eulerAngles;
    }

    void Update() {
        if (showShader){
            Vector3 dist = transform.position - lastPos;
            float speed = dist.sqrMagnitude / _maxSpeed;
            speedBuffer = PerformBufferCalculation(speed, speedBuffer);

            float rotVel = rb.angularVelocity.magnitude / rb.maxAngularVelocity; //maxAngularVel is 7rad/s
            rotVel = (rotVel > rotDeadZoneLimit) ? rotVel : 0.0f;
            rotBuffer = PerformBufferCalculation(rotVel, rotBuffer);

            float totalChange = (rotBuffer + speedBuffer) / 2.0f;

            mat.SetFloat("_Speed", totalChange);
            UpdatePosRot(transform.position, transform.rotation.eulerAngles);
        
        }

    }

    float PerformBufferCalculation(float a, float buffer){
        if (a > buffer){
            buffer = a;
        } else {
            buffer -= _bufferInc * Time.deltaTime;
        }
        return Mathf.Clamp(buffer, 0.0f, 1.5f);
    }

    void UpdatePosRot (Vector3 pos, Vector3 rot){
        lastPos = pos;
        lastRot = rot;
    }
    void OnPickup(){
        showShader = true;
        UpdatePosRot(transform.position, transform.rotation.eulerAngles);
    }
    void OnDrop(){
        showShader = false;
        UpdatePosRot(transform.position, transform.rotation.eulerAngles);
    }
}
