// Independent two-joint arm poses, evaluated only for tagged arm vertices.
// No skeletons or per-person animation callbacks; all eight garments share this vocabulary.
const float CROWD_POSE_COUNT = 12.0;
uniform float pose_strength : hint_range(0.0, 1.0) = 1.0;

vec3 align_limb(vec3 value, vec3 from, vec3 to) {
	vec3 axis = cross(from, to);
	return value + cross(axis, value) + cross(axis, cross(axis, value)) / max(1.0 + dot(from, to), 0.0001);
}

vec3 segment_point(vec3 point, vec3 start, vec3 end, vec3 target_start, vec3 target_end) {
	vec3 from = normalize(end - start);
	vec3 to = normalize(target_end - target_start);
	vec3 relative = point - start;
	float stretch = length(target_end - target_start) / length(end - start);
	// Preserve limb thickness when a pose adjusts the length of a segment.
	relative += from * dot(relative, from) * (stretch - 1.0);
	return target_start + align_limb(relative, from, to);
}

void crowd_arm_pose(inout vec3 point, inout vec3 normal, float side, float forearm, float broad, float pose, float time, float phase, float motion) {
	vec3 shoulder = vec3(side * 0.126 * broad, 0.861, 0.0);
	vec3 elbow = vec3(side * 0.178 * broad, 0.685, 0.018);
	vec3 wrist = vec3(side * 0.169 * broad, 0.506, 0.035);
	vec3 target_elbow = elbow;
	vec3 target_wrist = wrist;
	if (pose < 0.5) {
		// Relaxed, with the arms hanging at slightly different angles.
		target_wrist.z += side * 0.020;
	} else if (pose < 1.5) {
		// Folded arms.
		target_elbow = vec3(side * 0.190 * broad, 0.706, 0.070);
		target_wrist = vec3(-side * 0.084 * broad, 0.749 + side * 0.018, 0.123);
	} else if (pose < 3.5) {
		// Left or right hand resting on a hip.
		float hip_side = pose < 2.5 ? -1.0 : 1.0;
		if (side == hip_side) {
			target_elbow = vec3(side * 0.235 * broad, 0.720, 0.016);
			target_wrist = vec3(side * 0.132 * broad, 0.660, 0.068);
		}
	} else if (pose < 4.5) {
		// Both hands in pockets.
		target_elbow = vec3(side * 0.207 * broad, 0.712, 0.004);
		target_wrist = vec3(side * 0.103 * broad, 0.614, 0.087);
	} else if (pose < 5.5) {
		// Hands loosely clasped in front.
		target_elbow = vec3(side * 0.148 * broad, 0.704, 0.060);
		target_wrist = vec3(side * 0.018, 0.596 + side * 0.009, 0.128);
	} else if (pose < 6.5) {
		// Hands held behind the back.
		target_elbow = vec3(side * 0.174 * broad, 0.697, -0.061);
		target_wrist = vec3(side * 0.025, 0.603 + side * 0.009, -0.119);
	} else if (pose < 7.5) {
		// Thoughtful: one hand near the chin, the other relaxed.
		if (side > 0.0) {
			target_elbow = vec3(0.182 * broad, 0.802, 0.095);
			target_wrist = vec3(0.036, 0.995, 0.117);
		}
	} else if (pose < 8.5) {
		// A hand resting lightly over the chest.
		if (side < 0.0) {
			target_elbow = vec3(-0.196 * broad, 0.731, 0.069);
			target_wrist = vec3(0.020, 0.858, 0.110);
		}
	} else if (pose < 9.5) {
		// Small conversational gesture at waist height.
		if (side > 0.0) {
			target_elbow = vec3(0.193 * broad, 0.716, 0.036);
			target_wrist = vec3(0.242 * broad, 0.758, 0.201);
			target_wrist.y += sin(time * 0.91 + phase) * 0.012 * motion;
		}
	} else if (pose < 10.5) {
		// One hand behind the head, elbow raised to the side.
		if (side < 0.0) {
			target_elbow = vec3(-0.259 * broad, 0.938, -0.020);
			target_wrist = vec3(-0.067, 1.082, -0.071);
		}
	} else {
		// A small greeting, rather than a full-body cheer.
		if (side > 0.0) {
			target_elbow = vec3(0.234 * broad, 0.909, 0.025);
			target_wrist = vec3(0.227 * broad, 1.110, 0.079);
			target_wrist.x += sin(time * 1.15 + phase) * 0.011 * motion;
		}
	}
	target_elbow = mix(elbow, target_elbow, pose_strength);
	target_wrist = mix(wrist, target_wrist, pose_strength);
	vec3 upper = segment_point(point, shoulder, elbow, shoulder, target_elbow);
	vec3 lower = segment_point(point, elbow, wrist, target_elbow, target_wrist);
	vec3 upper_normal = align_limb(normal, normalize(elbow - shoulder), normalize(target_elbow - shoulder));
	vec3 lower_normal = align_limb(normal, normalize(wrist - elbow), normalize(target_wrist - target_elbow));
	point = mix(upper, lower, forearm);
	normal = normalize(mix(upper_normal, lower_normal, forearm));
}
