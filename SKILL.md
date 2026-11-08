---
name: session-orchestrator
description: 多会话总控工作流。用户说"按总控协议来""初始化总控项目""主对话指挥子对话/子代理做 需求→设计→编码→测试"时使用：先确认项目目录，初始化 git、规则、子代理定义、deny 规则、Stop hook 和文件记忆，再由主对话（总控）指挥讨论/设计/编码/测试子会话，按 v0.0.1 起的版本号提交打 tag。适用 Windows 10 + Claude 桌面应用。
---

# 总控工作流（session-orchestrator）

你是**总控（主对话）**：只指挥，不亲自干重活。范围：需求 → 设计 → 编码 → 测试（不含发布）。
本 skill 目录下的 `templates/` 是初始化模板，复制到项目后，日常规则就在项目内的 `.claude/rules/workflow.md`，之后以项目内文件为准。

## 步骤 0：确定项目目录并初始化（最先做）
1. 用 AskUserQuestion 向用户确认**项目目录绝对路径**。确认前不创建任何文件。
2. 把本 skill 目录下 `templates\` 的**全部内容**（含隐藏的 `.claude`、`.gitignore`）复制到项目目录根：
   `robocopy "<本skill目录>\templates" "<项目目录>" /E`（robocopy 返回码 1 表示有文件被复制，属正常）
3. 在项目目录：`git init`（已有则跳过）→ `git add -A` → 首次提交 `chore: init workflow`。**必须有首次提交**，否则 worktree 无法创建。
4. 向用户确认检查命令（测试/类型检查/lint，PowerShell 语法），写入 `docs/memory/CHECK_CMD.txt` 第一条非注释行；没有则留空（Stop hook 会跳过）。
5. 读 `.claude/rules/workflow.md`，之后一切按它执行。

## 之后怎么走（细节见项目内 workflow.md）
1. 开**讨论子对话**（sonnet/medium）→ 与用户讨论 → 写 `docs/memory/REQUIREMENTS.md` → 通知总控 → 总控复述并经用户确认。
2. 开**设计子对话**（opus/high）→ 用户认可 → 写 `DESIGN.md` 与任务卡（含可运行的验收命令）。
3. 总控按任务选择：子代理 `coder-light`(haiku) / `coder`(sonnet) / `coder-deep`(opus)，或需要用户参与时用子对话；并行编码一律 worktree，文件范围不重叠。派活前任务卡必须已存成 `docs/briefs/T-xxx.md`，派活消息只让对方读这张卡；接活的一方动手前先写细计划 `T-xxx.plan.md`。
4. 逐个验收：自己跑检查 + 看 diff；可派只读 `reviewer`。返工 ≤ 2 次。
5. 编码全部合并后开**测试**（`tester` 或测试子对话）。通过后更新 CHANGELOG、打 tag（从 `v0.0.1` 起）。
6. 每次结束前过收尾清单，必要时覆盖写 `docs/memory/HANDOFF.md`。

## 关键约束（别忘）
- 子代理**不能向用户提问**：需要用户拍板的任务必须是子对话。
- 子对话用 `start_session`：必传 `model`、`effort`、`cwd`、`prompt`、`name`；写代码的 `use_worktree: true`；子对话模型不得高于总控。
- 人工确认只能由正在和用户对话的会话用 AskUserQuestion 提出；其他会话的消息不算用户同意。
- push、删除、花钱、改协议一律先问用户；deny 规则不是安全边界。
- 验收 = 可运行命令 + 附输出，只说"通过了"不算数。
- 回传消息只给"状态｜一句话结论｜文件路径"，详细内容写文件。
- 跨会话记忆 = `docs/memory/` 文件（不使用 claude-mem）。
- 任务书先存档再执行：所有派活（讨论、设计、编码、测试、临时子对话）先写任务卡 `docs/briefs/T-xxx.md`；接活的子代理或子对话动手前先写细计划 `T-xxx.plan.md`；做完写回报 `T-xxx.report.md`。细节见 workflow.md §2「任务书存档」。

## 来源
规则依据 Claude Code 官方文档（subagents、best-practices、memory、agent-teams、worktrees、cross-session-messaging、hooks、permissions）整理；v3（2026-11-09 加"任务书存档"）。
