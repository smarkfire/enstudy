# EnStudy - 技术架构文档

## 1. 技术选型

### 1.1 整体技术栈

| 层次 | 技术选型 | 选型理由 |
|------|---------|---------|
| 移动端框架 | Flutter 3.x | 跨平台、UI一致性好、社区活跃、Dart性能优秀 |
| 编程语言 | Dart | Flutter官方语言，空安全支持完善 |
| 状态管理 | Riverpod 2.x (flutter_riverpod) | 编译时安全、可测试性强、依赖注入内置 |
| 本地数据库 | SQLite (drift) | 类型安全ORM、迁移方便、离线优先 |
| AI内容分析 | 千问多模态 (qwen3.5-omni-flash) | 阿里云DashScope服务，单次调用完成图片识别+内容分析，API兼容OpenAI格式 |
| 语音合成(TTS) | flutter_tts | 离线语音合成、支持英文发音、听力游戏核心依赖 |
| 音频播放 | audioplayers | 游戏音效播放（答对/答错提示音） |
| 本地通知 | awesome_notifications | 跨平台定时通知、Android/iOS双端支持、支持定时调度 |
| 路由管理 | go_router | 声明式路由、深链接支持 |
| 图片处理 | image / image_cropper | 图片压缩、裁剪 |
| 安全存储 | flutter_secure_storage | API Key加密存储（Android Keystore / iOS Keychain） |
| 数据备份 | share_plus + file_picker | 数据导出/导入 |
| 依赖注入 | Riverpod内置 | 统一管理，无需额外库 |
| 测试Mock | mocktail | 轻量级Mock框架，用于Repository/Service单元测试 |
| 短信验证码登录 | 阿里云短信服务 | 国内稳定、到达率高、支持验证码模板、按量计费成本低 |
| 后端服务 | Python + FastAPI | 高性能异步框架，自动生成OpenAPI文档，类型提示完善，开发效率高 |
| 后端数据库 | PostgreSQL | 功能最强大的开源关系型数据库，JSON支持、事务完善、扩展性强 |
| 缓存 | Redis | 验证码临时存储、Token黑名单、高频查询缓存 |
| 认证 | JWT (PyJWT) | 无状态认证，适合移动端，Token携带用户信息 |
| 环境变量配置 | flutter_dotenv | 敏感配置通过.env文件管理，不硬编码到代码中 |

### 1.2 项目结构

```
enstudy/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # App配置（主题、路由）
│   ├── core/                        # 核心层
│   │   ├── constants/               # 常量定义
│   │   │   ├── app_constants.dart
│   │   │   ├── game_constants.dart
│   │   │   └── api_config.dart      # API密钥默认配置
│   │   ├── extensions/              # Dart扩展方法
│   │   │   ├── context_ext.dart
│   │   │   └── datetime_ext.dart
│   │   ├── theme/                   # 主题配置
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   └── typography.dart
│   │   ├── network/                 # 网络层
│   │   │   └── cors_proxy_interceptor.dart  # CORS代理拦截器（Web跨域）
│   │   ├── database/                # 数据库层
│   │   │   ├── database_setup.dart        # 条件导入入口
│   │   │   ├── database_setup_io.dart     # 原生平台数据库初始化
│   │   │   └── database_setup_web.dart    # Web平台数据库初始化
│   │   ├── utils/                   # 工具类
│   │   │   ├── sm2_algorithm.dart   # SM-2间隔重复算法
│   │   │   ├── score_calculator.dart
│   │   │   ├── image_compressor.dart
│   │   │   ├── universal_io.dart    # dart:io条件导入
│   │   │   └── io_stub.dart        # Web端File/Directory存根
│   │   └── router/                  # 路由配置
│   │       └── app_router.dart
│   ├── features/                    # 功能模块层
│   │   ├── auth/                    # 用户认证
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── auth_api_service.dart    # 后端认证API调用
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart                   # 用户实体
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   └── login_page.dart             # 登录页（手机号+验证码）
│   │   │       └── providers/
│   │   │           └── auth_provider.dart          # 认证状态管理
│   │   ├── upload/                  # 图片上传与解析
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── upload_result.dart
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── ocr_service.dart         # 百度OCR封装
│   │   │   │   └── ai_analysis_service.dart  # DeepSeek AI封装
│   │   │   │   └── repositories/
│   │   │   │       └── upload_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── ocr_result.dart
│   │   │   │   └── repositories/
│   │   │   │       └── upload_repository.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── upload_page.dart
│   │   │       │   └── card_preview_page.dart
│   │   │       ├── widgets/
│   │   │       │   ├── upload_area.dart
│   │   │       │   └── card_preview_item.dart
│   │   │       └── providers/
│   │   │           └── upload_provider.dart
│   │   ├── cards/                   # 卡片管理
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── card_model.dart
│   │   │   │   │   └── card_model.g.dart
│   │   │   │   ├── datasources/
│   │   │   │   │   └── card_dao.dart
│   │   │   │   └── repositories/
│   │   │   │       └── card_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── card.dart
│   │   │   │   └── repositories/
│   │   │   │       └── card_repository.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── card_library_page.dart
│   │   │       │   └── card_detail_page.dart
│   │   │       ├── widgets/
│   │   │       │   ├── card_list_item.dart
│   │   │       │   └── card_filter_bar.dart
│   │   │       └── providers/
│   │   │           └── card_provider.dart
│   │   ├── games/                   # 游戏模块
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── game_session.dart
│   │   │   │   │   └── game_result.dart
│   │   │   │   └── repositories/
│   │   │   │       └── game_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── game_type.dart
│   │   │   │   └── repositories/
│   │   │   │       └── game_repository.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── game_lobby_page.dart
│   │   │       │   ├── game_play_page.dart
│   │   │       │   └── game_result_page.dart
│   │   │       ├── games/
│   │   │       │   ├── match_game.dart       # 配对消消乐
│   │   │       │   ├── spell_game.dart       # 拼写挑战
│   │   │       │   ├── listen_game.dart      # 听力选择
│   │   │       │   ├── fill_blank_game.dart  # 填空达人
│   │   │       │   ├── speed_game.dart       # 速度对决
│   │   │       │   ├── reorder_game.dart     # 短语重组
│   │   │       │   ├── shooting_game.dart    # 单词射击
│   │   │       │   └── whack_game.dart       # 疯狂打地鼠
│   │   │       ├── widgets/
│   │   │       │   ├── game_card.dart
│   │   │       │   └── score_board.dart
│   │   │       └── providers/
│   │   │           └── game_provider.dart
│   │   └── profile/                # 个人中心
│   │       ├── data/
│   │       │   ├── models/
│   │       │   │   ├── user_profile.dart
│   │       │   │   ├── daily_task.dart
│   │       │   │   └── export_data.dart     # 导出数据模型
│   │       │   ├── datasources/
│   │       │   │   └── data_transfer_service.dart  # 导入导出服务
│   │       │   └── repositories/
│   │       │       └── profile_repository_impl.dart
│   │       ├── domain/
│   │       │   └── repositories/
│   │       │       └── profile_repository.dart
│   │       └── presentation/
│   │           ├── pages/
│   │           │   ├── profile_page.dart
│   │           │   ├── data_management_page.dart  # 数据管理页面
│   │           │   ├── admin_user_list_page.dart   # 管理员-用户列表
│   │           │   └── purchase_page.dart          # 购买页面
│   │           ├── widgets/
│   │           │   ├── stat_card.dart
│   │           │   └── level_progress.dart
│   │           └── providers/
│   │               └── profile_provider.dart
│   └── shared/                      # 共享层
│       ├── widgets/                 # 通用组件
│       │   ├── app_scaffold.dart
│       │   ├── loading_overlay.dart
│       │   └── empty_state.dart
│       └── services/                # 通用服务
│           ├── notification_service.dart
│           ├── audio_service.dart
│           └── tts_service.dart
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── sounds/                      # 游戏音效
├── test/                            # 测试
│   ├── unit/                        # 单元测试
│   │   ├── core/
│   │   │   └── sm2_algorithm_test.dart
│   │   ├── features/
│   │   │   ├── upload/
│   │   │   ├── cards/
│   │   │   ├── games/
│   │   │   └── profile/
│   │   └── shared/
│   ├── widget/                      # Widget测试
│   └── integration/                 # 集成测试
├── docs/                            # 文档
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 2. 架构设计

### 2.1 整体架构

采用 **Clean Architecture** 分层架构，结合 **Feature-First** 模块化组织：

```
┌──────────────────────────────────────────────────┐
│                  Presentation Layer               │
│  (Pages, Widgets, Providers/State Management)     │
├──────────────────────────────────────────────────┤
│                  Domain Layer                     │
│  (Entities, Repository Interfaces, Use Cases)     │
├──────────────────────────────────────────────────┤
│                  Data Layer                       │
│  (Models, DAOs, Repository Implementations,       │
│   External Services: OCR, AI API)                 │
└──────────────────────────────────────────────────┘
```

**依赖规则：** Presentation → Domain ← Data（Domain层不依赖任何外层）

### 2.2 状态管理架构

使用 Riverpod 2.x 进行状态管理：

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Widget     │────▶│   Provider   │────▶│  Repository  │
│   (UI)       │◀────│  (State)     │◀────│  (Data)      │
└──────────────┘     └──────────────┘     └──────────────┘
       watch/              notify              fetch
       read                state               persist
```

**Provider分类：**
- `NotifierProvider`：复杂状态（卡片列表、游戏状态）
- `FutureProvider`：异步数据（AI分析结果）
- `StreamProvider`：实时数据（计时器）
- `Provider`：依赖注入（Repository、Service实例）

### 2.3 数据流架构

#### 2.3.1 图片上传与解析流程

```
用户选择图片
     │
     ▼
图片压缩 (image_compressor)
     │
     ▼
┌────────────────────────────────┐
│  OCR 识别 (百度OCR API)        │
│  - 通用文字识别                 │
│  - 返回文字内容+位置坐标        │
│  - 支持中英文混合识别           │
└────────────────────────────────┘
     │
     ▼
┌────────────────────────────────┐
│  选择解析方式                    │
│  ┌────────────┐ ┌────────────┐ │
│  │ 智能识别    │ │ 自定义要求  │ │
│  │ (默认模式)  │ │ (用户输入)  │ │
│  └─────┬──────┘ └─────┬──────┘ │
└────────┼──────────────┼────────┘
         │              │
         ▼              ▼
┌──────────────┐ ┌──────────────────────────┐
│ 默认Prompt   │ │ 自定义Prompt              │
│ - 标记内容匹配│ │ - 用户输入文字要求         │
│ - 翻译+音标   │ │ - AI按自定义要求分析       │
│ - 生成例句    │ │ - 灵活定制输出格式         │
│ - 推荐补充    │ │                          │
└──────┬───────┘ └────────────┬─────────────┘
       │                      │
       └──────────┬───────────┘
                  ▼
┌────────────────────────────────┐
│  AI 内容分析 (DeepSeek API)     │
│  - 根据 Prompt 模式分析         │
│  - 智能识别：翻译标记内容+推荐   │
│  - 自定义要求：按用户需求分析    │
└────────────────────────────────┘
     │
     ▼
卡片预览（用户确认/编辑）
     │
     ▼
保存到本地 SQLite 数据库
```

**解析方式说明：**

| 模式 | 触发方式 | Prompt来源 | 适用场景 |
|------|---------|-----------|---------|
| 智能识别 | 默认选择 | 内置默认Prompt | 标记了生词/短语的学习材料 |
| 自定义要求 | 用户主动选择 | 用户输入文字要求 | 有特定分析需求，如"只提取动词"、"按主题分类"等 |

#### 2.3.2 复习调度流程

```
每日启动APP
     │
     ▼
查询到期卡片 (nextReview <= today)
     │
     ▼
┌────────────────────────────────┐
│  卡片排序策略                    │
│  1. 优先级：逾期 > 到期 > 新卡   │
│  2. 难度权重：低正确率优先        │
│  3. 间隔因子：短间隔优先          │
└────────────────────────────────┘
     │
     ▼
推送到今日复习列表
     │
     ▼
用户通过游戏/直接复习
     │
     ▼
记录答题结果
     │
     ▼
┌────────────────────────────────┐
│  SM-2 算法计算                  │
│  - 更新 easeFactor              │
│  - 计算下次复习间隔              │
│  - 更新 nextReview 日期          │
│  - 更新卡片状态                  │
└────────────────────────────────┘
     │
     ▼
持久化到数据库
```

#### 2.3.3 手机号验证码登录流程

```
用户输入手机号，点击"获取验证码"
     │
     ▼
┌────────────────────────────────┐
│  客户端调用后端API               │
│  POST /api/auth/send-code      │
│  - 参数：phone                  │
│  - 后端校验手机号格式            │
│  - 后端检查发送频率限制          │
└────────────────────────────────┘
     │
     ▼
┌────────────────────────────────┐
│  后端调用阿里云短信服务          │
│  - 生成6位随机验证码            │
│  - 存入Redis（5分钟过期）       │
│  - 调用阿里云SMS API发送短信    │
│  - 返回发送成功                 │
└────────────────────────────────┘
     │
     ▼
用户输入验证码，点击"登录"
     │
     ▼
┌────────────────────────────────┐
│  客户端调用后端API               │
│  POST /api/auth/login          │
│  - 参数：phone + code           │
└────────────────────────────────┘
     │
     ▼
┌────────────────────────────────┐
│  后端校验验证码                  │
│  - 从Redis读取验证码            │
│  - 对比用户输入                 │
│  - 校验失败3次后验证码失效       │
│  - 校验成功后删除验证码          │
└────────────────────────────────┘
     │ (验证码正确)
     ▼
┌────────────────────────────────┐
│  后端查询/创建用户               │
│  - 查询users表是否存在该手机号  │
│  - 存在 → 更新last_login        │
│  - 不存在 → 创建新用户(默认10次)│
└────────────────────────────────┘
     │
     ▼
┌────────────────────────────────┐
│  后端生成JWT Token              │
│  - payload: userId, phone,      │
│    isAdmin, exp(7天)            │
│  - 返回 Token + 用户信息        │
└────────────────────────────────┘
     │
     ▼
┌────────────────────────────────┐
│  客户端保存登录状态              │
│  - Token存入flutter_secure_     │
│    storage                      │
│  - 更新AuthProvider状态         │
│  - 导航到主页                    │
└────────────────────────────────┘
```

#### 2.3.4 AI次数扣减流程

**核心规则：每次使用"智能解析"功能（上传图片→AI分析生成卡片）消耗1次AI使用次数，无论生成多少张卡片。智能识别和自定义要求解析均消耗1次。扣减时同步调用后端API，确保服务端数据一致。**

```
用户发起智能解析请求（分析图片并生成卡片）
     │
     ▼
┌────────────────────────────────┐
│  检查剩余AI次数                  │
│  - 优先从本地缓存读取            │
│  - quota > 0 → 允许继续         │
│  - quota <= 0 → 提示购买/联系   │
└────────────────────────────────┘
     │ (quota > 0)
     ▼
执行AI分析（调用千问多模态API）
     │
     ▼
┌────────────────────────────────┐
│  分析成功后扣减AI次数            │
│  - 调用后端API扣减（服务端校验） │
│  - POST /api/user/consume-quota│
│  - 后端原子性扣减（WHERE > 0）  │
│  - 返回扣减后剩余次数            │
│  - 客户端更新本地缓存            │
└────────────────────────────────┘
     │ (扣减成功)
     ▼
返回分析结果给用户预览
```

**购买套餐阶梯定价（购买越多，单价越低）：**

| 套餐 | AI使用次数 | 价格 | 单价 | 折扣 |
|------|-----------|------|------|------|
| 体验包 | 50次 | 5元 | 0.10元/次 | - |
| 基础包 | 100次 | 8元 | 0.08元/次 | 省20% |
| 进阶包 | 300次 | 18元 | 0.06元/次 | 省40% |
| 尊享包 | 500次 | 25元 | 0.05元/次 | 省50% |

#### 2.3.5 管理员充值流程

```
管理员登录（后端验证isAdmin身份）
     │
     ▼
进入用户管理页面
     │
     ▼
┌────────────────────────────────┐
│  调用后端API获取用户列表         │
│  GET /api/admin/users           │
│  - 需要管理员Token鉴权          │
│  - 返回用户列表+AI次数+积分     │
└────────────────────────────────┘
     │
     ▼
┌────────────────────────────────┐
│  管理员修改用户AI次数            │
│  POST /api/admin/update-quota  │
│  - 参数：userId, quota/change   │
│  - 后端原子性更新               │
│  - 记录变更审计日志             │
│  - 返回更新后的数据             │
└────────────────────────────────┘
     │
     ▼
客户端刷新用户数据
```

#### 2.3.6 数据同步流程

**核心原则：关键数据（积分、AI次数）以服务端为准，客户端本地缓存用于快速展示，变化时同步更新服务端。**

```
┌──────────────────────────────────────────────────┐
│                  数据同步策略                       │
│                                                    │
│  登录时同步：                                      │
│  ┌──────────────┐     ┌──────────────┐            │
│  │  客户端       │────▶│  后端API      │            │
│  │  登录成功     │     │ GET /api/user │            │
│  │              │◀────│ /profile      │            │
│  │  更新本地缓存 │     │ 返回最新数据   │            │
│  └──────────────┘     └──────────────┘            │
│                                                    │
│  数据变化时同步：                                   │
│  ┌──────────────┐     ┌──────────────┐            │
│  │  AI次数扣减   │────▶│  POST /api/  │            │
│  │  积分变化     │     │  user/sync   │            │
│  │              │◀────│  返回最新数据  │            │
│  │  更新本地缓存 │     │              │            │
│  └──────────────┘     └──────────────┘            │
│                                                    │
│  定时同步（可选）：                                 │
│  ┌──────────────┐     ┌──────────────┐            │
│  │  每5分钟/     │────▶│  GET /api/   │            │
│  │  页面恢复时   │     │  user/profile│            │
│  │              │◀────│  返回最新数据  │            │
│  │  更新本地缓存 │     │              │            │
│  └──────────────┘     └──────────────┘            │
└──────────────────────────────────────────────────┘
```

#### 2.3.7 后端API接口设计

**基础URL：** `https://api.enstudy.com`（开发环境可配置）

| 接口 | 方法 | 说明 | 鉴权 |
|------|------|------|------|
| `/api/auth/send-code` | POST | 发送短信验证码 | 无 |
| `/api/auth/login` | POST | 验证码登录 | 无 |
| `/api/user/profile` | GET | 获取用户信息（积分、AI次数等） | JWT |
| `/api/user/consume-quota` | POST | 扣减AI次数 | JWT |
| `/api/user/sync` | POST | 同步积分等数据变化 | JWT |
| `/api/admin/users` | GET | 获取用户列表 | 管理员JWT |
| `/api/admin/update-quota` | POST | 修改用户AI次数 | 管理员JWT |

**请求/响应示例：**

```json
// POST /api/auth/send-code
// Request:
{ "phone": "13800138000" }
// Response:
{ "success": true, "message": "验证码已发送" }

// POST /api/auth/login
// Request:
{ "phone": "13800138000", "code": "123456" }
// Response:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "phone": "13800138000",
    "nickname": "用户138****8000",
    "avatarUrl": "",
    "aiQuota": 10,
    "totalScore": 0,
    "isAdmin": false
  }
}

// GET /api/user/profile
// Headers: Authorization: Bearer <token>
// Response:
{
  "id": "uuid",
  "phone": "13800138000",
  "nickname": "用户138****8000",
  "avatarUrl": "",
  "aiQuota": 8,
  "totalScore": 320,
  "level": 3,
  "isAdmin": false
}

// POST /api/user/consume-quota
// Headers: Authorization: Bearer <token>
// Response:
{
  "success": true,
  "remainingQuota": 7
}

// POST /api/admin/update-quota
// Headers: Authorization: Bearer <admin-token>
// Request:
{ "userId": "uuid", "change": 50 }
// Response:
{
  "success": true,
  "newQuota": 57
}
```

---

## 3. 数据库设计

### 3.1 ER图

```
┌──────────────┐       ┌──────────────┐
│    cards     │       │   sources    │
├──────────────┤       ├──────────────┤
│ id (PK)      │◀──────│ id (PK)      │
│ type         │       │ image_path   │
│ content      │       │ created_at   │
│ translation  │       └──────────────┘
│ phonetic     │
│ example      │
│ example_trans│       ┌──────────────┐
│ source_id(FK)│       │ game_sessions│
│ tags         │       ├──────────────┤
│ difficulty   │       │ id (PK)      │
│ created_at   │       │ game_type    │
│ review_count │       │ started_at   │
│ correct_count│       │ ended_at     │
│ next_review  │       │ score        │
│ interval     │       │ total_q      │
│ ease_factor  │       │ correct_q    │
│ status       │       └──────┬───────┘
└──────┬───────┘              │
       │                      │
       │    ┌─────────────────┘
       │    │
       ▼    ▼
┌──────────────┐       ┌──────────────┐
│ review_logs  │       │  user_profile│       ┌──────────────┐
├──────────────┤       ├──────────────┤       │    users     │
│ id (PK)      │       │ id (PK)      │       ├──────────────┤
│ card_id (FK) │       │ user_id (FK) │◀──────│ id (PK)      │
│ session_id(FK)│      │ total_score  │       │ phone        │
│ quality      │       │ level        │       │ nickname     │
│ answered_at  │       │ streak_days  │       │ avatar_url   │
│ game_type    │       │ last_checkin │       │ ai_quota     │
└──────────────┘       │ new_cards_day│       │ is_admin     │
                       │ remind_time  │       │ created_at   │
                       └──────────────┘       │ last_login   │
                                              └──────────────┘
```

### 3.2 表结构详细设计

#### cards 表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | TEXT | PK, UUID | 唯一标识 |
| type | TEXT | NOT NULL | word/phrase/grammar |
| content | TEXT | NOT NULL | 原文内容 |
| translation | TEXT | | 中文翻译 |
| phonetic | TEXT | | 音标 |
| example | TEXT | | 例句 |
| example_translation | TEXT | | 例句翻译 |
| source_id | TEXT | FK | 来源图片ID |
| tags | TEXT | | JSON数组，标签 |
| difficulty | INTEGER | DEFAULT 3 | 难度1-5 |
| created_at | INTEGER | NOT NULL | 创建时间戳 |
| review_count | INTEGER | DEFAULT 0 | 复习次数 |
| correct_count | INTEGER | DEFAULT 0 | 正确次数 |
| next_review | INTEGER | NOT NULL | 下次复习时间戳 |
| interval | REAL | DEFAULT 1.0 | 复习间隔（天） |
| ease_factor | REAL | DEFAULT 2.5 | SM-2难度因子 |
| status | TEXT | DEFAULT 'new' | new/learning/review/mastered |

#### sources 表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | TEXT | PK, UUID | 唯一标识 |
| image_path | TEXT | NOT NULL | 图片本地路径 |
| thumbnail_path | TEXT | | 缩略图路径 |
| created_at | INTEGER | NOT NULL | 创建时间戳 |

#### game_sessions 表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | TEXT | PK, UUID | 唯一标识 |
| game_type | TEXT | NOT NULL | 游戏类型 |
| started_at | INTEGER | NOT NULL | 开始时间 |
| ended_at | INTEGER | | 结束时间 |
| score | INTEGER | DEFAULT 0 | 得分 |
| total_questions | INTEGER | DEFAULT 0 | 总题数 |
| correct_questions | INTEGER | DEFAULT 0 | 正确数 |

#### review_logs 表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | TEXT | PK, UUID | 唯一标识 |
| card_id | TEXT | FK, NOT NULL | 关联卡片 |
| session_id | TEXT | FK | 关联游戏会话 |
| quality | INTEGER | NOT NULL | 答题质量0-5 |
| answered_at | INTEGER | NOT NULL | 答题时间 |
| game_type | TEXT | | 来源游戏类型 |

#### users 表（服务端PostgreSQL）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID主键 |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | 手机号，唯一标识 |
| nickname | VARCHAR(50) | DEFAULT '' | 用户昵称 |
| avatar_url | VARCHAR(500) | DEFAULT '' | 头像URL |
| ai_quota | INT | DEFAULT 10 | AI智能解析剩余次数 |
| total_score | INT | DEFAULT 0 | 累计积分 |
| level | INT | DEFAULT 1 | 用户等级 |
| is_admin | TINYINT | DEFAULT 0 | 是否管理员(0否/1是) |
| created_at | DATETIME | NOT NULL | 注册时间 |
| last_login | DATETIME | NULL | 最后登录时间 |

**说明：**
- 用户表存储在服务端PostgreSQL数据库，客户端不再维护本地Users表
- 手机号为唯一标识，注册后不可更改
- 新用户注册默认赠送10次AI使用次数
- total_score 记录用户通过学习游戏等获得的累计积分
- level 根据积分自动计算
- is_admin 由后端管理，初始管理员通过数据库直接设置

#### user_profile 表（本地SQLite）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | TEXT | PK | 固定为'default' |
| user_id | TEXT | | 关联服务端用户ID |
| total_score | INTEGER | DEFAULT 0 | 总积分（本地缓存） |
| level | INTEGER | DEFAULT 1 | 等级 |
| streak_days | INTEGER | DEFAULT 0 | 连续打卡天数 |
| last_checkin | INTEGER | | 上次打卡时间 |
| new_cards_per_day | INTEGER | DEFAULT 10 | 每日新卡数 |
| remind_time | TEXT | DEFAULT '08:00' | 提醒时间 |

**说明：**
- user_profile 仍保留在本地SQLite，存储学习偏好和打卡等本地数据
- total_score/level 本地缓存，登录时从服务端同步

---

## 4. 关键技术实现

### 4.1 SM-2 间隔重复算法

```dart
class Sm2Algorithm {
  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;

  Sm2Result calculate({
    required int quality,       // 0-5
    required int reviewCount,
    required double easeFactor,
    required double interval,
  }) {
    double newEaseFactor = easeFactor;
    double newInterval = interval;
    String newStatus = 'review';

    if (quality >= 3) {
      if (reviewCount == 0) {
        newInterval = 1;
      } else if (reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = interval * newEaseFactor;
      }
      newEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < minEaseFactor) newEaseFactor = minEaseFactor;
    } else {
      newInterval = 1;
      newStatus = 'learning';
    }

    return Sm2Result(
      interval: newInterval,
      easeFactor: newEaseFactor,
      status: newStatus,
    );
  }
}
```

### 4.2 OCR + 标记识别方案

```
方案：百度OCR通用文字识别 + 自研标记检测

步骤：
1. 调用百度OCR通用文字识别API
   - 接口：https://aip.baidubce.com/rest/2.0/ocr/v1/general
   - 返回每个文字块的边界框 (location) 和文字内容 (words)
   - 支持中英文混合识别，返回位置坐标

2. 颜色分析检测标记区域（本地处理）
   - 遍历图片像素，检测高亮色（黄色、粉色等常见标记色）
   - 生成标记区域的掩码 (mask)
   - 提取标记区域的边界矩形

3. 文字与标记区域匹配
   - 计算百度OCR返回的文字块边界框与标记区域的重叠度 (IoU)
   - 重叠度超过阈值的文字块视为"已标记"
   - 根据标记颜色分类：黄色→生词，绿色→短语，粉色→语法

4. 输出结构化结果
   - markedItems: 用户标记的内容列表
   - unmarkedText: 未标记的文字（供AI分析）

百度OCR接入说明：
- 需要在百度智能云创建应用，获取 API Key 和 Secret Key
- 通过 API Key 获取 Access Token（有效期30天，需定时刷新）
- 免费额度：通用文字识别每月1000次
- 识别速度：单张图片约1-3秒
```

### 4.3 AI 内容分析接口设计

```dart
abstract class AiAnalysisService {
  Future<AiAnalysisResult> analyze({
    required String ocrText,
    required List<String> markedContents,
    required List<MarkType> markTypes,
    String? customPrompt,
  });
}

// DeepSeek API 实现
// - API地址：https://api.deepseek.com/v1/chat/completions
// - 模型：deepseek-chat
// - 兼容 OpenAI API 格式，可直接使用 dio 调用
// - 价格：输入 ¥1/百万token，输出 ¥2/百万token（远低于GPT-4）
// - 支持中文理解和翻译，效果优秀
//
// customPrompt 参数说明：
// - 传入时：使用用户自定义Prompt进行分析（自定义要求模式）
// - 不传时：使用内置默认Prompt进行分析（智能识别模式）

// 默认 Prompt 模板（智能识别模式）
const analysisPrompt = '''
你是一个英语学习助手。请分析以下来自学生学习材料的文本。

OCR识别文本：
$ocrText

学生标记的内容（这些是他们不认识的）：
$markedContents

请提供：
1. 对每个标记项：中文翻译、音标（单词类型）、例句
2. 从文本中推荐最多3个学生可能不认识的重要单词/短语

请以JSON格式返回：
{
  "marked_analysis": [
    {
      "content": "word",
      "translation": "翻译",
      "phonetic": "/音标/",
      "example": "Example sentence.",
      "example_translation": "例句翻译"
    }
  ],
  "recommendations": [
    {
      "content": "word",
      "type": "word|phrase|grammar",
      "translation": "翻译",
      "phonetic": "/音标/",
      "example": "Example sentence.",
      "example_translation": "例句翻译",
      "reason": "为什么推荐"
    }
  ]
}
''';

// DeepSeek API 调用示例
class DeepSeekAiService implements AiAnalysisService {
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  @override
  Future<AiAnalysisResult> analyze({
    required String ocrText,
    required List<String> markedContents,
    required List<MarkType> markTypes,
    String? customPrompt,
  }) async {
    // customPrompt 不为空时使用自定义Prompt，否则使用默认Prompt
    // 使用 dio 发送 POST 请求
    // Header: Authorization: Bearer $apiKey
    // Body: { model: "deepseek-chat", messages: [...] }
    // 解析返回的 JSON 结果
  }
}
```

**备选AI方案（如DeepSeek不可用）：**

| 方案 | API地址 | 模型 | 特点 |
|------|---------|------|------|
| 通义千问 | https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation | qwen-turbo | 阿里云服务，稳定可靠 |
| 智谱AI | https://open.bigmodel.cn/api/paas/v4/chat/completions | glm-4-flash | 免费额度多 |
| 月之暗面 | https://api.moonshot.cn/v1/chat/completions | moonshot-v1-8k | 长文本处理强 |

所有备选方案均兼容 OpenAI API 格式，切换成本极低，只需修改 baseUrl 和模型名。

### 4.4 本地通知与提醒

```dart
class NotificationService {
  Future<void> initialize() async {
    // 使用 awesome_notifications 初始化
    // Android/iOS 双端支持定时通知
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'review_reminder',
          channelName: '复习提醒',
          channelDescription: '每日复习提醒通知',
          defaultColor: AppColors.primary,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'streak_warning',
          channelName: '打卡提醒',
          channelDescription: '连续打卡即将中断提醒',
          importance: NotificationImportance.Default,
        ),
      ],
    );
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // awesome_notifications 支持双端定时调度
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'review_reminder',
        title: '该复习啦！',
        body: '你有待复习的卡片，快来打卡吧 📚',
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  Future<void> showOverdueReminder({
    required int overdueCount,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'review_reminder',
        title: '你有$overdueCount张逾期卡片',
        body: '再不复习就要忘记啦！',
      ),
    );
  }

  Future<void> showStreakWarning() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: 'streak_warning',
        title: '打卡即将中断！',
        body: '今天还没打卡，连续记录就要断了 🔥',
      ),
    );
  }
}
```

### 4.5 数据导入导出方案

```dart
class DataTransferService {
  final AppDatabase _db;

  Future<File> exportData({bool includeImages = false}) async {
    final cards = await _db.cardDao.getAllCards();
    final sources = await _db.sourceDao.getAllSources();
    final reviewLogs = await _db.reviewLogDao.getAllLogs();
    final gameSessions = await _db.gameSessionDao.getAllSessions();
    final profile = await _db.userProfileDao.getProfile();

    final exportData = ExportData(
      version: '1.0',
      exportTime: DateTime.now().toUtc().toIso8601String(),
      appVersion: '1.0.0',
      cards: cards,
      sources: includeImages
          ? await _encodeImagesToBase64(sources)
          : sources.map((s) => s.copyWith(imageBase64: null)).toList(),
      reviewLogs: reviewLogs,
      gameSessions: gameSessions,
      userProfile: profile,
    );

    final jsonStr = jsonEncode(exportData.toJson());
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/enstudy_backup_$timestamp.json');
    await file.writeAsString(jsonStr);
    return file;
  }

  Future<ImportPreview> previewImport(String filePath) async {
    final file = File(filePath);
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final exportData = ExportData.fromJson(data);

    return ImportPreview(
      cardCount: exportData.cards.length,
      sourceCount: exportData.sources.length,
      reviewLogCount: exportData.reviewLogs.length,
      gameSessionCount: exportData.gameSessions.length,
      hasImages: exportData.sources.any((s) => s.imageBase64 != null),
      version: exportData.version,
    );
  }

  Future<ImportResult> importData(
    String filePath, {
    ConflictStrategy strategy = ConflictStrategy.keepNewer,
  }) async {
    final file = File(filePath);
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final exportData = ExportData.fromJson(data);

    int imported = 0;
    int skipped = 0;
    int conflicted = 0;

    await _db.transaction(() async {
      for (final card in exportData.cards) {
        final existing = await _db.cardDao.getCardById(card.id);
        if (existing == null) {
          await _db.cardDao.insertCard(card);
          imported++;
        } else {
          conflicted++;
          switch (strategy) {
            case ConflictStrategy.keepNewer:
              if (card.createdAt > existing.createdAt) {
                await _db.cardDao.updateCard(card);
              }
              break;
            case ConflictStrategy.overwrite:
              await _db.cardDao.updateCard(card);
              imported++;
              break;
            case ConflictStrategy.skip:
              skipped++;
              break;
          }
        }
      }
    });

    return ImportResult(imported: imported, skipped: skipped, conflicted: conflicted);
  }
}

enum ConflictStrategy { keepNewer, overwrite, skip }
```

**导入导出流程：**

```
导出流程：
用户点击"导出" → 选择是否含图片 → 查询数据库 → 序列化为JSON
→ 写入临时文件 → share_plus 分享（微信/QQ/邮件/保存本地）

导入流程：
用户点击"导入" → file_picker 选择文件 → 解析JSON → 版本校验
→ 预览数据量 → 用户确认 → 事务写入数据库 → 显示导入结果
 ```

---

## 5. 第三方依赖清单

| 依赖包 | 版本 | 用途 |
|--------|------|------|
| flutter_riverpod | ^2.5.0 | 状态管理 |
| go_router | ^14.0.0 | 路由管理 |
| drift | ^2.18.0 | SQLite ORM |
| sqlite3_flutter_libs | ^0.5.0 | SQLite原生库（Android/iOS/Windows） |
| drift/wasm | (drift内置) | Web平台SQLite WASM支持（sqlite3.wasm + drift_worker.js） |
| dio | ^5.4.0 | HTTP客户端（百度OCR + DeepSeek AI） |
| image_picker | ^1.0.0 | 图片选择/拍照 |
| image | ^4.0.0 | 图片处理（压缩+标记检测） |
| image_cropper | ^8.0.0 | 图片裁剪 |
| flutter_tts | ^4.0.0 | 语音合成（单词发音、听力游戏） |
| audioplayers | ^6.0.0 | 音频播放（游戏音效） |
| flutter_secure_storage | ^9.2.0 | API Key安全存储 |
| awesome_notifications | ^0.9.0 | 本地通知（Android/iOS双端定时通知） |
| share_plus | ^9.0.0 | 分享/导出 |
| file_picker | ^8.0.0 | 文件选择 |
| path_provider | ^2.1.0 | 获取临时目录/应用目录（导入导出文件存储） |
| archive | ^4.0.0 | 文件压缩（含图片导出时压缩为zip） |
| freezed | ^2.5.0 | 不可变数据类 |
| json_serializable | ^6.8.0 | JSON序列化 |
| build_runner | ^2.4.0 | 代码生成 |
| cached_network_image | ^3.3.0 | 图片缓存 |
| flutter_animate | ^4.5.0 | 动画效果 |
| confetti | ^0.7.0 | 庆祝动画（游戏结算） |
| mocktail | ^1.0.0 | 单元测试Mock框架 |
| fluwx | ^4.0.0 | 微信SDK（登录、分享） |
| flutter_dotenv | ^5.1.0 | 环境变量配置（.env文件加载） |
| flutter_test | SDK | Widget测试和集成测试 |

---

## 6. 安全与性能

### 6.1 安全策略

**API密钥双源配置模式：**

采用 `ApiConfig` 默认值 + `flutter_secure_storage` 用户覆盖的双源配置模式：

```
┌──────────────────────────────────────────────────┐
│              API密钥获取流程                       │
│                                                    │
│  1. 优先从 flutter_secure_storage 读取用户配置     │
│     └─ 有值 → 使用用户自定义密钥                   │
│     └─ 无值 → 回退到 ApiConfig 默认值              │
│                                                    │
│  ApiConfig (api_config.dart)                       │
│  ├── 百度OCR API Key 默认值                        │
│  ├── 百度OCR Secret Key 默认值                     │
│  ├── DeepSeek API Key 默认值                       │
│  └── adminWechatIds 管理员微信号列表                │
│                                                    │
│  flutter_secure_storage (用户覆盖)                  │
│  ├── key: baidu_ocr_api_key                        │
│  ├── key: baidu_ocr_secret_key                     │
│  └── key: deepseek_api_key                         │
│                                                    │
│  .env 环境变量配置                                  │
│  └── ADMIN_WECHAT_IDS=smarkfire,admin2             │
└──────────────────────────────────────────────────┘
```

```dart
// api_config.dart - API密钥默认配置
class ApiConfig {
  static const String baiduOcrApiKey = 'default_baidu_api_key';
  static const String baiduOcrSecretKey = 'default_baidu_secret_key';
  static const String deepseekApiKey = 'default_deepseek_api_key';

  // 管理员微信号列表（从.env文件读取 ADMIN_WECHAT_IDS）
  static List<String> get adminWechatIds {
    const ids = String.fromEnvironment('ADMIN_WECHAT_IDS', defaultValue: '');
    if (ids.isEmpty) return [];
    return ids.split(',').map((id) => id.trim()).toList();
  }
}

// 密钥获取逻辑
Future<String> getApiKey(String key, String defaultValue) async {
  final stored = await flutterSecureStorage.read(key: key);
  return stored ?? defaultValue;
}
```

**其他安全措施：**
- 本地数据库可选加密（SQLCipher）
- 图片存储在应用沙盒目录，其他应用不可访问
- 网络请求仅在与百度OCR/DeepSeek服务通信时使用，核心功能离线可用
- Web平台安全存储使用 Window.localStorage，敏感数据需注意XSS防护
- JWT Token安全存储，使用flutter_secure_storage加密保存，不明文存储到本地文件
- AI次数扣减使用乐观锁，防止并发超扣（UPDATE WHERE ai_quota > 0，检查affected rows）
- 管理员操作需验证admin身份（后端JWT Token中包含isAdmin字段，API层校验）
- 次数变更记录审计日志，包含操作人、目标用户、变更前后值、操作时间

### 6.2 性能优化
- 图片上传前压缩至 500KB 以内
- OCR 在独立 Isolate 中执行，不阻塞UI
- 卡片列表使用 ListView.builder 懒加载
- 数据库查询添加索引（next_review, status, created_at）
- AI 请求结果本地缓存，避免重复调用
- 游戏动画使用 60fps，避免卡顿

---

## 7. 跨平台兼容性

### 7.1 多平台支持总览

所有核心依赖均支持 Android、iOS、Windows 桌面和 Web 四个平台：

| 依赖 | Android | iOS | Windows | Web | 备注 |
|------|---------|-----|---------|-----|------|
| Flutter/Dart | ✅ | ✅ | ✅ | ✅ | 原生跨平台 |
| drift (SQLite) | ✅ | ✅ | ✅ | ✅ | 原生：sqlite3_flutter_libs；Web：WasmDatabase |
| dio | ✅ | ✅ | ✅ | ✅ | 纯Dart实现 |
| image_picker | ✅ | ✅ | ✅ | ⚠️ | Web支持有限，需使用blob URL |
| image | ✅ | ✅ | ✅ | ✅ | 纯Dart实现 |
| image_cropper | ✅ | ✅ | ⚠️ | ❌ | iOS需配置UCrop；Web不支持 |
| flutter_tts | ✅ | ✅ | ✅ | ⚠️ | Web支持有限 |
| audioplayers | ✅ | ✅ | ✅ | ✅ | 多平台音频 |
| awesome_notifications | ✅ | ✅ | ❌ | ❌ | 仅Android/iOS支持 |
| flutter_secure_storage | ✅ | ✅ | ✅ | ⚠️ | Web使用Window.localStorage |
| share_plus | ✅ | ✅ | ✅ | ✅ | 多平台分享 |
| file_picker | ✅ | ✅ | ✅ | ✅ | 多平台文件选择 |

### 7.2 iOS 额外配置清单

构建 iOS 版本时，需要在 `ios/Runner/Info.plist` 中添加以下配置：

```xml
<!-- 图片选择 - 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄学习资料</string>

<!-- 图片选择 - 相册权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择学习资料图片</string>

<!-- TTS 语音合成 - 后台音频 -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- 通知权限（awesome_notifications 自动处理） -->

<!-- image_cropper 配置 -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存裁剪后的图片</string>
```

在 `ios/Podfile` 中确保最低版本：

```ruby
platform :ios, '13.0'
```

### 7.3 Android 额外配置清单

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- 相册读取权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- 通知权限 (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET" />
```

在 `android/app/build.gradle` 中确保：

```groovy
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 7.4 平台差异注意事项

| 功能 | Android | iOS | Windows | Web | 差异处理 |
|------|---------|-----|---------|-----|---------|
| 定时通知 | 完全支持 | 支持但需用户授权 | 不支持 | 不支持 | awesome_notifications 统一处理，Web/Windows降级处理 |
| TTS发音 | 系统TTS引擎 | AVSpeechSynthesizer | 系统TTS引擎 | 浏览器Speech API | flutter_tts 统一封装 |
| 安全存储 | Android Keystore | iOS Keychain | Windows DPAPI | Window.localStorage | flutter_secure_storage 统一封装 |
| 文件存储 | 应用内部存储 | 应用沙盒 | 应用数据目录 | 浏览器IndexedDB | path_provider统一获取路径，Web使用blob URL |
| 图片压缩 | 纯Dart处理 | 纯Dart处理 | 纯Dart处理 | 纯Dart处理 | 无差异 |
| 数据库 | NativeDatabase | NativeDatabase | NativeDatabase | WasmDatabase | 条件导入自动切换 |
| 图片路径 | 本地文件路径 | 本地文件路径 | 本地文件路径 | blob URL | universal_io + io_stub 统一封装 |
| 网络请求 | 直连 | 直连 | 直连 | 需CORS代理 | CorsProxyInterceptor处理跨域 |

### 7.5 Web 平台支持

Web 平台基于 Flutter Web 构建，在数据库、网络、图片等方面有特殊处理：

#### 7.5.1 数据库

Web 平台使用 `drift` 的 WASM 方案替代原生 SQLite：

```dart
// database_setup_web.dart
import 'package:drift/wasm.dart';

DatabaseConnection createDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'enstudy_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // 部分浏览器可能不支持OPFS等特性，记录警告
    }

    return result.resolvedExecutor;
  }));
}
```

**部署要求：**
- `sqlite3.wasm` 和 `drift_worker.js` 需放置在Web应用的根目录下
- 推荐使用 Origin Private File System (OPFS) 以获得最佳性能
- 不支持OPFS的浏览器将回退到 IndexedDB 存储

#### 7.5.2 CORS 跨域处理

Web 平台直接调用百度OCR/DeepSeek API会遇到CORS限制，通过 `CorsProxyInterceptor` 解决：

```dart
// cors_proxy_interceptor.dart
class CorsProxyInterceptor extends Interceptor {
  static const String _proxyUrl = 'https://cors-proxy.example.com/';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kIsWeb) {
      options.path = '$_proxyUrl${options.path}';
    }
    handler.next(options);
  }
}
```

**说明：**
- 仅在Web平台（`kIsWeb`）启用代理
- 原生平台（Android/iOS/Windows）直连API，不经过代理
- 需要自行部署CORS代理服务，或使用公共代理

#### 7.5.3 图片处理

Web 平台无法使用本地文件路径，采用 blob URL 方案：

```dart
// io_stub.dart - Web端File/Directory存根
// 提供与dart:io兼容的空实现，确保编译通过

// 图片上传流程中：
// - 原生平台：使用本地文件路径 (File.path)
// - Web平台：使用 blob URL (blob:https://...)
// - 通过 universal_io.dart 条件导入统一封装
```

#### 7.5.4 Web 平台限制

| 功能 | 状态 | 说明 |
|------|------|------|
| 标记检测 | ❌ 不支持 | Web端无法进行像素级颜色分析，仅支持OCR文字识别 |
| 本地通知 | ❌ 不支持 | awesome_notifications 不支持Web，需降级为页面内提醒 |
| 图片裁剪 | ❌ 不支持 | image_cropper 不支持Web，可考虑Web端替代方案 |
| 数据库 | ✅ 支持 | 使用WasmDatabase，需部署wasm文件 |
| AI分析 | ✅ 支持 | 需CORS代理 |
| OCR识别 | ✅ 支持 | 需CORS代理 |
| 游戏模块 | ✅ 支持 | 纯Dart实现，无平台限制 |
| 数据导入导出 | ⚠️ 部分支持 | 使用浏览器下载/文件选择替代原生文件操作 |

---

## 8. 后端服务架构

### 8.1 技术栈

| 组件 | 技术选型 | 说明 |
|------|---------|------|
| 运行时 | Python 3.11+ | 类型提示完善，生态丰富 |
| Web框架 | FastAPI | 高性能异步框架，自动生成OpenAPI文档，Pydantic数据校验 |
| 数据库 | PostgreSQL 16 | 功能最强大的开源关系型数据库，JSONB支持、事务完善 |
| ORM | SQLAlchemy 2.0 + Alembic | Python最成熟的ORM，Alembic管理数据库迁移 |
| 缓存 | Redis 7 | 验证码临时存储、Token黑名单 |
| 认证 | JWT (PyJWT) | 无状态Token认证 |
| 短信服务 | 阿里云短信 (dysmsapi) | 国内稳定，到达率高 |
| 部署 | Docker + Nginx | 容器化部署，Nginx反向代理+SSL |

### 8.2 后端项目结构

```
enstudy-server/                     # 后端服务（独立项目）
├── app/
│   ├── main.py                   # FastAPI应用入口
│   ├── config.py                 # 配置管理（Pydantic Settings）
│   ├── database.py               # SQLAlchemy引擎+会话管理
│   ├── models/                   # SQLAlchemy ORM模型
│   │   ├── __init__.py
│   │   ├── user.py               # User模型
│   │   └── quota_log.py          # QuotaChangeLog模型
│   ├── schemas/                  # Pydantic请求/响应模型
│   │   ├── __init__.py
│   │   ├── auth.py               # 登录/验证码请求响应
│   │   ├── user.py               # 用户信息请求响应
│   │   └── admin.py              # 管理员操作请求响应
│   ├── routers/                  # API路由
│   │   ├── __init__.py
│   │   ├── auth.py               # 认证路由（发送验证码/登录）
│   │   ├── user.py               # 用户路由（个人信息/同步数据）
│   │   └── admin.py              # 管理员路由（用户列表/充值）
│   ├── services/                 # 业务逻辑层
│   │   ├── __init__.py
│   │   ├── sms_service.py        # 阿里云短信服务
│   │   ├── auth_service.py       # 认证服务（验证码校验/Token生成）
│   │   ├── user_service.py       # 用户服务（CRUD/数据同步）
│   │   └── admin_service.py      # 管理员服务（用户管理/充值）
│   ├── middleware/                # 中间件
│   │   ├── __init__.py
│   │   └── auth.py               # JWT认证依赖注入
│   └── utils/                    # 工具函数
│       ├── __init__.py
│       ├── response.py           # 统一响应格式
│       └── validator.py          # 参数校验
├── alembic/                      # 数据库迁移
│   ├── env.py
│   └── versions/
├── alembic.ini
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── pyproject.toml
└── .env                          # 服务端环境变量
```

### 8.3 阿里云短信服务集成

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  客户端       │     │  后端服务     │     │  阿里云短信   │
│  请求验证码   │────▶│  生成6位码    │     │              │
│              │     │  存入Redis    │────▶│  调用SMS API │
│              │     │  (5分钟过期)  │     │  发送短信     │
│              │◀────│  返回成功     │◀────│  返回结果     │
└──────────────┘     └──────────────┘     └──────────────┘
```

**阿里云短信配置：**
- 签名名称：EnStudy（需在阿里云申请短信签名）
- 模板Code：SMS_XXXXXX（需在阿里云申请验证码模板）
- 模板内容：您的验证码为${code}，5分钟内有效，请勿泄露。
- AccessKey：从阿里云RAM控制台获取，存入服务端.env

**防刷策略：**
- 同一手机号60秒内不可重复发送
- 同一手机号每天最多发送10次
- 同一IP每分钟最多发送5次
- 验证码校验失败3次后自动失效

### 8.4 JWT认证机制

```
登录成功 → 生成JWT Token (PyJWT)
  - Header: { alg: HS256, typ: JWT }
  - Payload: { userId, phone, isAdmin, iat, exp(7天) }
  - Signature: HMACSHA256(base64(header) + "." + base64(payload), JWT_SECRET)

客户端请求 → Authorization: Bearer <token>
  → FastAPI Depends依赖注入校验Token
  → 解析payload获取userId/isAdmin
  → 注入当前请求上下文

Token刷新策略：
  - Token有效期7天
  - 过期后需重新登录
  - 不支持自动刷新（移动端场景下7天足够）
```

### 8.5 数据库设计（PostgreSQL）

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  nickname VARCHAR(50) DEFAULT '',
  avatar_url VARCHAR(500) DEFAULT '',
  ai_quota INTEGER DEFAULT 10,
  total_score INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  is_admin SMALLINT DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  last_login TIMESTAMP NULL
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_is_admin ON users(is_admin);

CREATE TABLE quota_change_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  change_amount INTEGER NOT NULL,
  before_quota INTEGER NOT NULL,
  after_quota INTEGER NOT NULL,
  reason VARCHAR(200) NOT NULL,
  operator_id UUID NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quota_logs_user_id ON quota_change_logs(user_id);
CREATE INDEX idx_quota_logs_created_at ON quota_change_logs(created_at);
```

### 8.6 部署架构

```
                    ┌─────────────┐
                    │   Nginx     │
                    │  (SSL/443)  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼───┐  ┌────▼────┐  ┌───▼────────┐
     │  前端静态   │  │  后端API │  │  管理后台   │
     │  (Flutter  │  │ (FastAPI │  │  (可选)     │
     │   Web)     │  │  :8000)  │  │            │
     └────────────┘  └────┬─────┘  └────────────┘
                          │
              ┌───────────┼───────────┐
              │           │           │
     ┌────────▼──┐ ┌─────▼─────┐ ┌──▼────────┐
     │ PostgreSQL│ │  Redis    │ │  阿里云SMS │
     │  (:5432)  │ │  (:6379)  │ │  (外部API) │
     └───────────┘ └───────────┘ └───────────┘
```

### 8.7 客户端-服务端交互架构

```
┌──────────────────────────────────────────────────────┐
│                    Flutter 客户端                      │
│                                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ AuthProvider │  │ ApiClient    │  │ 本地缓存     │ │
│  │ (Riverpod)  │  │ (Dio+JWT)    │  │ (SQLite)    │ │
│  └──────┬──────┘  └──────┬───────┘  └──────┬──────┘ │
│         │                │                  │         │
│         └────────────────┼──────────────────┘         │
│                          │                             │
└──────────────────────────┼─────────────────────────────┘
                           │ HTTPS
                           │
┌──────────────────────────┼─────────────────────────────┐
│                    后端服务 (FastAPI)                    │
│                          │                             │
│  ┌───────────────────────▼───────────────────────┐    │
│  │              FastAPI Router                    │    │
│  │  /api/auth/*  →  无需鉴权                      │    │
│  │  /api/user/*  →  JWT鉴权                       │    │
│  │  /api/admin/* →  JWT + 管理员鉴权              │    │
│  └───────────────────────┬───────────────────────┘    │
│                          │                             │
│  ┌───────────┐  ┌───────▼───────┐  ┌───────────┐    │
│  │ SMS服务   │  │ 业务Service   │  │ 数据访问   │    │
│  │ (阿里云)  │  │ (auth/user/   │  │ (SQLAlchemy │    │
│  │           │  │  admin)       │  │  + Redis)   │    │
│  └───────────┘  └───────────────┘  └───────────┘    │
└──────────────────────────────────────────────────────┘
```
