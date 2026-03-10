# OpenClaw 上游贡献待办

> PocketClaw 在实际使用中积累的实践经验，可贡献给 OpenClaw 上游项目。
> 上游仓库：https://github.com/openclaw/openclaw

---

## P0 — 立即提交（高价值、低风险）

### 1. Docker 安全加固示例
- **类型**: 文档补充 (docs)
- **目标文件**: `docs/install/docker.md`
- **内容**: 在 Docker 文档中补充 gateway 容器的安全加固最佳实践
- **要点**:
  - `read_only: true` — 只读根文件系统
  - `cap_drop: [ALL]` — 丢弃所有 Linux capabilities
  - `security_opt: [no-new-privileges:true]` — 禁止容器内提权
  - `mem_limit` / `pids_limit` — 资源限制防止 DoS
  - `tmpfs` 挂载 — `/tmp`, npm 缓存等必要可写目录
- **状态**: ⬜ 待提交
- **PR 分支**: `docs/docker-security-hardening`

### 2. Healthcheck docker-compose 示例
- **类型**: 文档补充 (docs)
- **目标文件**: `docs/install/docker.md`
- **内容**: 在 Health checks 小节补充 docker-compose.yml 格式的健康检查配置示例
- **要点**:
  - 使用 `/healthz` 端点（官方推荐的 liveness probe）
  - 合理的 interval/timeout/retries/start_period 参数
  - 示例可直接复制粘贴到用户的 compose 文件
- **状态**: ⬜ 待提交
- **PR 分支**: `docs/docker-healthcheck-compose`

---

## P1 — 短期目标（需更多准备）

### 3. ShellCheck + Hadolint CI 集成
- **类型**: CI/CD (`.github/workflows/`)
- **内容**: 提供 GitHub Actions workflow 对 shell 脚本和 Dockerfile 进行静态分析
- **价值**: 上游有 50+ shell 脚本，静态分析能捕获常见错误
- **状态**: ⬜ 待准备

### 4. 构建指纹缓存（CACHE_DATE）
- **类型**: Dockerfile 优化
- **内容**: 将 `ARG CACHE_DATE` 的使用模式提交为文档或示例
- **价值**: 精确控制 Docker 层缓存失效时机
- **状态**: ⬜ 待准备

---

## P2 — 中期目标（Issue 讨论）

### 5. Gateway 自定义路由 API
- **类型**: Feature Request (Issue)
- **内容**: 请求 gateway 提供注册自定义 HTTP 路由的 API（如 PocketClaw 的 mobile.html 和 setup.html）
- **当前方案**: PocketClaw 通过 gateway-patch.py 猴子补丁实现
- **理想方案**: 官方 API 如 `gateway.registerRoute('/mobile', handler)`
- **状态**: ⬜ 待提 Issue

### 6. Docker doctor 子命令
- **类型**: Feature Request (Issue)
- **内容**: 请求 `openclaw-cli doctor docker` 诊断命令，自动检查 Docker 环境健康
- **检查项**: 磁盘空间、容器状态、日志大小、配置一致性
- **状态**: ⬜ 待提 Issue

---

## P3 — 长期目标（需社区讨论）

### 7. 环境变量 → 频道配置映射
- **类型**: Feature Request (Issue)
- **内容**: 支持通过环境变量直接配置频道（如 `TELEGRAM_BOT_TOKEN`），无需 CLI 交互
- **价值**: 对 Docker/CI 场景非常友好
- **PocketClaw 实现**: entrypoint.sh 中通过脚本将环境变量写入 channels.json
- **状态**: ⬜ 待提 Issue

### 8. Provider 注册表机制
- **类型**: Feature Request (Issue)
- **内容**: 官方维护一个 provider 配置注册表（API base URL、模型列表、认证方式）
- **价值**: 降低用户配置免费 API 的门槛
- **PocketClaw 实现**: providers.json 内置了多个预配置的 provider
- **状态**: ⬜ 待提 Issue

---

## 提交 PR 的步骤

```bash
# 1. 登录 GitHub CLI
gh auth login

# 2. Fork 上游仓库
gh repo fork openclaw/openclaw --clone=false

# 3. 克隆你的 fork
gh repo clone ProjectAILiberation/openclaw

# 4. 创建分支并提交
cd openclaw
git checkout -b docs/docker-security-hardening
# ... 编辑文件 ...
git add .
git commit -m "docs(docker): add security hardening examples for gateway container"
git push origin docs/docker-security-hardening

# 5. 创建 PR
gh pr create --repo openclaw/openclaw \
  --title "docs(docker): add security hardening best practices" \
  --body "..."
```

---

*最后更新: 2026-03-15*
