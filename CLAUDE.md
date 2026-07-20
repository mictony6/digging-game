# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**"Sunk Cost"** — a first-person 3D mining game in Godot 4.6+ (Forward+ renderer, Jolt Physics). The player is a miner paying off debt to keep someone (Maria) in the hospital, descending into a cave each day to meet an escalating ore quota while managing tool durability, oxygen, and expenses.

## Godot Commands

There is no build/lint/test CLI for this project. Development happens entirely inside the Godot Editor. Open `project.godot` in Godot 4.6+.

- **Run game:** F5 (from editor) or click the Play button
- **Run current scene:** F6
- **Reload scripts:** Ctrl+Shift+F5

## Architecture

### Autoload Singletons (global access everywhere)

| Singleton | File | Responsibility |
|---|---|---|
| `QuotaManager` | `game/quota_manager.gd` | Daily ore quota, scaling (×1.25 on completion), bonuses |
| `PlayerData` | `game/player_data.gd` | Coins, health, oxygen vitals |
| `GlobalInput` | `game/global_input.gd` | F11 fullscreen, F1 cursor toggle |
| `ExpenseManager` | `game/expense_manager.gd` | End-of-day deductions (food, housing, hospital, tax, repair) |
| `DateManager` | `game/date_manager.gd` | Day counter, `end_day()` signal that triggers expense calculation |
| `PauseStateManager` | `game/pause_state_manager.gd` | Pause/resume state |
| `QuestManager` | `game/quest_manager.gd` | Quest lifecycle (`QuestState` enum: NOT_STARTED/ACTIVE/COMPLETED/FAILED) |

### State Machine

Generic state machine in `systems/state machine/`. `StateMachine.gd` holds the active state; states emit `finished(target_state_path, data)` to transition. Base classes: `State`, `PlayerState`, `ToolState`.

- **Player states** (`entities/player/states/`): Idle, Move, Sprint, Jump, Fall, Crouch, Climb, Swim, Vault, RidingMinecart
- **Tool states** (`game/tool_states/`): Idle, Walking, Mining — drive the mining loop and arm animation transitions (`travel_arm()`)
- **Turret states**: Idle, Alert, LockedIn, Attacking, CoolDown
- Each state implements `enter()`, `exit()`, `_input()`, `_process()`, `_physics_process()` as needed.

### Component Pattern

Entities are built by attaching reusable child components rather than deep inheritance:

| Component | File | Purpose |
|---|---|---|
| `HasHealth` | `systems/health/has_health.gd` | HP pool, damage, death signal |
| `IsMineable` | `systems/mineable/is_mineable.gd` | Receives mining hits; checks `tool_tier >= required_tool_tier` |
| `HasDrops` | `systems/mineable/has_drops.gd` | Loot table; spawns `PickupItem` on destruction |
| `IsKnockbacked` | `systems/physics/is_knockbacked.gd` | Impulse from explosions/hits |
| `HasOxygen` | `systems/oxygen/has_oxygen.gd` | Oxygen depletion; `LowOxygenArea` multiplies drain rate |
| `HasInventory` | `systems/inventory/has_inventory.gd` | Item storage; feeds crafting |
| `IsSelectable` | `systems/interaction/is_selectable.gd` | Interaction prompt, highlights on hover, emits `selected(_player, _tool)` |

### Tool & Mining Loop

`game/tool_manager.gd` drives the laser mining tool (`entities/laser_tool/LaserTool.tscn`), running the tool state machine above:
- RayCast3D detects hits on rocks; Area3D applies splash (100% primary, 25% nearby)
- Durability depletes while firing; repaired at day boundary
- Hit FX use a **5-pool** of particles (reused, not instantiated per hit)
- Upgrades: `tier` (unlocks harder rocks), `strength` (damage), `max_durability`; purchase counts persist on ToolManager (shop widgets are rebuilt per open)
- Visuals: `effects/beam.gd` (`LaserBeam`) — braided beam meshes curved to the target by `shaders/laser_beam.gdshader`, plus impact halo and flame particles; arm animations via an `AnimationTree` state machine, procedural weight/lag from `entities/player/arms_sway.gd`

`game/torch_manager.gd` (T key) raycasts forward and places a torch from inventory on the hit surface.

`entities/rocks/rock.gd` links to a `RockData` resource and updates the `damage` shader parameter (0–1) as the rock takes hits, driving the crack shader.

### Economy / Daily Cycle

1. Player mines → `QuotaManager.add_to_quota(value)`
2. Sell at Exchange → coins added, quota flag set
3. Sleep at Rest Point → `DateManager.end_day()` fires
4. `ExpenseManager.calculate_report()` deducts food (15), accommodation (30), hospital (80), tool repair (10), tax (10% gross), then adds quota bonus (`1000 × 1.5^quotas_completed` if met)
5. Quota scales: `required_quota *= 1.25` each day

### Shaders

Shaders live in `shaders/` (and some co-located with entities):

- **Rock crack shader** — triplanar damage cracks with emission; driven by `damage` instance parameter on each `MeshInstance3D`; reconstructs normal Z to avoid dark shading
- **`laser_beam.gdshader`** — mining beam; vertex-curves the mesh from the emitter to a `target_local` instance parameter with grow `progress` (see `effects/beam.gd`); `impact_halo.gdshader` renders the hit flash
- **`water.gdshader` / `water_ssr.gdshader`** — water surface with depth fade and screen-space reflections
- **`DarknessEffect.gdshader`** — fullscreen ColorRect effect (`systems/Darkness.gd` feeds camera basis/FOV each frame)

Use `set_instance_shader_parameter()` on the `MeshInstance3D` node directly to set per-instance shader parameters (no `duplicate()` needed). Use `ALPHA_HASH_SCALE` built-in for alpha hashing rather than implementing manually.

### Scene Hierarchy (Main.tscn)

```
Main (Node3D)
├── WorldEnvironment / DirectionalLight3D
├── LevelLoader
│   └── OverWorld  ← all gameplay content: cave, elevator, exchange, shop, rocks, enemies (turret, crawler)
├── Player (CharacterBody3D)
├── CanvasLayer (layer 0) ← DeathScreen, EODUI, InventoryUI, StartMenu
└── HudLayer (layer 2) ← ShopUI, HUD (PlayerHUD)
```

VoxelGI is precomputed (`GI/test.VoxelGI_data.res`). Item lights on pickups use sprite + distance fade instead of VoxelGI to avoid rebaking.

### Data Resources

Game content is defined as Godot Resources in `data/`:

- `data/items/` — `ItemData` (Bomb, Torch, Iron, Coal, Gunpowder, Stick)
- `data/rocks/` — `RockData` (drop tables, required tier, value)
- `data/tools/` — `ToolData` (tier, strength, durability)
- `data/crafting/` — `CraftingRecipe` (Bomb, Torch recipes)
- `data/shop/` — `ShopItemEntry`, `UpgradeEntry`
- `data/questing/` — `QuestData` (id, title, description, state, rewards), `QuestReward`
- `data/environment/` — environment/sky settings resources

### Interaction System

`systems/interaction/object_selector.gd` fires a RayCast each frame looking for nodes in the `"Selectable"` group. On hover it applies an outline material; on click it calls the `IsSelectable` component which emits `selected(player, tool)`.

### Crafting

`systems/crafting/crafting_manager.gd` polls recipes on a timer. When the player's inventory contains all required ingredients, it auto-crafts and emits `item_crafted` for UI toast feedback.

## Physics Layers

Jolt Physics is the engine. Collision layers (from project.godot): Player, Rocks, Environment, Bomb, Selectable, Props, Turrets, Interactables. Raycasts (e.g., bomb throw) filter by layer mask.

## Key Input Actions

`action` (LMB) = mine/interact · `secondary_action` (RMB) · `pickup` (E) · `inventory_toggle` (Tab) · `throw` (R) · `crouch` (C) · `sprint` (Shift) · `torch` (T)
