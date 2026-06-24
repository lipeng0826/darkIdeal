# 暗影深渊 — 代码导读（小白版）

> 给没做过游戏开发的同学看的。不用一次读完，遇到问题时当字典查。

---

## 一、这是个什么项目？

- **引擎**：Godot 4.7  
- **类型**：竖屏挂机 RPG（720×1280）  
- **入口场景**：`scenes/main.tscn` — 打开游戏就跑这个  
- **语言**：GDScript（像 Python 的脚本语言）

一句话：**一个场景 + 五个底部 Tab + 后台自动战斗**。

---

## 二、文件夹是干嘛的？

```
godotGame2/
├── scenes/          # 场景文件（界面布局，.tscn）
├── scripts/         # 所有逻辑代码（.gd）
│   ├── autoload/    # 全局单例（开机自动加载）
│   ├── systems/     # 游戏子系统（技能、宠物、波次…）
│   └── ui/          # 界面相关
├── data/            # JSON 配置表（等级曲线、世界观…）
├── assets/          # 图片、音效
└── docs/            # 设计文档（你现在看的也在 docs/）
```

---

## 三、五个「开机就有的」全局脚本（Autoload）

在 `project.godot` 里注册，**任何地方都能直接写名字调用**：

| 名字 | 文件 | 干什么 |
|------|------|--------|
| **DataManager** | `data_manager.gd` | 装备模板、区域、Boss、任务等**静态配置** |
| **ProgressionManager** | `progression_manager.gd` | 等级段、掉率、养成解锁（读 `data/*.json`） |
| **LoreManager** | `lore_manager.gd` | 万界裂隙世界观、穿越文案 |
| **SaveManager** | `save_manager.gd` | 存档读写（`user://shadow_abyss_save.json`） |
| **GameManager** | `game_manager.gd` | **核心**：战斗、升级、装备、金币 |
| **AudioManager** | `audio_manager.gd` | 音效播放 |

### 存档长什么样？

`SaveManager.create_new_save()` 里定义了初始结构，核心字段：

```json
{
  "player": { "level", "exp", "gold", "gems" },
  "combat": { "atk", "def", "max_hp", "crit" ... },
  "equipment": { "0"~"5": 六部位装备或 null },
  "inventory": [ 背包装备数组 ],
  "skills": { "levels", "equipped" },
  "zone": { "current", "unlocked" }
}
```

改存档结构时，记得在 `SaveManager._normalize_loaded_data` 里做**老存档兼容**。

---

## 四、游戏怎么跑起来？（启动流程）

```
main.tscn 加载
    ↓
GameManager._ready()
    ├─ 创建子系统：SkillSystem、PetSystem、BattleWaveController…
    ├─ SaveManager.load_game() 或 create_new_save()
    ├─ LoreManager 开场叙事
    └─ _start_next_wave() 开始第一波怪
    ↓
main_ui.gd 显示战斗界面、连接信号
```

---

## 五、战斗是怎么转的？（最重要）

### 5.1 两个「心跳」

每帧 `GameManager._process` 里：

1. **`_process_battle(delta)`** — 普攻计时、怪物反击  
2. **`SkillSystem._process(delta)`** — 技能 CD、自动放技能

两者**并行**，互不阻塞（修复后普攻不会因为大招动画卡住）。

### 5.2 波次战斗（平时挂机）

```
BattleWaveController.start_wave()
    → 生成 3~5 只怪
    → 玩家每 1.2 秒 _player_attack_enemy() 普攻
    → SkillSystem 自动放装备的技能
    → 怪全死 → wave_cleared → 战利品弹窗 → 下一波
```

关键文件：

| 文件 | 职责 |
|------|------|
| `game_manager.gd` | 伤害计算、信号、Boss 战 |
| `battle_wave_controller.gd` | 多怪列表、前排目标、波次结束 |
| `skill_system.gd` | 11 个技能定义 + 自动释放 |
| `main_ui.gd` | 角色/怪物**动画**、飘字、技能特效 |

### 5.3 信号（模块之间传话）

Godot 用 `signal` 解耦。战斗相关：

| 信号 | 谁发 | 谁听 | 含义 |
|------|------|------|------|
| `combat_player_attack` | GameManager | main_ui | **只有普攻** — 播挥剑动画 |
| `combat_player_hit` | GameManager | （保留） | 命中事件 |
| `damage_popup` | GameManager | main_ui | 飘伤害数字 |
| `skill_cast` | SkillSystem | main_ui | 技能特效（横扫、粒子） |
| `wave_cleared` | BattleWaveController | GameManager | 一波结束 |

> **曾出现的 Bug**：技能伤害也触发普攻动画，大招 tween 被技能 tween 打断后 `_player_atk_anim_playing` 永远为 true → 普攻动画/待机卡死。  
> **修法**：普攻动画只跟 `combat_player_attack`；技能用 `play_skill_cast_sequence()`。

---

## 六、界面（main_ui.gd）

最大的 UI 脚本，负责：

- 底部 5 Tab：战斗 / 角色 / 冒险 / 工坊 / 更多  
- 战斗区：玩家精灵、怪物、Boss、技能栏、飘字  
- 子面板：装备、技能、地图、锻造…

### Tab 与构建函数

| Tab | 函数 |
|-----|------|
| 0 战斗 | 场景里直接摆好 |
| 1 角色 | `_build_equipment()`、`_build_skills()`… |
| 2 冒险 | `_build_route_map()` |
| 3 工坊 | `_build_craft()`、强化 |
| 4 更多 | 任务、商店、成就 |

切换 Tab 时 `_switch_tab()` → 清空 `item_list` → 调对应 `_build_*`。

---

## 七、装备与背包

### 数据流

```
怪死掉 → GameManager 随机 generate_item()
    → _add_to_inventory()
    → （可选）auto_equip 自动换装
    → item_obtained 信号
```

### 相关文件

| 文件 | 职责 |
|------|------|
| `data_manager.gd` | `generate_item()` 随机属性 |
| `game_manager.gd` | `equip_item` / `unequip_item` / `_recalculate_stats` |
| `inventory_utils.gd` | 背包排序、战力对比 |
| `equip_item_slot.gd` | 格子 UI（品质边框、+战力角标） |
| `equip_tooltip.gd` | 悬停提示（对比已装备） |
| `equip_compare_dialog.gd` | 双击背包装备 → 对比弹窗 |
| `enhance_system.gd` | 强化、附魔、宝石 |

### 玩家操作

- **悬停**：看属性 + 与已装备对比  
- **双击背包**：对比弹窗 → 确认装备  
- **双击已装备**：卸下回背包  
- **背包排序**：战力 / 品质 / 等级 / 部位  

战力公式：`DataManager.item_power()` — 所有属性值相加（简化版）。

---

## 八、配置表（data/）

| 文件 | 内容 |
|------|------|
| `balance_curves.json` | 经验、等级段掉率 |
| `progression_systems.json` | 几级解锁宝石/坐骑等 |
| `multiverse_lore.json` | 十界穿越文案 |
| `synthesis_catalog.json` | 合成配方（规划中） |

改 JSON 后**重启游戏**生效，不用改代码。

---

## 九、想加功能时去哪改？

| 我想… | 去改… |
|--------|--------|
| 新怪物/新区域 | `data_manager.gd` → `ZONES` |
| 新技能 | `skill_system.gd` → `SKILLS` + `_cast_skill` 分支 |
| 掉率/升级速度 | `data/balance_curves.json` |
| 战斗飘字样式 | `damage_popup_layer.gd` |
| 新 Tab 页面 | `main_ui.gd` 加 `_build_xxx` |
| 世界观台词 | `data/multiverse_lore.json` |
| 残片主线（规划） | 见 `docs/HORCRUX_LOOP.md` |

---

## 十、常用 GDScript 概念（30 秒版）

```gdscript
extends Node          # 继承 Godot 节点类型
signal my_signal      # 定义信号
func _ready():        # 节点进场景时调用一次
func _process(delta):  # 每帧调用，delta = 距上一帧秒数
var hp := 100         # 变量
const MAX := 10       # 常量
if x > 0:             # 条件
for i in arr:         # 循环
GameManager.add_gold(5)  # 调 Autoload
my_signal.emit(1)     # 发信号
my_signal.connect(func(x): print(x))  # 监听信号
```

---

## 十一、调试建议

1. **看 Output 面板** — `push_error` 和报错栈  
2. **战斗不对** — 在 `game_manager._process_battle` 打 `print(attack_timer)`  
3. **装备没装上** — 查 `equip_item` 是否找到 `uid`  
4. **存档坏了** — 删 `user://shadow_abyss_save.json` 开新档  
5. **改完 Autoload** — 需重启 Godot 或重新运行场景  

---

## 十二、文档索引

| 文档 | 内容 |
|------|------|
| [GAME_FEATURES.md](GAME_FEATURES.md) | 功能清单 |
| [MULTIVERSE_LORE.md](MULTIVERSE_LORE.md) | 万界裂隙世界观 |
| [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) | 等级段养成 |
| [HORCRUX_LOOP.md](HORCRUX_LOOP.md) | 界锚残片主线（规划） |
| [OPTIMIZATION_PLAN.md](OPTIMIZATION_PLAN.md) | 优化路线图 |

---

## 十三、脚本清单（31 个）

### autoload/（全局）
- `game_manager.gd` — 战斗 + 养成核心  
- `data_manager.gd` — 静态数据  
- `save_manager.gd` — 存档  
- `progression_manager.gd` — 等级段 JSON  
- `lore_manager.gd` — 叙事  
- `audio_manager.gd` — 音效  

### systems/（逻辑子系统）
- `skill_system.gd` — 技能 + 天赋  
- `battle_wave_controller.gd` — 波次多怪  
- `pet_system.gd` — 宠物  
- `enhance_system.gd` — 强化附魔宝石  
- `craft_system.gd` — 锻造  
- `tower_system.gd` — 深渊塔  
- `quest_system.gd` — 任务  
- `achievement_system.gd` — 成就转生  

### ui/（界面）
- `main_ui.gd` — **主界面总控**（2000+ 行，改前先搜函数名）  
- `player_visual.gd` — 主角动画  
- `battle_enemy_unit.gd` — 怪物单位  
- `equip_item_slot.gd` / `equip_tooltip.gd` / `equip_compare_dialog.gd` — 装备 UI  
- `inventory_utils.gd` — 背包工具  
- `battle_skill_bar.gd` — 技能 CD 条  
- `damage_popup_layer.gd` — 伤害飘字  
- `loot_dialog.gd` — 战利品弹窗  
- `adventure_map_view.gd` — 世界地图  
- 其他：`theme_config.gd`、`asset_registry.gd`、`nav_tab_button.gd`…  

---

*最后更新：战斗普攻/技能动画分离、背包排序与战力对比*
