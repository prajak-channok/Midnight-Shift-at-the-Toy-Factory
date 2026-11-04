---
name: comment-style
description: Write or edit code comments in this project's GDScript in the owner's style (Thai first, short English in parentheses, only at non-obvious points). Use whenever adding, translating or reviewing comments in .gd files, unless the style was turned off with `/comment-style off`.
argument-hint: "[on|off|status]"
---

# Comment style (GDScript, Midnight Shift at the Toy Factory)

## On / off

Arguments given to this skill: `$ARGUMENTS`

- No argument or `on`: apply the rules below to every comment you write or edit for the rest of this session. Reply with one short line confirming it is on.
- `off`: stop applying this style for the rest of this session (write comments the normal way, or none). Reply with one short line confirming it is off, then ignore the rest of this file until `on` is given again.
- `status`: say whether the style is currently on or off in this session.
- The switch lasts for the current session only. For a permanent "manual only" mode, set `disable-model-invocation: true` in the frontmatter above, so the skill runs only when `/comment-style` is typed.

## Format

- Thai sentence first, then a concise English translation in parentheses on the same line.
- One line only.
- `##` (doc comment) for declarations: trailing on `@export` / `var` / `const` lines, or directly above a function. Godot shows these as tooltips.
- Plain `#` for comments inside function bodies (trailing or on their own line).

```gdscript
@export var cam_manager: CameraManager ## สำหรับทำจอซ่าห์ (For lose communication)
const WIND_RATE := 2.5 ## สเกลการเพิ่มของคูลดาวน์ (Cooldown increase rate)

## ย้ายตำแหน่งของโมเดล และเล่นอนิเมชันที่กำหนดไว้ (Move the model and play its assigned animation)
func apply_position_to_body(pos: AnimatronicPosition) -> void:
	...
	if ai_level <= 0: # หุ่นตัวนี้ใช้ AI level เป็นแค่สวิตช์เปิด/ปิดตามคืน (AI level is only an on/off switch per night)
```

## What to comment

Comment intent and game rules, written from the game designer's point of view (what happens in the game, not how the code does it).

- Designer-facing `@export` fields: what to wire in the inspector.
- State flags that control a loop or mode.
- Hooks that subclasses override (what kind of condition belongs there).
- Branches whose reason isn't obvious from the code.
- Magic numbers and tuning constants: what the number means.
- Subtle flags and mechanics (lure, freeze, forces_monitor_down, per-night switches).

## What NOT to comment

- Obvious functions (`start_ai`, `stop_ai`, `_ready`, `_process`, getters) and anything the name already says.
- No class header doc blocks, no multi-line paragraphs, no `[br]` / `[param]` BBCode.
- Don't reference the current task, a fix, or "added for X".
- Naming a class or caller is allowed when it makes the intent clear (e.g. "เช่น Burned Plush Bot"), but keep it rare.

## Wording

- Common openers: `สำหรับ…` (for…, states intent), or a verb: `ย้าย…`, `วาง…`, `เช็คว่า…`, `สุ่ม…`, `ส่งสัญญาณให้ … รู้ว่า…`, `ถ้า… จะ…`.
- Code identifiers and engine terms stay English (`night`, `AI level`, `graph`). Game terms are transliterated Thai: จัมป์สแกร์, คูลดาวน์, อนิเมชัน, รีเทิร์น, โหนด.
- Project term: `จอซ่าห์` = the camera monitor losing communication (`lose_communication`). Use it consistently.
- Keep it short: one line, no redundant words (prefer "สุ่มเวลารอ แล้วทอยว่าจะเดินตามระดับ AI" over "สุ่มเวลาในการที่จะสุ่มว่า…").
- The English gloss is a faithful short translation of the Thai, not an extra explanation.

## Rules when editing

1. Never rewrite or "correct" the owner's Thai wording unless asked. Only append the English gloss.
2. Existing English-only comments in project files should get a Thai lead in the same format, only when asked.
3. Add a comment only where it passes the "non-obvious" test above. When in doubt, leave it out.
