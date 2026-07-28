# 识天 iOS 版 — 下载与安装指南（Windows 用户）

本指南面向 Windows 用户：从 GitHub Actions 下载云端构建的未签名 ipa，并签名安装到 iPhone。

## 一、下载构建产物

1. 打开仓库 Actions 页面：
   https://github.com/Feng-WeiHang/know_sky-ios/actions
2. 点击最新一次 **绿色 ✅ 成功** 的 "Build iOS IPA (unsigned)" 运行记录
3. 滚动到页面底部 **Artifacts** 区域，点击下载：
   - `SkySense-unsigned-ipa` —— 未签名安装包（日常安装用这个）
   - `SkySense-xcarchive` —— Xcode 归档（上架 App Store / 正式签名时才需要）
4. 下载得到的是 zip，解压后得到 `SkySense-unsigned.ipa`

> 产物保留 30 天。过期后到 Actions 页面点 **Run workflow** 手动触发重新构建即可。
> 每次向 main 分支推送代码也会自动重新构建。

## 二、签名并安装到 iPhone（二选一）

未签名 ipa 无法直接安装，需用自己的 Apple ID 签名。以下两个工具都在 Windows 上运行：

### 方式 A：Sideloadly（推荐，界面简洁）

1. 官网下载安装：https://sideloadly.io/ （同时会提示安装 iTunes 驱动组件）
2. 数据线连接 iPhone，手机上点「信任此电脑」
3. 打开 Sideloadly：
   - 把 `SkySense-unsigned.ipa` 拖入窗口
   - `Apple account` 填入你的 Apple ID，点 **Start**，按提示输入密码（支持双重认证）
4. 安装完成后，在 iPhone 上：
   **设置 → 通用 → VPN与设备管理 → 你的 Apple ID → 信任**
5. 桌面点击「识天」图标即可运行

### 方式 B：爱思助手（中文界面）

1. 官网下载：https://www.i4.cn/
2. 连接 iPhone → 工具箱 → **IPA 签名**
3. 添加 `SkySense-unsigned.ipa`，选择「使用 Apple ID 签名」，登录后点签名
4. 签名完成后在「已签名列表」里点 **安装**
5. 同样需要在手机上信任证书（步骤同上）

## 三、添加桌面小组件

安装并打开 App 一次后：

1. 长按 iPhone 桌面空白处 → 点左上角 **＋**
2. 搜索「识天」，可添加：
   - **识天时钟**：质感表盘（小/中两种尺寸）
   - **识天气象**：实时天气（小=精简 / 中=详细网格 / 大=含5日预报）
3. 长按气象小组件 → **编辑小组件** → 可为每个组件单独选择城市
4. 小组件主题与透明度在 App 内 **设置 → 组件** 中调整

## 四、重要说明

| 事项 | 免费 Apple ID | 付费开发者账号（$99/年） |
|---|---|---|
| 签名有效期 | **7 天**（到期重签即可，数据不丢） | 1 年 |
| 可安装设备数 | 3 台 | 100 台 |
| App Group（主应用与小组件共享城市/设置数据） | ❌ 不支持，小组件可能读不到主应用数据 | ✅ 完整支持 |
| 上架 App Store | ❌ | ✅ |

- 免费账号签名的 App 每 7 天需要用 Sideloadly/爱思助手重新签名一次（重签不会丢数据）
- 若小组件显示「暂无城市」，多为免费账号 App Group 受限所致，属预期行为
- 天气数据来源 open-meteo.com，无需任何 API 密钥

## 五、常见问题

- **安装时报「无法验证应用」**：先完成第二步第 4 点的「信任证书」
- **Sideloadly 报 Apple ID 错误**：关闭 VPN/代理后重试；双重认证按手机弹窗提示操作
- **7 天后 App 打不开**：属正常过期，重新签名安装一次即可
- **想要正式版**：购买 Apple 开发者账号后，用 `SkySense-xcarchive` 在 Xcode 中导出正式签名的 ipa，或直接上架 App Store
