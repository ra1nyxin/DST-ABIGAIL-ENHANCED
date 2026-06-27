# DST-ABIGAIL-ENHANCED

Enhances Wendy's Abigail in Don't Starve Together.

## 中文

这个模组用来增强温蒂召唤出的阿比盖尔。

当前功能：

- 阿比盖尔锁定攻击目标时会立刻先劈一道雷。
- 只要该目标还活着且仍然是阿比盖尔当前目标，就会每 2 秒再次落雷一次。
- 阿比盖尔每次命中目标都会刷新一次 60 秒的减速效果，使目标移速降低 50%。
- 阿比盖尔永久获得 50% 移速提升。
- 阿比盖尔的发光范围永久提升到原版的 5 倍。
- 每个阿比盖尔都会每 60 秒为附近玩家回复 9 点饱食度、9 点理智、9 点生命值。
- 阿比盖尔永久免疫雷击和火焰伤害。
- 阿比盖尔通过“作祟”命令作用于地面上的耐久类物品时，会直接回满耐久。

目前耐久恢复覆盖：

- `finiteuses`：如斧头、镐子、武器、法杖等使用次数型物品。
- `armor`：如草甲、木甲、矿甲等护甲耐久型物品。
- `fueled`：如提灯、矿灯等燃料耐久型物品。

说明：

- 没有替换阿比盖尔的 brain 或 stategraph 主逻辑，尽量减少和原版/其他模组的冲突面。
- 减速效果采用单一外部移速倍率并不断刷新持续时间，不会叠出超长持续时间。
- 附近玩家回复效果按每个阿比盖尔各自独立结算，多只阿比盖尔聚在一起时会自然叠加回复频率。
- “作祟回耐久”是对原版 `ACTIONS.HAUNT` 结果做兼容式增强，不改动温蒂原本的阿比盖尔命令系统。

## English

This mod enhances Wendy's Abigail.

Current features:

- Abigail immediately calls down lightning on her current combat target.
- If that same target stays alive and remains Abigail's active target, it is struck again every 2 seconds.
- Whenever Abigail hits a target, she refreshes a 60 second movement slow that reduces that target's speed by 50%.
- Abigail permanently gains 50% movement speed.
- Abigail's light radius is permanently increased to 5x the vanilla radius.
- Every Abigail restores 9 hunger, 9 sanity, and 9 health to nearby players every 60 seconds.
- Abigail is permanently immune to lightning and fire damage.
- When Abigail uses her haunt command on a dropped durability-based item, that item's durability is fully restored.

Durability restoration currently covers:

- `finiteuses`: axes, pickaxes, weapons, staves, and other use-count based items.
- `armor`: armor pieces that use condition durability.
- `fueled`: fueled durability items such as lanterns and miner hats.

Notes:

- The mod does not replace Abigail's main brain or core stategraph flow.
- The slow effect refreshes one locomotor speed modifier instead of stacking long-duration timers.
- Nearby player restoration is calculated independently per Abigail, so multiple Abigails naturally stack their regen cadence.
- The haunt-based durability refill augments vanilla `ACTIONS.HAUNT` behavior instead of rewriting Wendy's ghost command system.
