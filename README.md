# 🧸 Midnight Shift at the Toy Factory

A 3D first-person survival horror game built with Godot 4.7.

**[▶ Play in your browser](https://prajak-channok.github.io/Midnight-Shift-at-the-Toy-Factory/)** · **[Also on itch.io](https://inxpj.itch.io/midnight-shift-at-the-toy-factory)**

## About

**Genre:** 3D First-Person Survival · Resource Management · Supernatural Horror

**Inspired by:** Five Nights at Freddy's 1 (FNaF1)

## Story

Many years ago, WonderMold Inc., a famous toy factory, was destroyed by a large fire and had to close forever. The fire left behind an abandoned factory and many toys that were never moved out.

Years later, a nearby warehouse was still used to store the remaining goods. A new night guard was hired to watch over the warehouse from midnight until 6 AM.

But soon, strange things began to happen. Toys that should have stayed still started moving around the warehouse. Some even came out of the old factory.

Now, the guard must use security cameras, the hall lights, and the doors to stay safe until morning. But something from the past may still be hiding inside the abandoned factory.

## How to Play

You can't leave your seat. You can only look around, check the cameras, shine your light down the left and right halls, and close the doors.

- Move the mouse to the left or right edge of the screen to look around the office.
- Raise the monitor to watch the cameras and track where the toys are. Click a room on the map to switch cameras.
- Use the door lights to check the left and right halls, and close the door when a toy is standing there. A closed door holds a toy back for a few seconds before it retreats, but an open door lets it straight in.
- The monitor, the closed doors and (from Night 2) the lights all drain the battery, and the drain gets heavier every night. Keep them off when you don't need them.
- If the battery hits **0%** the doors open by themselves and the monitor shuts down, leaving you defenceless.
- Survive from **12:00 AM to 6:00 AM** (6 minutes real time, 1 minute per hour) to win the night. Beating a night unlocks the next one (5 nights in total).
- You lose if a toy reaches you.

## Controls

| Input | Action |
|:---:|--------|
| `A` | Left door |
| `D` | Right door |
| `Z` | Left light |
| `C` | Right light |
| `SPACE` | Raise / lower the monitor |
| Mouse (screen edges) | Look left / right |
| Left click | Press the in-office door and light buttons, and the on-screen monitor button |

The doors, lights and monitor can also be used with the mouse. Hover over or click the monitor button on screen to raise or lower it. The **FLEE THE SHIFT** button on the night screen abandons the night (progress isn't saved) and returns to the menu.

### Camera monitor

With the monitor raised, click a room on the map (CAM 1-11) to switch cameras. Two extra buttons appear on later nights:

- **PLAY AUDIO** (from Night 2): press it, then pick a room on the map to play a sound there. Some toys are drawn towards noise. The button needs time to recharge between uses.
- **WIND UP** (Nights 4-5): only shown while you are watching CAM 5. Hold it down to keep the toy there from running down.

The main menu also has a **Settings** panel (fullscreen and sound on/off).

## The Nights

Each night is harder than the last: the battery drains faster and the toys get more active. A short hint appears at the start of Nights 2 and 4.

| Night | What's new |
|:---:|---|
| 1 | The basics: doors, hall lights (free on this night) and the monitor. |
| 2 | Hall lights now drain the battery. PLAY AUDIO appears (recharge: 30 s). |
| 3 | The battery drains faster. PLAY AUDIO recharges in 25 s. |
| 4 | The Wound-Up Tin Soldier joins in, with WIND UP on CAM 5. PLAY AUDIO recharges in 20 s. |
| 5 | The heaviest drain of all. PLAY AUDIO recharges in 15 s. |

## Meet the Toys

- **Springy Clown** - roams the factory and heads for the **left** door. Close it while the clown is in the hall; a closed door holds it back for a few seconds before it retreats.
- **Porcelain Ballerina** - the same, but it comes for the **right** door.
- **Burned Plush-Bot** - also heads for the right door. It cannot move while a camera is looking at it in the Right Hall. Sound can lure it towards a room (PLAY AUDIO).
- **Wound-Up Tin Soldier** (Nights 4-5) - never leaves the staff room, but he runs down on his own. Keep winding him up from CAM 5, or your shift is over.

## Credits

**Based on** the open-source [fnaf-2-godot](https://github.com/bypell/fnaf-2-godot) example project by bypell (CC0 1.0), adapted into a FNaF1-style game with a new setting, new toys and new mechanics.

The 3D models, textures and images were generated with AI tools (apart from a few files inherited from the template). The sound effects, music, fonts and engine are listed in [credits.txt](credits.txt).

This is a fan-made student project, not affiliated with or endorsed by the creators of Five Nights at Freddy's.

## License

- **Source code** (GDScript files and project configuration): [MIT](LICENSE).
- **3D models, textures and images**: AI-generated and not licensed for reuse.
- **Third-party assets** (sounds, fonts, template files): each keeps its original license, see [credits.txt](credits.txt).
