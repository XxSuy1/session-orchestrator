# 项目入口（保持精简）

## 工作流
本项目按总控协议运行，规则见 @.claude/rules/workflow.md。主对话 = 总控，只指挥不干重活；子会话只做被分配的一张任务卡。

## 当前状态（自动导入）
@docs/memory/STATE.md

## 会话协议
- 开始：若 `docs/memory/HANDOFF.md` 内容不是空模板，先读它；再读 `DECISIONS.md`、`TASKS.md`，用三句话复述当前状态再动手。
- 结束前按 `workflow.md` §7 的收尾清单逐项过一遍。
- 结束：更新 STATE.md（只写当前状态）；有决策写 DECISIONS.md；有坑写 GOTCHAS.md。
- 你若是子会话：读 brief → 动手前把细计划写成 `docs/briefs/T-xxx.plan.md` → 只做 brief 范围 → 详细产出写文件 → 回报"状态｜结论｜文件路径"，并附检查命令与输出。

## 检查命令
见 `docs/memory/CHECK_CMD.txt`。完成前必须运行并出示输出。
