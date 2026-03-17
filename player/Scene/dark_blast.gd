class_name PlayerStateGroundSlam extends PlayerState

const DASH_AUDIO = preload("uid://fp3pia3qydwj")
const BOOM_AUDIO = preload("uid://cpy4obvavg3o7")
const BREAK_WOOD_AUDIO = preload("uid://d13c64ewv15ri")

const HIT_WOOD_LARGE = preload("uid://d13c64ewv15ri")
const HIT_WOOD_MEDIUM = preload("uid://d13c64ewv15ri")
const HIT_WOOD_SMALL = preload("uid://d13c64ewv15ri")


@export var velocity : float = 400
@export var effect_delay : float = 0.075
var effect_timer : float = 0

@onready var damageable_area: DamageableArea = %DamageableArea
@onready var ground_slam_attack_area: AttackArea = %GroundSlamAttackArea
@onready var ground_slam_shape_cast: ShapeCast2D = $"../../GroundSlamShapeCast"



# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:
	player.animation_player.play( "ground_slam" )
	player.sprite.tween_color()
	Audio.play_spatial_sound( DASH_AUDIO, player.global_position )
	damageable_area.start_invulnerable()
	ground_slam_attack_area.set_active()
	pass


# What happens when we exit this state?
func exit() -> void:
	VisualEffects.camera_shake( 10.0 )
	VisualEffects.land_dust( player.global_position )
	VisualEffects.hit_dust( player.global_position )
	Audio.play_spatial_sound( BOOM_AUDIO, player.global_position )
	damageable_area.end_invulnerable()
	ground_slam_attack_area.set_active( false )
	pass


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	return null


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	check_collisions( _delta )
	effect_timer -= _delta
	if effect_timer < 0:
		effect_timer = effect_delay
		player.sprite.ghost()
	return null


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity = Vector2( 0, velocity )
	if player.is_on_floor():
		if not check_collisions( _delta ):
			return idle
	return next_state


func check_collisions( _delta : float ) -> bool:
	ground_slam_shape_cast.target_position.y = velocity * _delta
	ground_slam_shape_cast.force_shapecast_update()
	if ground_slam_shape_cast.is_colliding():
		for i in ground_slam_shape_cast.get_collision_count():
			var c = ground_slam_shape_cast.get_collider( i )
			var pos : Vector2 = ground_slam_shape_cast.get_collision_point( i )
			
			VisualEffects.hit_dust( pos )
			VisualEffects.camera_shake( 10.0 )
			
			if c.get_parent() is Breakable:
				var b : Breakable = c.get_parent()
				b.queue_free()
				Audio.play_spatial_sound( b.destroy_audio, pos )
				for p in b.destroy_particles:
					VisualEffects.hit_particles( pos, Vector2.DOWN, p )
			else:
				c.queue_free()
				VisualEffects.hit_particles( pos, Vector2.DOWN, HIT_WOOD_LARGE )
				VisualEffects.hit_particles( pos, Vector2.DOWN, HIT_WOOD_MEDIUM )
				VisualEffects.hit_particles( pos, Vector2.UP, HIT_WOOD_SMALL )
				Audio.play_spatial_sound( BREAK_WOOD_AUDIO, pos )
			
		return true
	return false
