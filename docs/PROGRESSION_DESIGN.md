# 养成系统设计 — 等级段解锁路线

> 对标御龙在天 / QQ三国：**升到某个等级段 → 解锁系统 → 刷材料 → 合成加成物件**  
> 数据外置在 `data/` 目录，调数值改 JSON，不改代码。

---

## 一、核心设计模式

```
等级提升
  ↓
进入新等级段（每10级）
  ↓
解锁新养成系统（装备/宝石/宠物/坐骑…）
  ↓
战斗掉落对应材料
  ↓
工坊合成 / 镶嵌 / 强化
  ↓
战力提升 → 推新区域/Boss
```

这和御龙在天、QQ三国的节奏一致：**不是一开始全开放**，而是每 10 级左右给玩家一个新目标。

---

## 二、等级段与解锁表

| 等级段 | 阶段名 | 解锁系统 | 状态 |
|--------|--------|----------|------|
| 1-10 | 初入暗影 | 装备 | ✅ 已实现 |
| 10+ | 墓穴试炼 | 暗影锻造 | ✅ 已实现 |
| 15+ | — | 技能奥术 | ✅ 已实现 |
| 20+ | 影域征途 | 天赋脉络、灵契宠物 | ✅ 已实现 |
| 25+ | — | 装备强化 | ✅ 已实现 |
| 30+ | 深渊裂隙 | 深渊宝石 | 🔶 部分 |
| 35+ | — | 诅咒附魔 | ✅ 已实现 |
| 40+ | 王座之路 | 暗影坐骑 | 📋 规划中 |
| 45+ | — | 深渊塔 | ✅ 已实现 |
| 50+ | 虚空前哨 | 噬魂八阵、轮回转生 | 🔶 转生已实现 |
| 55+ | — | 深渊灵兽 | 📋 规划中 |
| 60+ | 灭世序曲 | 虚眼神识（元神） | 📋 规划中 |
| 65+ | — | 灵魄结晶 | 📋 规划中 |
| 70+ | 终焉边缘 | 暗影符箓 | 📋 规划中 |
| 75+ | — | 堕天翼 | 📋 规划中 |
| 80+ | 永恒深渊 | 灭世奥义 | 📋 规划中 |
| 90+ | 轮回之巅 | 深渊天书 | 📋 规划中 |

完整配置见 [`data/progression_systems.json`](../data/progression_systems.json)。

---

## 三、数据文件说明

| 文件 | 用途 |
|------|------|
| `data/balance_curves.json` | 经验公式、10个等级段、掉率、保底、奖励倍率 |
| `data/progression_systems.json` | 19个养成系统解锁等级、描述、对标名 |
| `data/synthesis_catalog.json` | 宝石/坐骑/八阵/符咒/翅膀/天书的分档合成配方 |

### 经验曲线（前期更快）

```
exp_needed = 55 × lv^1.42 × (1 + lv × 0.035)
```

| 等级 | 约需经验 | 目标升级时间 |
|------|----------|--------------|
| 1→2 | ~60 | ~3.5 分钟 |
| 5→6 | ~350 | ~3.5 分钟 |
| 10→11 | ~900 | 进入新阶段 |
| 20→21 | ~2800 | ~5 分钟 |

### 掉落（按等级段）

| 等级段 | 装备掉率 | 材料掉率 | 装备保底波数 |
|--------|----------|----------|--------------|
| 1-10 | 22% | 35% | 每3波必掉1件 |
| 11-20 | 18% | 32% | 每4波 |
| 21-30 | 16% | 30% | 每5波 |

---

## 四、代码入口

| 模块 | 职责 |
|------|------|
| `ProgressionManager` | 加载 JSON、查等级段/解锁/合成表 |
| `DataManager.exp_for_level()` | 委托给 ProgressionManager |
| `GameManager._aggregate_wave_rewards()` | 按等级段掉率 + 装备保底 |
| `GameManager._on_level_up()` | 触发解锁通知 |
| `save.progression` | 已解锁系统、保底计数 |

### 常用 API

```gdscript
ProgressionManager.get_bracket(level)           # 当前等级段
ProgressionManager.is_system_unlocked("gem", level)
ProgressionManager.get_next_unlock(level)       # 下一个待解锁系统
ProgressionManager.get_available_synthesis_tiers("mount", level)
ProgressionManager.exp_for_level(level)
```

---

## 五、后续实现顺序（建议）

1. **坐骑** — 合成表已有，加 `mount` 存档字段 + 属性加成
2. **宝石 UI** — `enhance_system` 已有镶嵌逻辑，补合成入口
3. **八阵图** — 8 个阵眼槽，材料合成阵眼
4. **元神/灵魄** — 百分比属性专项加成
5. **符咒/翅膀/奥义/天书** — 按合成表逐档接入

每做一个系统：**只读 JSON 配方 + 写存档 + 接入 `_recalculate_stats()`**，不要硬编码数值。

---

## 六、调平衡工作流

1. 觉得升级太慢 → 改 `balance_curves.json` 的 `exp_formula.base` 或 `target_minutes_per_level`
2. 觉得掉装太少 → 改对应等级段的 `drop_rate_equip` 或 `equip_pity_waves`
3. 想推迟某系统 → 改 `progression_systems.json` 的 `unlock_level`
4. 想调合成成本 → 改 `synthesis_catalog.json` 的 `recipe`

改完重启游戏即可生效，无需改 GDScript。

---

## 七、相关文档

- [界锚残片主线玩法](HORCRUX_LOOP.md) — 魂器式探索主线，与等级段养成并行
- [万界裂隙世界观](MULTIVERSE_LORE.md) — 十界穿越设定
