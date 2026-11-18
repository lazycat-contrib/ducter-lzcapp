# ducter-lzcapp

[Ducter](https://github.com/wey-gu/ducter) 的懒猫微服（LazyCat）打包仓库 —— 个人 AI 伙伴：跑在自己的服务器上，把任务交给 Claude Code、Codex 等 Agent 执行，完成或需要拍板时回到对话找你。

## 打包方式

- **exec 裸应用**：不引用 Docker 镜像，LPK 内含上游 GitHub Release 的 Linux 二进制（Bun 单文件可执行，x64/arm64）。
- **仓库不存储二进制**：`build.sh` 在构建时按 `package.yml` 的版本下载 `ducter-<version>-linux-<arch>.tar.gz`，并用上游 `SHA256SUMS.txt` 校验 SHA-256，再解包进 `dist/`。
- CI（[ca-x/lazycat-github-action](https://github.com/ca-x/lazycat-github-action)）每 6 小时跟随上游 release 自动发版，发布到喵喵商店并附版本化 GitHub Release LPK。

## 本地构建

```sh
npm install -g @lazycatcloud/lzc-cli
lzc-cli project build -o ducter.lpk
```

## 运行要点

- 启动命令为 `ducter-launcher.sh`：设置 `HOME=/lzcapp/var/home`、`DUCTER_PORT=8080`、`DUCTER_HOST=127.0.0.1`（仅监听回环，外部访问全部经懒猫网关鉴权转发），再 `exec ducter up --headless`。
- 首次使用需在容器内登录一个 AI Agent（`claude auth login` / `codex login --device-auth` / DeepSeek Key），或首次打开应用时直接粘贴 OpenAI 兼容 Key。
- 数据（对话、任务、Agent 凭据）在 `/lzcapp/var/home/.ducter`，升级不丢。
- 上游 Apache-2.0；本仓库仅做打包适配。
