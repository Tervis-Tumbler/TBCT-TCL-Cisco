# Tervis TBCT Script 


proc init { } {

     global param


     set param(enableReporting) true    
     set param(maxDigits) 1
     set param(initialDigitTimeout) 3600
     set param1(dialPlan) true
     set param1(initialDigitTimeout) 30

}

proc act_Setup { } {
      global dest
      
      leg setupack leg_incoming
      leg proceeding leg_incoming
      leg connect leg_incoming
      
      
      if { [infotag get leg_isdid] } {
          
	  set dest [infotag get leg_dnis]		
	  leg setup $dest callInfo leg_incoming
      } else {
	  call close
      } 
}

proc act_CallSetupDone { } {
      
      
      set status [infotag get evt_status] 
      
     if { $status == "ls_000"} { 
         
       puts "call has been hairpinned"

	
	call_digit_collection 
     } else {
        	 
       fsm setstate CALLDISCONNECTED
    } 
}


proc call_digit_collection { } {
     
     global param

     leg collectdigits leg_outgoing param 
}

proc act_EnterDigit { } {
     
     global digit
     
     set digit [infotag get evt_digit]
     if { $digit == "#" } {
	 
	  
          connection destroy con_all
          fsm setstate TRANSFER	
             
          
     } else {
	  puts "CALL IS ACTIVE"
          
          fsm setstate CALLACTIVE
     } 
}

proc act_Transfer { } {
  
        set callInfo(mode) REDIRECT_AT_CONNECT
        set callInfo(notifyEvents) "ev_transfer_status ev_alert ev_progress ev_transfer_request"
       
        leg setup 18005550199 callInfo leg_incoming
    
}


proc act_Cleanup { } { 
    call close 
} 

init

#---------------------------------- 
#   State Machine 
#---------------------------------- 
  set FSM(any_state,ev_disconnected)           "act_Cleanup,         same_state"  
  set FSM(CALL_INIT,ev_setup_indication)       "act_Setup,           PLACECALL" 
  set FSM(PLACECALL,ev_setup_done)             "act_CallSetupDone,   CALLACTIVE" 
  set FSM(CALLACTIVE,ev_digit_end)             "act_EnterDigit,       TRANSFER"
  set FSM(TRANSFER,ev_destroy_done)             "act_Transfer,CALLDISCONNECTED"
  set FSM(CALLDISCONNECTED,ev_disconnected)    "act_Cleanup,         same_state" 
  set FSM(CALLDISCONNECTED,ev_disconnect_done) "act_Cleanup,         same_state"

fsm define FSM  CALL_INIT

