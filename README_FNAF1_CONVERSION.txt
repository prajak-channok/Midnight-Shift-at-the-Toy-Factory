FNAF1 Power + Doors conversion

This version keeps the original template's AnimatronicBase/TravellingAnimatronic hierarchy.
FnafAnimatronic extends TravellingAnimatronic so its inherited _animation_player is defined
and initialized from animation_player_path in each animatronic scene.

Mechanics:
- Two animatronics use left/right routes.
- Left/right doors and vent lights are used for defense/checking.
- Power drains over time, faster with doors closed and monitor active.
- Power reaching 0 forces both doors open.
- If an animatronic reaches the door while it is open, the night ends in game over.
- If the door stays closed during its attack check, the animatronic retreats.
- The night is won at 6 AM.
- Mask mechanics are not used by the new night logic.

Controls:
A = left door
D = right door
Z = left light
C = right light
SPACE = monitor

Typing cleanup:
New/modified locals and key state variables are explicitly typed to avoid Variant inference
issues, including wait_time, chance, marker, block_wait, drain, power, monitor_on, and
related state variables. Existing template code was left intact where it was not part of
the conversion.
