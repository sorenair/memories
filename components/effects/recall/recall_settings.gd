class_name RecallSettings
extends Resource
## Edit recall_settings.tres to tune discovery for every recallable component.
## Extra proximity reach beyond the component footprint, in world meters.
@export_range(0.0, 20.0, 0.1, "suffix:m") var proximity_distance: float = 3.5
