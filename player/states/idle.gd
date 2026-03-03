class_name PlayerStateIdle extends PlayerState 

  



func init() -> void: 
	pass 


#what happens when entering the state 
func enter() -> void: 
	player.animation_player.play( "Idle" )
	player.collision_crouch.disabled = true
	pass 

  
#what happens when exiting the state 
func exit() -> void: 
	pass 


#what happens when an input is pressed 
func handle_input( _event : InputEvent ) -> PlayerState:
	#Handle input
	if _event.is_action_pressed("jump"):
		return jump
	return next_state
  

#what happens each process tick in this state 
func process( _delta: float) -> PlayerState: 
	if player.direction.x != 0:
		return run
	elif player.direction.y >= 0.5:
		return crouch
	return next_state 


#what happens each process tick in this state 
func physics_process( _delta: float) -> PlayerState: 
	player.velocity.x = 0
	if player.is_on_floor() == false:
		return fall
	return next_state 
