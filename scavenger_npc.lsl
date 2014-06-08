/*Action Constants*/
integer TALK = 0;
integer GIVE = 1;

/*v### NPC Settings - Make Changes Below ###v*/
string TRIGGER_ID = "Lisette"; //NPC Name
string GREETINGS = "Hi! Welcome to Courtesy VSD Scavenger Hunt! How may I help you?";
string DIALOGUE_OPTION_A = "Who are you?";
string DIALOGUE_OPTION_B = "Have you seen any broken mill parts around here?";
string DIALOGUE_OPTION_C = "Can I get an information notecard?";
string ITEM_OPTION_A = "NO_ITEM";
string ITEM_OPTION_B = "NO_ITEM";
string ITEM_OPTION_C = "Scavenger Hunt Information";
string REPLY_A = "My name is Lisette. I take care of this VSD hub! Please make yourself at home.";
string REPLY_B = "I think I saw something flew from the sky just a few moments ago.";
string REPLY_C = "Here you go!";
integer ACTION_OPTION_A = TALK;
integer ACTION_OPTION_B = TALK;
integer ACTION_OPTION_C = GIVE;
key NPC_TEXTURE = "a27c6a99-ff74-f517-4fcf-5930eff3e655"; //Texture UUID
string FLOATING_TEXT = "[Wear HUD and click to interact with this NPC]";
/*^### NPC Settings- Make Changes Above ###^*/

/*Global Constants*/
string SEPERATOR = "|||";
list DIALOGUE_OPTIONS = [DIALOGUE_OPTION_A, DIALOGUE_OPTION_B, DIALOGUE_OPTION_C];
list ACTION_OPTIONS = [ACTION_OPTION_A, ACTION_OPTION_B, ACTION_OPTION_C]; 
list REPLY_OPTIONS = [REPLY_A, REPLY_B, REPLY_C]; 
list ITEM_OPTIONS = [ITEM_OPTION_A, ITEM_OPTION_B, ITEM_OPTION_C];
integer SCAVENGER_HUD_CHANNEL = -498; 
integer SCAVENGER_OBJECT_CHANNEL = 498;
string XOR_KEY = "husky498uw!";
    
/*Index Constants for Incoming Parameters*/
integer TIME_STAMP = 0;
integer ID = 1;
integer COMMAND = 2;
integer PARAMETER = 3;

/*Global Variables*/
integer listenHandle = 0;
integer timerCounter = 1;

/*Encode & Decode Functions (for security)*/
string Xor(string data, string xorKey)
{
     return llXorBase64(llStringToBase64(data), llStringToBase64(xorKey));
}
 
string Dexor(string data, string xorKey) 
{
     return llBase64ToString(llXorBase64(data, llStringToBase64(xorKey)));
}

ReturnAction(key avatarKey, integer dialogueIndex)
{
    integer action = llList2Integer(ACTION_OPTIONS, dialogueIndex);

    string timeStamp = llGetTimestamp();    
    string command = "NPC_TALK";
    string parameter = TRIGGER_ID;
    string item = llList2String(ITEM_OPTIONS, dialogueIndex);
    
    if(action == GIVE)
    {
        llGiveInventory(avatarKey, item);
    }
    
    string reply = llList2String(REPLY_OPTIONS, dialogueIndex);
    parameter = TRIGGER_ID + "***" + reply;
    string xorParameterList = Xor(timeStamp + SEPERATOR + (string)avatarKey + SEPERATOR + command + SEPERATOR + parameter, XOR_KEY + (string)avatarKey);  
    
    llSay(SCAVENGER_HUD_CHANNEL, xorParameterList);      
}

default
{
    state_entry()
    {
        llSetText("[NPC] " + TRIGGER_ID + "\n" + FLOATING_TEXT, <1.0, 1.0, 1.0>, 1.0);
        llListenRemove(listenHandle);    
        listenHandle = llListen(SCAVENGER_OBJECT_CHANNEL, "", "", "");
    }
    
    touch_end(integer num_detected)
    {
        string timeStamp = llGetTimestamp();
        string avatarKey = llDetectedKey(0);
        string command = "RETURN_DIALOGUE_OPTION";
        string parameter = TRIGGER_ID + "***" + (string)NPC_TEXTURE + "***" + llDumpList2String(DIALOGUE_OPTIONS, "###");
        
        string xorParameterList = Xor(timeStamp + SEPERATOR + avatarKey + SEPERATOR + command + SEPERATOR + parameter, XOR_KEY + avatarKey);
        
        llSay(SCAVENGER_HUD_CHANNEL, xorParameterList); 

        command = "NPC_TALK";
        parameter = TRIGGER_ID + "***" + GREETINGS;        
        
        xorParameterList = Xor(timeStamp + SEPERATOR + avatarKey + SEPERATOR + command + SEPERATOR + parameter, XOR_KEY + avatarKey);        

        llSay(SCAVENGER_HUD_CHANNEL, xorParameterList);  
    }
    
    listen(integer channel, string name, key id, string message)
    {
        list parameterList = llParseString2List(Dexor(message, XOR_KEY + TRIGGER_ID), [SEPERATOR], [""]);  
        
        if(llGetListLength(parameterList) == 4)
        {   
            string timeStamp = llList2Key(parameterList, TIME_STAMP);        
            string triggerID = llList2String(parameterList, ID); //Avatar Key or Trigger ID
            string command = llList2String(parameterList, COMMAND);
            string parameter = llList2String(parameterList, PARAMETER);      
            
            if(command == "CHOOSE_DIALOGUE")
            {
                integer dialogueIndex = llListFindList(DIALOGUE_OPTIONS, [parameter]);  
                         
                if(dialogueIndex != -1)
                {
                    ReturnAction(llGetOwnerKey(id), dialogueIndex);
                }
            }
        }
    }     
}