# 鑫源大酒店餐饮订阅系统 - 设计文档

## 1. 项目背景

### 1.1 现状
鑫源大酒店是本地小本经营的餐饮酒店，目前订桌流程完全依赖人工记账：客户打电话预订，工作人员用纸笔记录客户称谓、桌位、时段等信息。存在以下痛点：
- 无法快速查看桌位空闲情况，容易重复预订或漏记
- 纸质记录易丢失、难统计
- 换班交接信息不对称
- 无法做数据分析（客流高峰、热门桌位等）

### 1.2 目标
用电子化系统替代纸质记账，实现：
- 订桌记录的结构化存储
- 桌位空闲状态实时查询，避免冲突
- 经营数据统计与可视化

### 1.3 范围（确认清单）
**做**：订桌记录、桌位空闲查询、统计报表、系统管理（桌位/包厢增删改）、数据导入导出
**不做**：点单结账、客户档案维护、云同步、多端实时共享、推送通知

---

## 2. 关键设计决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 使用者 | 单人（前台/老板） | 小本经营不买云服务，纯本地即可 |
| 存储 | 纯本地 SQLite + JSON 导入导出 | 无云成本，支持换机迁移 |
| 技术栈 | Flutter | 跨平台，未来可扩展 iOS |
| 时段模型 | 按小时，含快捷时段 | 精确冲突检测，兼顾操作便捷 |
| 楼层管理 | 一楼二楼都管，统一增删 | 一楼虽非主要但也会用 |
| 空闲逻辑 | 大厅按桌、包厢按整体 | 符合实际占用规则 |
| 客户信息 | 称谓+联系方式，不建档 | 客户通常只报姓 |
| 状态流转 | 已预订→已完成/已取消 | 简化流程 |
| 人数匹配 | 记录并自动过滤推荐 | 提升预订效率 |
| 提醒 | 列表内高亮 | 无需后台任务，简单可靠 |

---

## 3. 场景与楼层结构

### 3.1 物理结构
```
鑫源大酒店
├── 一楼
│   └── 大厅（活动桌，数量可增删，非主要营业区）
└── 二楼（主入口，前台所在）
    ├── 大厅
    │   ├── 小桌（4人桌，多张）
    │   └── 大桌（10+人桌，多张）
    └── 包厢（多个）
        ├── 纯大桌包厢（10-20人一桌）
        └── 大小桌组合包厢（大桌+小桌）
```

### 3.2 区域类型
- **大厅**：含多张独立桌位，桌位之间互不影响，预订按"桌"为单位
- **包厢**：含一张或多张桌位，但预订按"整个包厢"为单位，预订后包厢内所有桌位均占用

---

## 4. 数据模型

### 4.1 实体关系图
```
Floor（楼层）1 ── * Area（区域）
Area（区域）1 ── * Table（桌位）
Reservation（预订）* ── 1 Table（桌位）  [大厅桌预订]
Reservation（预订）* ── 1 Area（包厢）   [包厢预订]
```

### 4.2 表结构

#### floor（楼层）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 自增主键 |
| name | TEXT | 楼层名（如"一楼"、"二楼"） |
| sort_order | INTEGER | 排序号 |
| is_main | INTEGER | 是否主楼层（0/1） |

#### area（区域）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 自增主键 |
| floor_id | INTEGER FK | 所属楼层 |
| name | TEXT | 区域名（如"一楼大厅"、"VIP1号包厢"） |
| type | TEXT | 类型：`hall`（大厅）/ `private_room`（包厢） |
| sort_order | INTEGER | 排序号 |

#### dining_table（桌位）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 自增主键 |
| area_id | INTEGER FK | 所属区域 |
| name | TEXT | 桌位名（如"A1"、"大圆桌1"） |
| seats | INTEGER | 座位数 |
| sort_order | INTEGER | 排序号 |

#### reservation（预订）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 自增主键 |
| date | TEXT | 预订日期 YYYY-MM-DD |
| start_time | TEXT | 开始时间 HH:mm |
| end_time | TEXT | 结束时间 HH:mm |
| table_id | INTEGER FK | 桌位ID（大厅桌预订时填写，包厢预订时为空） |
| area_id | INTEGER FK | 包厢ID（包厢预订时填写，大厅桌预订时为空） |
| customer_title | TEXT | 客户称谓（如"张先生"） |
| customer_phone | TEXT | 联系方式（手机/座机/微信，文本） |
| guest_count | INTEGER | 用餐人数 |
| status | TEXT | 状态：`booked`/`completed`/`cancelled` |
| remark | TEXT | 备注 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

> **约束**：`table_id` 和 `area_id` 二选一非空。大厅桌预订填 `table_id`，包厢预订填 `area_id`。

#### quick_time_slot（快捷时段）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 自增主键 |
| name | TEXT | 名称（如"午餐"、"晚餐"） |
| start_time | TEXT | 开始时间 HH:mm |
| end_time | TEXT | 结束时间 HH:mm |
| sort_order | INTEGER | 排序号 |

> 预装数据：午餐 11:00-13:00、晚餐 17:00-19:00，可在系统管理中增删改。

---

## 5. 核心业务规则

### 5.1 冲突检测（时段重叠）
两个时段 `[s1, e1)` 与 `[s2, e2)` 重叠的判定：
```
s1 < e2  &&  s2 < e1
```

### 5.2 空闲判定逻辑

#### 大厅桌位空闲
桌位 T 在日期 D、时段 `[s, e)` 空闲，当且仅当：
- 不存在预订 R 满足：`R.table_id = T.id` 且 `R.date = D` 且 `R.status = 'booked'` 且 `R` 的时段与 `[s, e)` 重叠

#### 包厢空闲
包厢 A 在日期 D、时段 `[s, e)` 空闲，当且仅当：
- 不存在预订 R 满足：`R.area_id = A.id` 且 `R.date = D` 且 `R.status = 'booked'` 且 `R` 的时段与 `[s, e)` 重叠

> 注意：包厢一旦被预订，包厢内**所有桌位**在该时段均视为占用，但占用来源是包厢层级，不是桌位层级。

### 5.3 状态流转
```
已预订(booked) ──到店用餐──→ 已完成(completed)
已预订(booked) ──取消/未到──→ 已取消(cancelled)
```
- `booked` 状态会占用桌位/包厢，影响空闲判定
- `completed`、`cancelled` 不再占用，不影响空闲判定
- 已完成和已取消是终态，不可回退

### 5.4 人数匹配推荐
查询空闲桌位时，若用户输入了用餐人数 N：
- 桌位按 `seats >= N` 过滤
- 同时展示 `seats < N` 的桌位但标记"座位不足"
- 推荐排序：`seats` 接近 N 的优先（避免大桌小用）

---

## 6. 功能模块

### 6.1 模块总览
```
├── 首页（今日概览）
├── 预订管理
│   ├── 新建预订
│   ├── 预订列表（按日期）
│   └── 预订详情/编辑/状态变更
├── 空闲查询
│   ├── 按日期+时段查桌位
│   └── 按人数过滤推荐
├── 统计报表
│   ├── 预订量统计
│   ├── 桌位使用率
│   ├── 时段分布
│   └── 区域占比
├── 系统管理
│   ├── 楼层管理
│   ├── 区域管理（大厅/包厢）
│   ├── 桌位管理
│   └── 快捷时段管理
└── 数据管理
    ├── 导出数据（JSON）
    └── 导入数据（JSON，覆盖式）
```

### 6.2 首页 - 今日概览
- 今日预订数（按状态分组：已预订/已完成/已取消）
- 即将到店列表（今日已预订且开始时间在当前时间前后30分钟内，高亮显示）
- 今日各时段预订数小图表

### 6.3 预订管理

#### 6.3.1 新建预订
**输入字段**：
- 日期（默认今天）
- 时段：可选快捷时段按钮（自动填充时间）或自定义开始/结束时间
- 预订类型：大厅桌 / 包厢（二选一）
- 桌位/包厢选择：
  - 选"大厅桌"→ 显示指定楼层大厅下的空闲桌位列表（可按人数过滤）
  - 选"包厢"→ 显示空闲包厢列表
- 客户称谓（必填，文本，如"张先生"）
- 联系方式（选填，手机/座机/微信）
- 用餐人数（选填，用于过滤桌位）
- 备注（选填）

**校验**：
- 必填项校验
- 冲突校验：所选桌位/包厢在该时段是否已被预订
- 时间校验：结束时间 > 开始时间

#### 6.3.2 预订列表
- 按日期筛选（默认今天）
- 按状态筛选（全部/已预订/已完成/已取消）
- 列表项展示：时间、客户、桌位/包厢、人数、状态、联系方式
- 列表项操作：标记完成、标记取消、编辑、删除
- 即将到店高亮（开始时间在前后30分钟内的已预订项）

#### 6.3.3 预订详情/编辑
- 展示完整信息
- 编辑：同新建，但若已变更状态需提示
- 删除：二次确认（建议用"取消"而非删除，保留记录便于统计）

### 6.4 空闲查询
**入口**：独立菜单 + 新建预订时选择桌位

**查询条件**：
- 日期（默认今天）
- 时段（快捷时段按钮 + 自定义时间）
- 用餐人数（选填，用于过滤）

**结果展示**：
- 按楼层 → 区域分组展示
- 大厅：列出桌位，标记空闲/占用，占用时显示占用来源预订
- 包厢：列出包厢，标记空闲/占用，占用时显示占用来源预订
- 人数过滤：`seats >= 人数` 优先展示，不足的灰显

### 6.5 统计报表

#### 6.5.1 预订量统计
- 时间范围选择：日/周/月
- 指标：预订总数、完成数、取消数、到店率（完成/已预订）
- 展示：数字卡片 + 趋势折线图

#### 6.5.2 桌位使用率
- 时间范围选择
- 按桌位/包厢统计被预订次数
- 展示：横向条形图，按使用次数排序
- 使用率 = 该桌位预订次数 / 总预订次数

#### 6.5.3 时段分布
- 时间范围选择
- 按小时统计预订数
- 展示：柱状图，横轴为小时，纵轴为预订数

#### 6.5.4 区域占比
- 时间范围选择
- 按楼层、按大厅/包厢统计预订数占比
- 展示：饼图

### 6.6 系统管理

#### 6.6.1 楼层管理
- 列表展示楼层
- 新增/编辑/删除楼层
- 删除校验：楼层下有区域时不可删除

#### 6.6.2 区域管理
- 按楼层分组展示区域
- 新增/编辑/删除区域
- 类型选择：大厅 / 包厢
- 删除校验：区域下有桌位时不可删除

#### 6.6.3 桌位管理
- 按区域分组展示桌位
- 新增/编辑/删除桌位
- 字段：名称、座位数
- 删除校验：桌位有未来预订时需提示（建议改"取消"而非删除）

#### 6.6.4 快捷时段管理
- 列表展示快捷时段
- 新增/编辑/删除

### 6.7 数据管理

#### 6.7.1 导出
- 一键导出全库为 JSON 文件
- 包含：所有楼层、区域、桌位、快捷时段、预订记录
- 文件保存到手机本地存储，可分享
- 文件名格式：`xinyuan_backup_YYYYMMDD_HHmmss.json`

#### 6.7.2 导入
- 选择 JSON 文件
- **覆盖式导入**：清空当前数据，用导入数据替换
- 导入前强制提示"将覆盖当前所有数据，是否继续？"
- 导入后展示导入结果摘要

---

## 7. 技术架构

### 7.1 技术栈
| 层 | 技术 | 说明 |
|----|------|------|
| 框架 | Flutter 3.x | 跨平台 UI |
| 语言 | Dart | - |
| 数据库 | sqflite | SQLite 本地存储 |
| 状态管理 | Provider 或 Riverpod | 轻量级 |
| 路由 | go_router | 声明式路由 |
| 图表 | fl_chart | 统计报表 |
| 文件操作 | file_picker + path_provider | 导入导出 |
| 日期处理 | intl | 日期格式化 |

### 7.2 项目结构
```
lib/
├── main.dart                      # 入口
├── app.dart                       # App 配置
├── data/
│   ├── database.dart              # 数据库初始化
│   ├── dao/
│   │   ├── floor_dao.dart
│   │   ├── area_dao.dart
│   │   ├── table_dao.dart
│   │   ├── reservation_dao.dart
│   │   └── time_slot_dao.dart
│   └── models/
│       ├── floor.dart
│       ├── area.dart
│       ├── dining_table.dart
│       ├── reservation.dart
│       └── time_slot.dart
├── services/
│   ├── backup_service.dart        # 导入导出
│   └── conflict_service.dart      # 冲突检测
├── providers/                     # 状态管理
├── pages/
│   ├── home/
│   ├── reservation/
│   ├── availability/
│   ├── statistics/
│   └── settings/
├── widgets/                       # 通用组件
└── utils/
```

### 7.3 关键算法

#### 冲突检测（插入预订时）
```dart
bool hasConflict(Reservation newRes) {
  // 大厅桌
  if (newRes.tableId != null) {
    return db.query('reservation', where: '''
      table_id = ? AND date = ? AND status = 'booked'
      AND start_time < ? AND end_time > ?
    ''', [newRes.tableId, newRes.date, newRes.endTime, newRes.startTime]).isNotEmpty;
  }
  // 包厢
  if (newRes.areaId != null) {
    return db.query('reservation', where: '''
      area_id = ? AND date = ? AND status = 'booked'
      AND start_time < ? AND end_time > ?
    ''', [newRes.areaId, newRes.date, newRes.endTime, newRes.startTime]).isNotEmpty;
  }
  return false;
}
```

#### 空闲桌位查询
```dart
List<TableAvailability> queryAvailable(String date, String startTime, String endTime, [int? guestCount]) {
  // 1. 查所有桌位（含所属区域、楼层）
  // 2. 查该日期、时段、booked 状态的预订
  //    - 大厅桌预订 → 标记对应桌位占用
  //    - 包厢预订   → 标记该包厢下所有桌位占用
  // 3. 按人数过滤（可选）
  // 4. 返回结果
}
```

---

## 8. 数据初始化

首次启动时，根据鑫源大酒店实际情况预置：

```sql
-- 楼层
INSERT INTO floor (name, sort_order, is_main) VALUES ('一楼', 1, 0);
INSERT INTO floor (name, sort_order, is_main) VALUES ('二楼', 2, 1);

-- 二楼大厅和几个示例包厢
INSERT INTO area (floor_id, name, type, sort_order) VALUES (2, '二楼大厅', 'hall', 1);
INSERT INTO area (floor_id, name, type, sort_order) VALUES (2, 'VIP1号包厢', 'private_room', 2);
INSERT INTO area (floor_id, name, type, sort_order) VALUES (2, 'VIP2号包厢', 'private_room', 3);

-- 一楼大厅
INSERT INTO area (floor_id, name, type, sort_order) VALUES (1, '一楼大厅', 'hall', 1);

-- 快捷时段
INSERT INTO quick_time_slot (name, start_time, end_time, sort_order) VALUES ('午餐', '11:00', '13:00', 1);
INSERT INTO quick_time_slot (name, start_time, end_time, sort_order) VALUES ('晚餐', '17:00', '19:00', 2);
```

> 具体桌位由管理员首次使用时在系统管理中添加。

---

## 9. 待办与开放问题

### 9.1 已确认范围外（未来可扩展）
- 多员工实时同步（需引入后端）
- 客户档案与回头客统计
- 点单结账 POS
- 推送通知
- iOS 版本（Flutter 天然支持，后续可出）

### 9.2 开发阶段需细化
- UI 交互细节（具体页面线框图）
- 错误处理与边界场景
- 数据库迁移策略（版本升级时）

---

## 10. 下一步

设计文档完成后，将进入**实现规划阶段**：
1. 将功能拆解为细粒度任务（每个 2-5 分钟可完成）
2. 每个任务包含具体文件路径、代码、验证方式
3. 生成 `plan.md`
4. 按计划进入 TDD 开发
