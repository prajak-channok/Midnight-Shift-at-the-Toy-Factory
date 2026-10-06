# AI Architecture — FNaF-Style Animatronic System

เอกสารนี้เป็น Architecture / Prompt สำหรับสร้างระบบ AI ของ Animatronic ในเกมแนว FNaF โดยเริ่มต้นรองรับ 4 ตัว: **Bonnie, Chica, Freddy, Foxy**

## 1. แนวคิดหลัก

อย่าบังคับให้ Animatronic ทุกตัวใช้ Movement Logic แบบเดียวกัน เพราะพฤติกรรมต่างกัน แต่ควรแชร์ Infrastructure ที่เหมาะสม เช่น:

- Animatronic Position
- Movement Opportunity / Timer
- State
- Animation
- Door State
- Jumpscare / Game Over Event
- Return Position
- การสื่อสารกับ Night / Game Manager

แบ่งเป็น:

```text
Shared Infrastructure
        +
Character-Specific Logic
```

หลักสำคัญคือ **แชร์ระบบพื้นฐาน แต่ไม่แชร์กฎการตัดสินใจที่ไม่เหมือนกัน**

---

## 2. Position System

มีระบบ Position กลางสำหรับระบุตำแหน่งที่ Animatronic สามารถอยู่ได้ เช่น:

```text
Stage
Dining Area
Backstage
West Hall
East Hall
West Hall Corner
East Hall Corner
Left Door
Right Door
Pirate Cove
4B
Office
```

แต่ไม่ใช่ว่าทุกตัวจะใช้ทุก Position

ตัวอย่างแนวคิด:

```text
Bonnie:
Stage → ... → Left Door

Chica:
Stage → ... → Right Door

Freddy:
Stage → ... → 4B

Foxy:
Pirate Cove → Attack Run → Left Door
```

---

## 3. Movement Graph

สำหรับ Animatronic ที่เดินตามเส้นทางปกติ ให้ใช้ Graph จำกัด Destination

Graph ตอบคำถาม:

> จาก Position ปัจจุบัน ตัวละครตัวนี้มีสิทธิ์ไป Position ไหนได้บ้าง?

ส่วน AI Chance ตอบ:

> ใน Movement Opportunity ครั้งนี้ ตัวละครจะเคลื่อนที่หรือไม่?

ตัวอย่าง:

```text
Movement Opportunity
        ↓
สุ่ม AI Chance
        ↓
สำเร็จ?
 ├── No  → อยู่ที่เดิม
 └── Yes → เลือก Destination จาก Graph
```

ตัวเลขอย่าง `70%` เป็นเพียง **ตัวอย่างสำหรับ Design** ไม่ใช่ค่าที่ต้องถือว่าเป็นค่าของ FNaF1

ตัวอย่าง:

```text
Hall → Corner = 70%
Corner → Door = 70%
```

---

## 4. Special Position

บางตำแหน่งไม่ควรใช้ Graph แบบปกติ เช่น Door ของ Bonnie/Chica และ 4B ของ Freddy

จึงแบ่งเป็น:

```text
Normal Position
Special Position
```

Normal Position ใช้ Graph ปกติ

Special Position เปลี่ยนไปใช้ Logic เฉพาะของตัวละคร

---

# 5. Bonnie

Bonnie ใช้:

```text
Normal Movement Graph
        ↓
Left Door
        ↓
Special Door Logic
```

เมื่อถึง Left Door:

```text
Movement Opportunity
        ↓
พยายามเข้า Office
        ↓
ตรวจ Left Door
 ┌───────────────┴───────────────┐
เปิด                              ปิด
 ↓                                 ↓
Office / Jumpscare             Return Position
                                  ↓
                              กลับ Normal AI
```

ดังนั้น Door ไม่ควรมี Destination แบบสุ่มหลายตัวอีก แต่เป็น Special Path ที่ชัดเจน:

```text
Left Door → Office
```

ตัวอย่าง Configuration:

```text
Bonnie
- Normal Graph: BonnieGraph
- Special Position: LeftDoor
- Target: Office
- Block Condition: LeftDoorClosed
- Blocked Position: [กำหนดค่า]
```

---

# 6. Chica

Chica ใช้ Architecture เดียวกับ Bonnie แต่เป็นฝั่งขวา:

```text
Normal Movement Graph
        ↓
Right Door
        ↓
Special Door Logic
```

เมื่อถึง Right Door:

```text
Movement Opportunity
        ↓
พยายามเข้า Office
        ↓
ตรวจ Right Door
 ┌───────────────┴───────────────┐
เปิด                              ปิด
 ↓                                 ↓
Office / Jumpscare             Return Position
                                  ↓
                              กลับ Normal AI
```

Configuration:

```text
Chica
- Normal Graph: ChicaGraph
- Special Position: RightDoor
- Target: Office
- Block Condition: RightDoorClosed
- Blocked Position: [กำหนดค่า]
```

---

# 7. Freddy

Freddy ใช้แนวคิด Graph แต่ Position ปลายทางเป็น `4B` ไม่ใช่ Door:

```text
Normal Movement Graph
        ↓
...
        ↓
4B
        ↓
Special Freddy Logic
```

เมื่ออยู่ 4B ให้ตรวจ Stall:

```text
Movement Opportunity
        ↓
อยู่ 4B?
        ↓
ตรวจ Stall
 ┌───────────────┴───────────────┐
Stall สำเร็จ                  ไม่ Stall
 ↓                               ↓
อยู่ 4B                       พยายามเข้า Office
                                 ↓
                           ตรวจเงื่อนไข
```

ควรแยก:

```text
Freddy สามารถเคลื่อนที่ได้
```

ออกจาก:

```text
Freddy สามารถผ่าน Special State 4B และเข้า Office ได้
```

ตัวอย่าง Configuration:

```text
Freddy
- Normal Graph: FreddyGraph
- Special Position: 4B
- Target: Office
- Stall Condition: [กำหนดตามระบบกล้อง]
- Blocked Position: [กำหนดตาม Design]
```

รายละเอียด Stall และผลเมื่อ Freddy ถูกขวางควรเป็น Logic เฉพาะของ Freddy ไม่ควรยัดเข้า Normal Graph

---

# 8. Foxy

**Foxy ไม่ควรถูกบังคับให้ใช้ Movement Graph แบบเดียวกับ Bonnie / Chica**

Bonnie / Chica:

```text
Position
   ↓
Movement Opportunity
   ↓
Graph Destination
```

Foxy:

```text
Pirate Cove
      ↓
Cove State / Attack Readiness
      ↓
Attack Trigger
      ↓
Attack Run
      ↓
Left Door
      ↓
ตรวจ Door
```

ดังนั้น Foxy ควรใช้ **State Machine / Attack Sequence** เป็นหลัก

ไม่ควรทำเป็น:

```text
Pirate Cove
   ↓
Hall
   ↓
Corner
   ↓
Left Door
```

เพราะจะทำให้ Foxy มีพฤติกรรมเหมือน Animatronic ที่เดินตาม Graph ปกติ

ตัวอย่าง State:

```text
FoxyState
├── HIDDEN
├── WATCHING
├── READY
├── RUNNING
├── AT_LEFT_DOOR
├── HIT_DOOR
└── RETURN_TO_COVE
```

ชื่อ State สามารถเปลี่ยนได้ตาม Implementation จริง

---

# 9. Foxy Attack Sequence

แนวคิด:

```text
Pirate Cove
     ↓
ตรวจ/สะสมสถานะ
     ↓
พร้อมโจมตี
     ↓
เริ่ม Attack Run
     ↓
Left Door
     ↓
ตรวจ Door
 ┌───────────────┴───────────────┐
เปิด                              ปิด
 ↓                                 ↓
Office / Jumpscare             Door Hit
                                  ↓
                              Power Loss
                                  ↓
                          Return to Pirate Cove
```

Foxy จึงเป็น **Special Behavior** มากกว่า Normal Movement Graph

---

# 10. Architecture ของทั้ง 4 ตัว

```text
BONNIE
Normal Graph
    ↓
Left Door
    ↓
Door Special Logic
    ├── Open   → Office
    └── Closed → Return Position


CHICA
Normal Graph
    ↓
Right Door
    ↓
Door Special Logic
    ├── Open   → Office
    └── Closed → Return Position


FREDDY
Normal Graph
    ↓
4B
    ↓
Freddy Special Logic
    ├── Stall    → Stay / Wait
    └── No Stall → Office Logic


FOXY
Pirate Cove State
    ↓
Attack Sequence
    ↓
Left Door
    ├── Open   → Office
    └── Closed → Door Hit → Power Loss → Cove
```

---

# 11. Class Architecture

แนวคิดหนึ่งสำหรับ Godot:

```text
Animatronic
│
├── TravellingAnimatronic
│   │
│   ├── Bonnie
│   │   └── Movement Graph + Door State
│   │
│   ├── Chica
│   │   └── Movement Graph + Door State
│   │
│   └── Freddy
│       └── Movement Graph + 4B Stall State
│
└── Foxy
    └── Attack State Machine
```

`TravellingAnimatronic` รับผิดชอบสิ่งทั่วไป เช่น:

- Current Position
- Movement Opportunity
- Position System
- Move To Position
- Animation
- AI Level
- Active / Inactive

Child Class รับผิดชอบกฎเฉพาะของตัวเอง

---

# 12. แยก Movement กับ Decision

ควรคิดระบบเป็น 3 ชั้น:

```text
[1] Movement System
    "ตัวละครอยู่ที่ไหน?"

        ↓

[2] Decision System
    "ถึงเวลาเคลื่อนที่หรือยัง?
     และควรทำอะไร?"

        ↓

[3] Special Behavior
    "ถ้าอยู่ Door / 4B / Attack State
     ต้องใช้กฎพิเศษอะไร?"
```

ตัวอย่าง Bonnie:

```text
Movement
    → Bonnie อยู่ Left Door

Decision
    → Movement Opportunity เกิดขึ้น

Special Behavior
    → ตรวจ Door
       → Open = Office
       → Closed = Return Position
```

ตัวอย่าง Foxy:

```text
Movement
    → Foxy อยู่ Pirate Cove

Decision
    → Attack Trigger เกิดขึ้น

Special Behavior
    → เริ่ม Run
       → ถึง Left Door
       → ตรวจ Door
```

---

# 13. หลักการที่ต้องรักษา

### 13.1 Shared System, Different Rules

ใช้ Infrastructure ร่วมกัน แต่ไม่บังคับให้ทุกตัวใช้ Behavior เหมือนกัน

### 13.2 Graph จำกัด "ไปไหนได้"

Graph จำกัด Destination ที่เป็นไปได้

ไม่ได้ตัดสินทั้งหมดว่า Animatronic จะเคลื่อนที่หรือไม่

### 13.3 AI Chance ตัดสิน "จะขยับหรือไม่"

```text
Movement Opportunity
        ↓
AI Chance
        ↓
Move / Stay
```

### 13.4 Special Position เปลี่ยนกฎ

เมื่อถึง Door หรือ 4B ไม่จำเป็นต้องใช้ Graph แบบปกติต่อ

### 13.5 Foxy เป็น Special Behavior

Foxy ใช้ Attack Sequence / State Machine มากกว่า Normal Movement Graph

### 13.6 Configuration แยกจาก Logic

ค่าต่าง ๆ เช่น:

```text
Blocked Position
Return Position
Target Position
Special Position
AI Chance
Movement Interval
```

ควรปรับได้โดยไม่ต้องแก้ Core Movement System

---

# 14. สิ่งที่ควรหลีกเลี่ยง

ไม่ควรสร้าง Graph เดียวให้ทุกตัวแล้วบังคับให้ทุกตัวใช้กฎเดียวกัน

และหลีกเลี่ยง Character-Specific Logic กระจายไปทั่วระบบ เช่น:

```gdscript
if animatronic.name == "Bonnie":
    ...
elif animatronic.name == "Chica":
    ...
elif animatronic.name == "Freddy":
    ...
elif animatronic.name == "Foxy":
    ...
```

ใน `Night`, `Player`, `CameraManager`, `Door` ฯลฯ

ควรให้แต่ละ Animatronic รับผิดชอบ Behavior ของตัวเอง

---

# 15. เป้าหมายของ Implementation

การเพิ่มหรือแก้ Animatronic ควรมีขั้นตอนประมาณ:

```text
1. กำหนด Position
2. กำหนด Graph หรือ State Machine
3. กำหนด AI / Movement Rules
4. กำหนด Special State ถ้ามี
5. กำหนด Target / Return Position
6. เชื่อม Door / Camera / Night Events
```

ไม่ควรต้องแก้ Core System จำนวนมากเพียงเพราะเพิ่ม Animatronic ตัวใหม่

---

# 16. Prompt สำหรับใช้สร้างระบบ

> สร้างระบบ AI Animatronic สำหรับเกม 3D First-Person Survival แนว FNaF ด้วย Godot โดยรองรับ Bonnie, Chica, Freddy และ Foxy
>
> ออกแบบระบบแบบ Modular และใช้ Shared Infrastructure เท่าที่เหมาะสม โดยมี Position, Movement Opportunity, AI Chance, State, Door Check, Animation และ Jumpscare/Game Over Event เป็นส่วนกลาง
>
> Bonnie และ Chica ใช้ Movement Graph สำหรับการเคลื่อนที่ปกติ เมื่อถึง Door ให้เปลี่ยนเป็น Special Door State ซึ่งมี Destination หลักเป็น Office หากประตูเปิดให้เข้าสู่ Office/Game Over และหากประตูปิดให้ย้ายกลับไปยัง Return Position ที่กำหนด แล้วกลับเข้าสู่ Normal Movement
>
> Freddy ใช้ Movement Graph แต่ Position พิเศษสุดท้ายคือ 4B เมื่ออยู่ 4B ให้ใช้ Special Freddy State ซึ่งตรวจ Stall Condition ก่อนตัดสินใจเข้า Office โดย Stall Logic ต้องแยกจาก Normal Movement Graph
>
> Foxy ใช้ Logic แยกจาก Bonnie, Chica และ Freddy โดยใช้ State Machine หรือ Attack Sequence เริ่มจาก Pirate Cove เมื่อเข้าเงื่อนไขโจมตีให้เริ่ม Attack Run ไปยัง Left Door จากนั้นตรวจประตู หากเปิดให้เข้าสู่ Office/Game Over หากปิดให้เกิด Door Hit, จัดการ Power Loss ตามกติกา และกลับ Pirate Cove
>
> หลีกเลี่ยงการเขียน Character-Specific Logic กระจาย เช่น `if name == "Bonnie"` ในระบบกลาง ให้แต่ละ Animatronic รับผิดชอบ Behavior ของตัวเอง และใช้ Base Class / Component / State ที่เหมาะสมเพื่อ reuse code
>
> แยกหน้าที่:
>
> - Position System = ตัวละครอยู่ที่ไหน
> - Movement Graph = ตัวละครสามารถไปที่ไหน
> - AI Chance = ตัวละครจะเคลื่อนที่หรือไม่
> - Special State = เมื่ออยู่ตำแหน่งพิเศษต้องทำอะไร
> - Door System = ประตูเปิดหรือปิด
> - Power System = จัดการการใช้พลังงาน
> - Night/Game Manager = จัดการเวลา, Game Over และ Win Condition
>
> ต้องออกแบบให้สามารถปรับ Position, Graph, AI Chance, Return Position, Special State และ Target ได้จาก Configuration โดยไม่ต้องแก้ Core Movement System ทุกครั้ง
>
> ก่อนเขียนโค้ด ให้แสดง Architecture, Class Responsibility, State Flow และ Data Flow ก่อน จากนั้นจึงค่อย Implement ทีละส่วน

---

## หมายเหตุ

ตัวเลข AI Chance, Movement Interval และรายละเอียดเฉพาะของ FNaF1 **ยังไม่ควรถูก hard-code จากเอกสารนี้** ให้ถือเป็นค่าที่ปรับได้ใน Configuration ก่อน แล้วจึงกำหนดค่าจริงตาม Design ของเกม
