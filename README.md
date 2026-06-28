这是一个在饥荒联机版服务器中增强阿比盖尔的小模组喵。

当前功能：
- 阿比盖尔锁定攻击目标时会立刻先劈一道雷。
- 只要该目标还活着且仍然是阿比盖尔当前目标，就会每 2 秒再次落雷一次。
- 阿比盖尔每次命中目标都会刷新一次 60 秒的减速效果，使目标移速降低 50%。
- 阿比盖尔永久获得 100% 移速提升。
- 阿比盖尔的发光范围永久提升到原版的 7 倍。
- 每个阿比盖尔都会每 60 秒为附近玩家回复 9 点饱食度、9 点理智、9 点生命值。
- 阿比盖尔受到伤害时，攻击她的怪会被原版冰冻效果冻住一段时间。
- 阿比盖尔永久免疫雷击和火焰伤害。
- 阿比盖尔通过“作祟”命令作用于地面上的耐久类物品时，会尽量回满耐久和保质期。

目前耐久恢复覆盖：
- `finiteuses`：如斧头、镐子、武器、法杖等使用次数型物品。
- `armor`：如草甲、木甲、矿甲等护甲耐久型物品。
- `fueled`：如提灯、矿灯等燃料耐久型物品。
- `perishable`：如食物等带保质期的物品，能恢复的会回满保质期。

说明：
- 没有替换阿比盖尔的 brain 或 stategraph 主逻辑，尽量减少和原版/其他模组的冲突面。
- 减速效果采用单一外部移速倍率并不断刷新持续时间，不会叠出超长持续时间。
- 附近玩家回复效果按每个阿比盖尔各自独立结算，多只阿比盖尔聚在一起时会自然叠加回复频率。
- “作祟回耐久/保质期”是对原版 `ACTIONS.HAUNT` 结果做兼容式增强，不改动温蒂原本的阿比盖尔命令系统。

之前踩过的问题：
- 之前试过直接改 `inst.Light` 上的方法，结果因为它是 userdata，进世界后会直接报错并导致世界卡死。现在只通过 `inst.Light:SetRadius(...)` 改半径，不再碰 userdata 方法表。
- 之前给保质期恢复加过 `pcall` 保护，但 DST 这个模组运行环境里那次实际拿到的 `pcall` 是空值，阿比盖尔作祟熟肉时会直接把服务端打崩。现在保质期恢复只做字段判断，然后直接走 `perishable:SetPercent(1)`。

Current features:
- Abigail immediately calls down lightning on her current combat target.
- If that same target stays alive and remains Abigail's active target, it is struck again every 2 seconds.
- Whenever Abigail hits a target, she refreshes a 60 second movement slow that reduces that target's speed by 50%.
- Abigail permanently gains 100% movement speed.
- Abigail's light radius is permanently increased to 7x the vanilla radius.
- Every Abigail restores 9 hunger, 9 sanity, and 9 health to nearby players every 60 seconds.
- Abigail freezes attackers with the base game's freeze effect when she is hit.
- Abigail is permanently immune to lightning and fire damage.
- When Abigail uses her haunt command on a dropped durability-based item, it restores durability and freshness where supported.

Durability restoration currently covers:
- `finiteuses`: axes, pickaxes, weapons, staves, and other use-count based items.
- `armor`: armor pieces that use condition durability.
- `fueled`: fueled durability items such as lanterns and miner hats.
- `perishable`: food and other perishables, restored when the item safely supports freshness recovery.

Notes:
- The mod does not replace Abigail's main brain or core stategraph flow.
- The slow effect refreshes one locomotor speed modifier instead of stacking long-duration timers.
- Nearby player restoration is calculated independently per Abigail, so multiple Abigails naturally stack their regen cadence.
- The haunt-based durability and freshness refill augments vanilla `ACTIONS.HAUNT` behavior instead of rewriting Wendy's ghost command system.

Past pitfalls:
- A previous attempt tried to override methods on `inst.Light` directly. That crashed because `inst.Light` is userdata. The mod now only adjusts light radius through `inst.Light:SetRadius(...)`.
- A previous perishability hotfix used `pcall`, but in that crash case the mod runtime exposed `pcall` as a nil value, so haunting stale cooked meat could crash the server. Freshness restoration now relies on direct field checks plus `perishable:SetPercent(1)`.
