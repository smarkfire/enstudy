# EnStudy - 英语学习APP

一款基于 Flutter 的英语学习应用，通过拍照识别教材中的生词，利用 AI 智能分析生成学习卡片，并通过间隔重复算法和趣味游戏帮助用户高效记忆。

## 核心功能

- 📷 **拍照识词**：拍摄教材/书本页面，OCR 识别文字 + AI 分析生成卡片
- 🎯 **标记检测**：自动检测页面中的高亮/下划线标记，优先学习标记内容
- 🧠 **SM-2 复习调度**：科学的间隔重复算法，在最佳时间点复习
- 🎮 **8种趣味游戏**：配对消消乐、拼写挑战、听力选择、填空达人、速度对决、短语重组、单词射击、疯狂打地鼠
- 📊 **积分等级系统**：学习获得积分，升级解锁成就
- 📦 **数据导入导出**：完整的数据备份和恢复，换机不丢数据
- 🔔 **复习提醒**：本地通知提醒，不错过每日复习

## 技术栈

- **框架**：Flutter 3.44
- **状态管理**：Riverpod
- **数据库**：Drift (SQLite)
- **路由**：GoRouter
- **OCR**：百度OCR API
- **AI分析**：DeepSeek API
- **通知**：awesome_notifications

## 开始使用

```bash
# 安装依赖
flutter pub get

# 生成代码（freezed/drift/json_serializable）
dart run build_runner build --delete-conflicting-outputs

# 运行（Windows 桌面）
flutter run -d windows
# 运行（Chrome 浏览器）
flutter run -d chrome --web-browser-flag=--disable-web-security
# 运行测试
flutter test
```

## 项目结构

```
lib/
├── core/           # 核心模块（主题、路由、数据库、工具类）
├── features/       # 功能模块
│   ├── upload/     # 图片上传与解析
│   ├── cards/      # 卡片管理与复习
│   ├── games/      # 8种游戏
│   └── profile/    # 个人中心与数据管理
└── shared/         # 共享组件与服务
```

## API 配置

在 APP 的 **设置页面** 中配置：
- 百度OCR API Key + Secret Key
- DeepSeek API Key
