# 搭+ 项目知识库 Skill

面向青年群体的微信小程序活动报名与轻社交平台（Da+）的项目知识库 Claude Code Skill。

## 覆盖范围

- 产品定位与架构
- 功能清单（V1.0 - V1.4.11）
- 业务规则（10 类，含拉卡拉分账）
- 版本演进（132 条台账）
- 技术决策（6 个关键架构决策）
- 源码索引（待填充）
- 16 个高频 FAQ

## 使用方式

安装到 Claude Code：

```bash
# 克隆到 skills 目录
git clone https://github.com/yanye09/da--knowledge.skill.git ~/.claude/skills/da+-knowledge.skill
```

触发方式：对话中提到「搭+」「Da+」「搭加」等关键词即自动激活。

## 目录结构

```
da+-knowledge.skill/
├── SKILL.md                 # 调用规则 + 检索机制 + 同步触发
├── knowledge/               # 项目知识库（结构化摘要）
│   ├── faq.md               # 高频问题速查
│   ├── 00-meta.md           # 元数据、数据源清单
│   ├── 01-quick-ref.md      # 产品速览、架构、关键决策
│   ├── 02-features.md       # 功能清单
│   ├── 03-rules.md          # 业务规则
│   ├── 04-versions.md       # 版本演进
│   └── 05-tech.md           # 技术决策与安全规范
├── scripts/
│   └── sync-from-feishu.sh  # 飞书源同步检查脚本
├── source-index/
│   └── README.md            # 源码索引框架
└── state/
    └── sync-state.json      # 飞书源版本指纹
```

## 同步机制

关联两个飞书实时数据源，变更时自动检测并提示更新：

| 模式 | API 调用次数 | 检测内容 |
|------|-------------|---------|
| light | 1 次 | PRD revision_id |
| full | 3 次 | PRD + 台账 edit_time + row_count |

手动触发全量同步：对话中说「更新 Skill」「更新知识库」「同步最新信息」。

## 盲答禁令

知识库中没有证据的，不猜测、不补充、不根据通用经验补全。每个结论都标注可信度：`[已确认]` / `[推断]` / `[不确定]`。

## 数据源

| 类型 | 链接 |
|------|------|
| PRD 文档 | [飞书 Docx](https://scntlaw1t3yy.feishu.cn/docx/FkFZdljhJoJN1xx0QgfcqxgBnsf) |
| 优化台账 | [飞书 Wiki](https://scntlaw1t3yy.feishu.cn/wiki/FGjtwH4qQi4trUkvPQvcM24unHh) |
