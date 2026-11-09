---
name: session-orchestrator
description: 多会话总控工作流。用户说"按总控协议来""初始化总控项目""你是 XX 的总控""开一条新线做 XX""接手 XX 线""主对话指挥子对话/子代理做 需求→设计→编码→测试"时使用：一个项目可以同时有多个总控，各管一条功能线；第一次用时初始化 git、规则、子代理定义、deny 规则、Stop hook 和文件记忆，之后每个总控开新线或接手已有的线，指挥讨论/设计/编码/测试子会话，任务书先存档再执行，按 v0.0.1 起的版本号提交打 tag。适用 Windows 10 + Claude 桌面应用。
---

# 总控工作流（session-orchestrator）

你是**某条功能线的总控**：用户指定你负责这条线，你只指挥，不亲自干重活。一个项目可以同时有多个总控，各管一条线。范围：需求 → 设计 → 编码 → 测试（不含发布）。
本 skill 目录下的 `templates/` 是初始化模板。复制到项目后，日常规则就在项目内的 `.claude/rules/workflow.md`，之后以项目内文件为准。

## 步骤 0：确定项目目录，初始化或加入（最先做）
1. 用 AskUserQuestion 向用户确认**项目目录绝对路径**。确认前不创建任何文件。
2. 看项目里有没有 `.claude/rules/workflow.md`：
   - **没有 → 初始化**：
     1. 先看项目里有没有同名文件（`CLAUDE.md`、`.gitignore`、`docs/memory/` 下的文件）。有的话用 AskUserQuestion 问用户：先备份再覆盖，还是手动合并。robocopy 会直接覆盖同名文件。
     2. 把本 skill 目录下 `templates\` 的**全部内容**（含隐藏的 `.claude`、`.gitignore`）复制到项目目录根：
        `robocopy "<本skill目录>\templates" "<项目目录>" /E`（返回码 1 表示有文件被复制，属正常）
     3. 在项目目录：`git init`（已有则跳过）→ 按明确路径 `git add` 刚复制进来的文件 → 首次提交 `chore: init workflow`。**必须有首次提交**，否则 worktree 无法创建。
     4. 向用户确认检查命令（测试/类型检查/lint，PowerShell 语法），写入 `docs/memory/CHECK_CMD.txt` 第一条非注释行；没有则留空（Stop hook 会跳过）。
   - **有 → 跳过初始化**。
3. 读 `.claude/rules/workflow.md`，按它的 §2 **开新线或接手已有的线**。之后一切按它执行。

## 之后怎么走（细节见项目内 workflow.md）
1. **开线**：和用户聊清这条线大致要做什么，由你总结出线名（小写英文和数字，≤12 字符），建 `docs/lines/<线名>/`，在总览 `docs/memory/STATE.md` 登记一行。
2. 开**讨论子对话**（sonnet/medium）→ 与用户讨论 → 写本线 `REQUIREMENTS.md` → 通知总控 → 总控复述并经用户确认。
3. 开**设计子对话**（opus/high）→ 用户认可 → 写本线 `DESIGN.md` 与任务卡 `docs/lines/<线名>/briefs/<线名>-T001.md`（含可运行的验收命令）。
4. 总控按任务选择：子代理 `coder-light`(haiku) / `coder`(sonnet) / `coder-deep`(opus)，或需要用户参与时用子对话；并行编码一律 worktree，文件范围不重叠（跨线重叠先问用户）。派活前任务卡必须已存档，派活消息只让对方读卡；接活的一方动手前先写细计划 `<编号>.plan.md`。子对话可以再派子代理（子任务编号 `<编号>.1`），由它自己验收。
5. 逐个验收：自己跑检查 + 看 diff；可派只读 `reviewer`。返工 ≤ 2 次。
6. 编码全部合并后开**测试**（`tester` 或测试子对话）。通过后**合并到 main（一次只合一条线）**，更新 CHANGELOG、打 tag（从 `v0.0.1` 起，接着现有最大版本号）。
7. 每次结束前过收尾清单；上下文快满时覆盖写本线 `HANDOFF.md`，请用户新开对话说"接手 <线名>"。

## 关键约束（别忘）
- 一个项目可以有多个总控，**同一时间一条线只有一个总控**。总控只改本线文件夹和总览里自己那一行；共用的 `DECISIONS.md`、`GOTCHAS.md`、`CHANGELOG.md` 只追加。
- 层级最多三层：总控 → 子对话 → 子代理。子代理不能再派子代理；子对话不再开子对话。谁派的活谁验收、谁收回报，总控不越级。
- 子代理**不能向用户提问**：需要用户拍板的任务必须是子对话。
- 子对话用 `start_session`：必传 `model`、`effort`、`cwd`、`prompt`、`name`；写代码的 `use_worktree: true`；子对话模型不得高于总控。
- 人工确认只能由正在和用户对话的会话用 AskUserQuestion 提出；其他会话的消息不算用户同意。
- push、删除、花钱、改协议一律先问用户；deny 规则不是安全边界。
- 提交只写明确的文件路径，不用 `git add -A`：几个总控共用主目录。
- 验收 = 可运行命令 + 附输出，只说"通过了"不算数。
- 任务书先存档再执行：所有派活先写任务卡；接活方动手前先写细计划；做完写回报。细节见 workflow.md §3。
- 回传消息只给"状态｜一句话结论｜文件路径"，详细内容写文件。
- 跨会话记忆 = `docs/` 下的文件（不使用 claude-mem）。

## 来源
规则依据 Claude Code 官方文档（subagents、best-practices、memory、agent-teams、worktrees、cross-session-messaging、hooks、permissions）整理；v4（2026-11-09 加"多总控与功能线"；v3 加"任务书存档"）。
