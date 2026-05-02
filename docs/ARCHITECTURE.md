# ARCHITECTURE.md

> **作用**：系统的"地图"。让 AI 在改跨组件代码、设计新功能怎么落地、判断改动会影响什么的时候有依据。
>
> **何时读**：处理跨组件改动；设计如何落地一个新需求；评估某个改动的爆炸半径。
>
> **何时更新**：组件边界变了、新增/删除了一个组件、依赖关系变了；伴随某个 OpenSpec change 一起改。
>
> **写作风格**：稳定。不写易变的细节（那些去 `openspec/specs/`）。
>
> 把所有 `TODO:` 替换成本项目的真实内容，然后删除本提示框。

---

## 系统全景图

TODO: 用 ASCII / Mermaid 画一张系统总览图。要包含主要组件、数据流向、外部依赖。

```
TODO: 例
            ┌──────────┐
   client → │   API    │ → ┌──────────┐
            │ (FastAPI)│   │   Core   │ → ┌─────────┐
            └──────────┘   │ (domain) │   │ Storage │ → PostgreSQL
                           └──────────┘   └─────────┘
```

## 组件清单

TODO: 列出每个组件的职责和位置。


| 组件            | 职责               | 关键路径             |
| ------------- | ---------------- | ---------------- |
| TODO: API     | HTTP 入口、请求校验、序列化 | `src/api/**`     |
| TODO: Core    | 业务逻辑，与框架无关       | `src/core/**`    |
| TODO: Storage | 持久化适配器           | `src/storage/**` |


## 模块边界（谁能依赖谁）

TODO: 写清楚导入方向，越严格越好。AI 子代理会按这个判断 import 是否合法。

- TODO: 例「`api/` 可以调用 `core/`；`core/` 不得 import `api/`。」
- TODO: 例「副作用（网络、文件系统、时间）只能在 `storage/` 适配器层。」
- TODO: 例「不得跨 capability 直接 import；走公共接口。」

## 关键数据流

TODO: 列出 1-3 条最重要的端到端数据流。

- TODO: 例「请求路径：`api/` 校验 → `core/` 决策 → `storage/` 持久化 → 响应回到 `api/`。」
- TODO: 例「后台任务：定时器触发 → 任务队列 → worker 处理 → 写回 `storage/`。」

## 外部依赖

TODO: 列出每个外部服务/库为什么选它。AI 改代码时会参考这个判断「该不该引入新的依赖」。


| 依赖               | 用途    | 选它的原因                     |
| ---------------- | ----- | ------------------------- |
| TODO: PostgreSQL | 持久化   | TODO: 例「ACID + JSON 字段支持」 |
| TODO: Redis      | 缓存/队列 | TODO: 例「项目已有运维栈，复用」       |


## 非目标（明确不做的事）

TODO: 写出架构层面**故意不做**的东西，避免 AI 过度泛化。

- TODO: 例「不做多租户。所有数据按单租户假设设计。」
- TODO: 例「不上微服务。单进程到 100 万 DAU 才考虑拆。」

## 相关 spec

TODO: 列出 `openspec/specs/<capability>/spec.md` 中和架构强相关的 capability。

- TODO: 例 `[openspec/specs/auth/spec.md](../openspec/specs/auth/spec.md)`
- TODO: 例 `[openspec/specs/billing/spec.md](../openspec/specs/billing/spec.md)`

