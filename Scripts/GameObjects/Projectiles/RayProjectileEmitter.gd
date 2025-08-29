class_name RayProjectileEmitter
extends CastProjectileEmitter


func fire(parent: Node3D, origin: Vector3, target: Vector3) -> Node3D:
	## Evaluate range and overshoot.
	## If overshoot, go full range towards the target
	if overshoot:
		target = origin + origin.direction_to(target) * projectile_range
	## Else, go towards the target up to the maximum range
	else:
		target = origin + origin.direction_to(target) * min(origin.distance_to(target), projectile_range)
	
	## Get space state.
	var world := parent.get_world_3d()
	var space_state := world.direct_space_state

	## Get a combined mask of both terrain and target to project just a single ray.
	var combined_collision_mask: int = target_collision_mask | terrain_collision_mask
	## The point from which the next ray will originate.
	var next_query_origin: Vector3 = origin
	## Exclude the previously hit object.
	var next_query_exclude: Array[RID] = []
	## Reduce that number every hit and stop the loop when it reaches 0, ignore if -1.
	var remaining_hits: int = max_hits
	## The position at which the projectile dies.
	var death_pos: Vector3
	## Have the projectile ever fired
	var fired: bool = false

	while true:
		## Project ray
		var query := PhysicsRayQueryParameters3D.create(
		next_query_origin, target, combined_collision_mask, next_query_exclude
			)
		query.collide_with_areas = true
		var query_result := space_state.intersect_ray(query)
		## Check if the projectile should fire:
		if !query_result:
			## If nothing was hit and not fire_on_miss, set death pos and break.
			if !fire_on_miss:
				death_pos = target
				break
			## If nothing was hit and fire_on_miss, set death_pos, fired and break.
			else:
				fired = true
				death_pos = target
				break

		## At this point the projectile was necessarily fired
		fired = true

		## At this point the projectile hit something, so if reduce_hits_on_terrain,
		## this necessarily means reducing hits.
		if reduce_hits_on_terrain and max_hits > 0:
			remaining_hits -= 1

		## Create new ProjHitData object.
		var collision_data := ProjHitData.new()
		collision_data.collider = query_result["collider"]
		collision_data.collision_pos = query_result["position"]

		## Check if the projectile should trigger hit signals
		## If target was hit or terrain was hit and trigger_on_terrain
		if \
		collision_data.collider.collision_layer & target_collision_mask or \
		(collision_data.collider.collision_layer & terrain_collision_mask and \
		trigger_on_terrain):
			## Reduce hits, keeping in mind the potential previous reduction
			if !reduce_hits_on_terrain and max_hits > 0:
				remaining_hits -= 1
			## If instantenous, emit the signal
			if instantaneous:
				projectile_hit.emit(collision_data)
			## Else, set up a hit timer
			else:
				var delay: float = \
				origin.distance_to(collision_data.collision_pos) / projectile_speed
				var hit_timer := parent.get_tree().create_timer(delay, false, true)
				hit_timer.timeout.connect(projectile_hit.emit.bind(collision_data))

		## Check if the projectile dies at this collision
		## If remaining_hits == 0 and finite hits, set death_pos and break.
		if max_hits > 0 and remaining_hits == 0:
			death_pos = collision_data.collision_pos
			break
		## If terrain was hit and die on terrain is true, set death_pos and break.
		if collision_data.collider.collision_layer & terrain_collision_mask and \
		die_on_terrain:
			death_pos = collision_data.collision_pos
			break
		## At this point the projectile is still alive, and will continue
		## towards the target, repeating this loop until it breaks.
		## Prepare the next loop.
		next_query_exclude = [collision_data.collider.get_rid()]
		next_query_origin = collision_data.collision_pos

	## Exit the loop.
	## Handle projectile death.
	## If there was no projectile, return.
	if not fired:
		return null
	## If the projectile hit instantly, it dies instantly.
	if instantaneous:
		projectile_died.emit(death_pos)
	## If the projectile has travel time, set up a timer.
	else:
		var death_delay: float = origin.distance_to(death_pos) / projectile_speed
		var death_timer := parent.get_tree().create_timer(death_delay, false, true)
		death_timer.timeout.connect(projectile_died.emit.bind(death_pos))
	## Handle the fake projectile.
	## Check if the fake projectile should fire at all.
	if not create_fake_projectile:
		return null
	## The end.
	return fire_fake_proj(parent, origin, death_pos)
