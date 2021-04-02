
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ShaderManager : UdonSharpBehaviour
{

    public GameObject spawnItem;
    public PlayerTracker tracker;
    // use player list to track all players
    // when the button to play animations is pressed, spawn all the balls on the players
    void Start()
    {
        
    }

    void OnMouseDown() {
        string h = "hello";
        for (int i = 0; i < tracker.GetPlayers().Length; i++){
            
        }
    }
}
