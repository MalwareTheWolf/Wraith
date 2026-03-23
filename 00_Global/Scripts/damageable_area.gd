@icon("uid://cr0h12d36c35s")
class_name DamageableArea extends Area2D

# Area that can receive damage from attack hitboxes.
# Also supports temporary invulnerability and optional hit audio.


#SIGNALS

# Emitted when this area is struck by an attack.
signal damage_taken(attack_area)



#TUNABLES

# Sound played when damage is received.
@export var audio: AudioStream



#DAMAGE

# Called when an attack area hits this damageable area.
func take_damage(attack_area: AttackArea) -> void:

	# Notify listeners that damage was received.
	damage_taken.emit(attack_area)

	# Play hit sound at this position if assigned.
	if audio:
		Audio.play_spatial_sound(audio, global_position)



#INVULNERABILITY

# Makes this area temporarily unable to receive damage.
func make_invulnerable(duration: float = 1.0) -> void:

	# Disable processing so hits are ignored.
	process_mode = Node.PROCESS_MODE_DISABLED

	await get_tree().create_timer(duration).timeout

	# Re-enable normal processing after delay.
	process_mode = Node.PROCESS_MODE_INHERIT


# Starts invulnerability until ended manually.
func start_invulnerable() -> void:

	# Disable damage processing.
	process_mode = Node.PROCESS_MODE_DISABLED


# Ends invulnerability and allows damage again.
func end_invulnerable() -> void:

	# Restore normal processing.
	process_mode = Node.PROCESS_MODE_INHERIT
