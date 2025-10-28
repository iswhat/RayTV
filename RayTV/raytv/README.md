# RayTV

一个基于HarmonyOS/OpenHarmony开发的功能强大的视频播放应用。

## 功能特性

- 🎬 丰富的视频内容浏览
- 📱 响应式设计，支持手机和平板设备
- ❤️ 收藏功能，保存喜欢的视频
- 📊 观看历史记录
- 📂 分类浏览和筛选
- ⚡ 流畅的视频播放体验
- 🌙 支持深色模式
- 🔄 自动播放记忆功能

## 技术栈

- HarmonyOS/OpenHarmony SDK
- ArkTS/TypeScript
- React
- Redux (状态管理)
- Less (样式预处理器)

## 快速开始

### 环境要求

- Node.js >= 16.0.0
- HarmonyOS SDK 9.0+
- DevEco Studio

### 安装和运行

1. 克隆项目

```bash
git clone https://github.com/yourusername/RayTV.git
cd RayTV
```

2. 安装依赖

```bash
npm install
```

3. 开发模式运行

```bash
npm run dev
```

4. 构建应用

```bash
# 构建手机版本
npm run build

# 构建平板版本
npm run build:tablet
```

## 项目结构

```
RayTV/
├── src/                   # 源代码目录
│   ├── main/ets/          # ArkTS/TypeScript代码
│   │   ├── App.tsx        # 应用入口组件
│   │   ├── MainAbility.ts # 主Ability
│   │   ├── common/        # 通用组件和工具
│   │   ├── components/    # 自定义组件
│   │   ├── pages/         # 页面组件
│   │   ├── service/       # 服务层
│   │   └── store/         # Redux状态管理
│   └── resources/         # 资源文件
├── assets/                # 静态资源
├── app.json5              # 应用配置
├── build-profile.json5    # 构建配置
├── package.json           # 项目依赖
└── README.md              # 项目说明
```

## 页面说明

- **首页**: 展示推荐视频和热门内容
- **分类页**: 按分类浏览视频内容
- **收藏页**: 管理用户收藏的视频
- **历史页**: 查看观看历史记录

## 开发注意事项

1. 请确保已配置正确的HarmonyOS开发环境
2. 应用需要网络权限，请在设备上授权
3. 如需自定义主题，请修改相应的样式文件

## 许可证

[MIT](https://opensource.org/licenses/MIT)

## 贡献

欢迎提交Issue和Pull Request来帮助改进这个项目！