---
name: da+-knowledge.skill
description: |
  搭+（Da+）小程序项目知识库。覆盖产品定位、功能清单、业务规则、技术决策、版本演进、源码索引。
  TRIGGER when: 用户提到「搭+」「Da+」「搭加」「搭+小程序」「搭+平台」，或询问搭+的功能、业务规则、产品设计、版本历史、技术架构、PRD。
  DO NOT TRIGGER when: 用户讨论的是其他小程序/平台/产品，或与搭+无关的通用技术问题。
---

# 搭+ 项目知识库

## Skill 架构

```
da+-knowledge.skill/
├── SKILL.md                 ← 调用规则 + 检索机制 + 同步触发 + 盲答禁令
├── knowledge/               ← 项目知识库（结构化摘要）
│   ├── faq.md               ← 高频问题速查（先扫此文件）
│   ├── 00-meta.md           ← 元数据、数据源清单、最近同步时间
│   ├── 01-quick-ref.md      ← 产品速览、架构、关键决策
│   ├── 02-features.md       ← 功能清单
│   ├── 03-rules.md          ← 业务规则
│   ├── 04-versions.md       ← 版本演进
│   └── 05-tech.md           ← 技术决策与安全规范
├── source-index/            ← 源码索引（代码位置映射）
│   └── README.md            ← 代码库说明、文件树、feature→file 映射
├── scripts/
│   └── sync-from-feishu.sh  ← 飞书源同步脚本
└── state/
    └── sync-state.json      ← 飞书源版本指纹
```

---

## 一、调用规则

### 何时触发
- 用户消息包含「搭+」「Da+」「搭加」「搭+小程序」「搭+平台」
- 用户询问搭+的功能、业务规则、版本历史、技术架构、PRD 相关内容
- 用户要求分析/评估/建议搭+的产品决策或技术方案

### 触发后的行为
1. **先扫 FAQ**：加载 `knowledge/faq.md`，如果问题命中 FAQ 中的条目 → 直接回答，跳过后续步骤
2. **同步检查**（见第四节）：FAQ 未命中时，运行 `bash scripts/sync-from-feishu.sh <dir> light` 轻量检查（仅 1 次 API 调用）；如果用户询问台账/版本历史，或上次全量同步距今超过 24 小时，则用 `full` 模式（3 次 API 调用）
3. **按检索表路由**（见第二节）：定位到具体 knowledge 文件或飞书源
4. **加载 knowledge 文件**：只加载与问题相关的文件，不全部加载
5. **回答**：基于 knowledge 文件的内容回答，遵守盲答禁令（见第三节）

### 何时不触发
- 用户讨论的是其他小程序/平台/产品
- 与搭+无关的通用技术问题

### 何时加载飞书源
- knowledge 文件中的摘要信息不足以回答用户问题
- 用户询问的是台账最新数据（因为 knowledge/ 可能是几天前的快照）
- 用户明确要求「查一下飞书」「从飞书 PRD 看看」

---

## 二、检索机制

### 问题 → 知识定位

| 问题类型 | 检索路径 |
|----------|---------|
| **常见高频问题**（版本号/支付方式/有没有XX功能等） | **先扫 `knowledge/faq.md`**，命中则直接回答 |
| 产品定位 / Slogan / 用户角色 / 版本号 / 架构概览 | `knowledge/01-quick-ref.md` |
| 某个功能是否存在 / 功能清单 / 能力边界 | `knowledge/02-features.md` → 不足时查飞书 PRD |
| 业务规则 / 流程约束 / 校验逻辑 | `knowledge/03-rules.md` → 不足时查飞书 PRD |
| 版本历史 / 台账 / 某功能何时上线 | `knowledge/04-versions.md` → 实时数据查飞书台账 |
| 技术栈 / 架构决策 / 安全规范 / 敏感信息处理 | `knowledge/05-tech.md` |
| 源代码位置 / 某功能的代码在哪 / 项目文件结构 | `source-index/README.md` |
| 元数据 / 数据源 / 最近同步时间 / 知识盲区 | `knowledge/00-meta.md` |

### 交叉问题的检索策略
当问题跨越多个知识域时：
1. 先扫 `knowledge/00-meta.md` 了解全局
2. 读取相关的 2-3 个 knowledge 文件
3. 如需原文细节，查飞书源
4. 如需代码实现，查 source-index

---

## 三、盲答禁令（关键规则）

### 原则
**知识库中没有证据的，不猜测、不补充、不根据通用经验补全。**

### 执行规则
1. 每个结论必须有 knowledge 文件或飞书源中的具体依据
2. 如果 knowledge 文件中没有相关信息：
   - **不要猜测**
   - 明确回答：**"当前 Skill 中没有足够信息确认 [具体问题]。建议：1) 直接查看飞书 PRD: https://scntlaw1t3yy.feishu.cn/docx/FkFZdljhJoJN1xx0QgfcqxgBnsf; 2) 查看飞书台账: https://scntlaw1t3yy.feishu.cn/wiki/FGjtwH4qQi4trUkvPQvcM24unHh; 3) 提供相关文档后我补充进知识库。"**
3. 如果 knowledge 文件有相关信息但不完整——先说明已知部分，再标注不确定部分：
   - **"[已确认]：[evidence]。[不确定]：[question] — 当前知识库未覆盖此细节。"**
4. 禁止的行为：
   - "一般来说这种系统会..."（根据通用经验补全）
   - "应该是..."（没有依据的推测）
   - 把「待开发」功能说成「已上线」
   - 把「已终止」功能说成「可用」

### 可信度标记
回答时对信息来源分级标记：
- **[已确认]**：来自飞书 PRD 或台账，或已在 knowledge 文件中结构化记录
- **[推断]**：基于已确认信息的逻辑推导（需要标注推理链路）
- **[不确定]**：知识库未覆盖，需要进一步确认

---

## 四、同步触发

### 两级同步策略

| 模式 | 命令 | API 调用次数 | 何时使用 |
|------|------|------------|---------|
| **light**（默认） | `bash scripts/sync-from-feishu.sh <dir> light` | 1 次（仅 PRD revision_id） | 用户问简单问题、FAQ 已命中 |
| **full** | `bash scripts/sync-from-feishu.sh <dir> full` | 3 次（PRD + 台账 edit_time + row_count） | 用户询问台账/版本历史、FA 未命中且距上次全量同步 > 24h、用户明确触发同步 |

### 脚本输出

返回 JSON，核心字段：
```json
{
  "check_mode": "light|full",
  "prd_changed": true/false,
  "ledger_changed": true/false,
  "any_error": true/false,
  "prd": { "cached_revision": N, "current_revision": N, "error": true/false, "error_msg": "..." },
  "ledger": { "cached_edit_time": N, "current_edit_time": N, "cached_rows": N, "current_rows": N, "error": true/false, "error_msg": "...", "skipped": true/false }
}
```
退出码: `0` = 无变化, `2` = 有变化, `3` = 获取失败（认证过期或网络错误）

### 错误处理

**当 `any_error: true` 或退出码为 3 时**：
- 不能假设数据未变化（静默失败已消除）
- 降级策略：跳过同步检查，基于现有 knowledge/ 文件回答，但在回答末尾标注：
  > "⚠️ 本次回答未经过飞书源同步检查（同步脚本报错：[error_msg]），知识库内容可能是过期快照。建议检查 lark-cli 认证状态后手动执行 `bash scripts/sync-from-feishu.sh <dir> full`。"

### 判定与行动

| 脚本输出 | 行动 |
|----------|------|
| 退出码 0，无变化 | 直接使用 knowledge/ 文件回答 |
| 退出码 3，获取失败 | 降级使用 knowledge/ 文件，标注「未经过同步检查」 |
| `prd_changed: true` | 读取 PRD 变更部分 → 更新 `knowledge/02-features.md`、`03-rules.md`、`05-tech.md`、`faq.md`（如涉及 FAQ） → 更新 `state/sync-state.json` |
| `ledger_changed: true` | 读取台账新增行 → 更新 `knowledge/04-versions.md` → 如有新功能同步更新 `knowledge/02-features.md`、`faq.md` → 更新 `state/sync-state.json` |
| 两者均变化 | 先更新 PRD 侧，再更新台账侧 |

### 手动触发

用户以下指令触发全量同步：
- 「更新 Skill」「更新知识库」「同步最新信息」
- 「搭+有新功能上线」「搭+更新了版本」

### 更新后的步骤
1. 使用 Edit 增量更新受影响的 knowledge 文件
2. 更新 `state/sync-state.json` 中的指纹
3. 更新 `knowledge/00-meta.md` 中的最近同步时间
4. 告知用户具体变更内容

---

## 五、飞书权威数据源

### 两个核心飞书源

| 数据源 | URL | Token |
|--------|-----|-------|
| PRD 文档 | `scntlaw1t3yy.feishu.cn/docx/FkFZdljhJoJN1xx0QgfcqxgBnsf` | `FkFZdljhJoJN1xx0QgfcqxgBnsf` |
| 优化台账 | `scntlaw1t3yy.feishu.cn/wiki/FGjtwH4qQi4trUkvPQvcM24unHh` | spreadsheet: `W5fJsGIEPhyee1ttMU6c1keUnmc`, sheet: `1` |

**完整数据源清单（含本地文档）见 `knowledge/00-meta.md`**。
