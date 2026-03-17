#VisualEffects
extends Node

const DUST_EFFECT = preload("uid://dhvjvwf1i08ua")
const HIT_PARTICLES = preload("uid://d1av2hrkq170n")

signal camera_shook( strength : float )



# Create dust effects
# Create new instance of a dust effect
func _create_dust_effect( pos : Vector2 ) -> DustEffect:
	var dust : DustEffect = DUST_EFFECT.instantiate()
	add_child( dust )
	dust.global_position = pos
	return dust


# Create Jump Dust
func jump_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.JUMP )
	pass

# Create Land Dust
func land_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.LAND )
	pass

# Hit Dust
func hit_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.HIT )
	pass


func hit_particles( pos : Vector2, dir : Vector2, settings : HitParticleSettings ) -> void:
	var p : HitParticles = HIT_PARTICLES.instantiate()
	add_child( p )
	p.global_position = pos
	p.start( dir, settings )
	pass


func camera_shake( strength : float = 1.0 ) -> void:
	camera_shook.emit( strength )
	pass
