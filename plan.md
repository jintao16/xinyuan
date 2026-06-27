# 鑫源大酒店餐饮订阅系统 - 实现规划

> 基于 [design.md](./design.md)，将系统拆解为细粒度可执行任务。
> 每个任务 2-5 分钟可完成，包含文件路径、代码要点、验证方式。
> 遵循 YAGNI 和 DRY 原则。

## 开发原则
- **TDD**：每个功能先写测试，再写实现
- **渐进式**：按层次推进，数据层 → 服务层 → UI 层
- **可验证**：每个任务都有明确验证方式
- **小步提交**：完成一个任务即可验证

## 阶段总览

| 阶段 | 内容 | 任务数 |
|------|------|--------|
| P0 | 项目初始化 | 5 |
| P1 | 数据层（数据库 + DAO + 模型） | 12 |
| P2 | 服务层（冲突检测、备份） | 4 |
| P3 | 状态管理与依赖注入 | 2 |
| P4 | 通用组件与主题 | 4 |
| P5 | 首页（今日概览） | 4 |
| P6 | 预订管理 | 8 |
| P7 | 空闲查询 | 3 |
| P8 | 统计报表 | 5 |
| P9 | 系统管理 | 6 |
| P10 | 数据导入导出 | 3 |
| P11 | 集成测试与收尾 | 4 |

---

## P0 - 项目初始化

### T0.1 创建 Flutter 项目
- **命令**：`flutter create --org com.xinyuan xinyuan_hotel`
- **目录**：`/Users/jintao/Documents/viceWork/xinyuan/xinyuan_hotel`
- **验证**：`flutter run` 能在模拟器/真机启动默认计数器页面

### T0.2 配置 pubspec.yaml 依赖
- **文件**：`pubspec.yaml`
- **依赖**：
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    sqflite: ^2.3.0
    path: ^1.8.3
    provider: ^6.1.1
    go_router: ^13.0.0
    fl_chart: ^0.66.0
    file_picker: ^6.1.1
    path_provider: ^2.1.1
    intl: ^0.19.0
    shared_preferences: ^2.2.2
  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^3.0.0
  ```
- **验证**：`flutter pub get` 成功

### T0.3 配置 Android 应用信息
- **文件**：`android/app/build.gradle`（applicationId、minSdk）
- **文件**：`android/app/src/main/AndroidManifest.xml`（应用名"鑫源订餐"、存储权限）
- **验证**：构建 APK 不报错

### T0.4 创建目录结构
- **目录**：
  ```
  lib/
  ├── data/{dao,models}/
  ├── services/
  ├── providers/
  ├── pages/{home,reservation,availability,statistics,settings}/
  ├── widgets/
  └── utils/
  test/
  ├── data/
  ├── services/
  └── pages/
  ```
- **验证**：目录创建成功

### T0.5 配置代码规范
- **文件**：`analysis_options.yaml`（启用 lint）
- **验证**：`flutter analyze` 通过

---

## P1 - 数据层

### T1.1 定义数据模型 - Floor
- **文件**：`lib/data/models/floor.dart`
- **内容**：`Floor` 类，含 `id`、`name`、`sortOrder`、`isMain`，`toMap()` / `fromMap()`
- **测试**：`test/data/models/floor_test.dart` 验证序列化
- **验证**：`flutter test` 通过

### T1.2 定义数据模型 - Area
- **文件**：`lib/data/models/area.dart`
- **内容**：`Area` 类 + `AreaType` 枚举（`hall`/`privateRoom`），含 `floorId`、`name`、`type`、`sortOrder`
- **测试**：序列化测试
- **验证**：测试通过

### T1.3 定义数据模型 - DiningTable
- **文件**：`lib/data/models/dining_table.dart`
- **内容**：`DiningTable` 类，含 `areaId`、`name`、`seats`、`sortOrder`
- **测试**：序列化测试
- **验证**：测试通过

### T1.4 定义数据模型 - Reservation + 状态枚举
- **文件**：`lib/data/models/reservation.dart`
- **内容**：
  - `ReservationStatus` 枚举：`booked`/`completed`/`cancelled`，含中文标签和颜色
  - `Reservation` 类：含所有字段，`tableId` 与 `areaId` 互斥校验
- **测试**：序列化、互斥校验测试
- **验证**：测试通过

### T1.5 定义数据模型 - QuickTimeSlot
- **文件**：`lib/data/models/quick_time_slot.dart`
- **内容**：`QuickTimeSlot` 类，含 `name`、`startTime`、`endTime`、`sortOrder`
- **测试**：序列化测试
- **验证**：测试通过

### T1.6 数据库初始化与建表
- **文件**：`lib/data/database.dart`
- **内容**：
  - `DatabaseHelper` 单例类
  - `database` getter 懒加载
  - `onCreate` 建表 SQL（5 张表 + 索引）
  - 版本管理 `version: 1`
- **测试**：内存数据库建表测试
- **验证**：测试通过

### T1.7 数据库初始化数据
- **文件**：`lib/data/database.dart`（扩展 `onCreate`）
- **内容**：预置 2 个楼层、4 个区域、2 个快捷时段
- **测试**：建表后查询预置数据
- **验证**：测试通过

### T1.8 实现 FloorDao
- **文件**：`lib/data/dao/floor_dao.dart`
- **方法**：`getAll()`、`getById()`、`insert()`、`update()`、`delete()`（含级联校验）
- **测试**：CRUD 测试
- **验证**：测试通过

### T1.9 实现 AreaDao
- **文件**：`lib/data/dao/area_dao.dart`
- **方法**：CRUD + `getByFloorId()`、`getByType()`
- **测试**：CRUD 测试
- **验证**：测试通过

### T1.10 实现 TableDao
- **文件**：`lib/data/dao/table_dao.dart`
- **方法**：CRUD + `getByAreaId()`、`getByFloorWithArea()`
- **测试**：CRUD 测试
- **验证**：测试通过

### T1.11 实现 ReservationDao
- **文件**：`lib/data/dao/reservation_dao.dart`
- **方法**：
  - CRUD
  - `getByDate(date)`、`getByDateRange(start, end)`
  - `getByStatus(status, dateRange)`
  - `getByTable(tableId, date)`、`getByArea(areaId, date)`
- **测试**：CRUD + 查询测试
- **验证**：测试通过

### T1.12 实现 QuickTimeSlotDao
- **文件**：`lib/data/dao/quick_time_slot_dao.dart`
- **方法**：CRUD + `getAll()`
- **测试**：CRUD 测试
- **验证**：测试通过

---

## P2 - 服务层

### T2.1 冲突检测服务
- **文件**：`lib/services/conflict_service.dart`
- **内容**：
  - `hasConflict(reservation)` 方法
  - 大厅桌：按 `table_id + date + booked + 时段重叠` 查询
  - 包厢：按 `area_id + date + booked + 时段重叠` 查询
  - 时段重叠算法：`start1 < end2 && start2 < end1`
- **测试**：
  - 大厅桌冲突场景
  - 包厢冲突场景
  - 同桌不同时段不冲突
  - 同桌相同时段冲突
  - 已完成/已取消不冲突
- **验证**：测试通过

### T2.2 空闲查询服务
- **文件**：`lib/services/availability_service.dart`
- **内容**：
  - `queryAvailability(date, startTime, endTime, [guestCount])`
  - 返回 `List<TableAvailability>`，按楼层→区域分组
  - 大厅桌预订 → 标记桌位占用
  - 包厢预订 → 包厢下所有桌位占用
  - 人数过滤：`seats >= guestCount` 优先，不足灰显
- **测试**：
  - 全空闲场景
  - 大厅桌被占场景
  - 包厢被占场景
  - 人数过滤场景
- **验证**：测试通过

### T2.3 备份服务 - 导出
- **文件**：`lib/services/backup_service.dart`
- **内容**：
  - `exportToJson()` 返回 JSON 字符串
  - 收集所有表数据组装成 Map
  - `exportToFile()` 保存到文件，文件名 `xinyuan_backup_YYYYMMDD_HHmmss.json`
- **测试**：导出数据结构测试
- **验证**：测试通过

### T2.4 备份服务 - 导入
- **文件**：`lib/services/backup_service.dart`（扩展）
- **内容**：
  - `importFromJson(jsonStr)` 覆盖式导入
  - 事务内清空 + 插入
  - 返回导入结果摘要（各表记录数）
- **测试**：导入数据测试
- **验证**：测试通过

---

## P3 - 状态管理

### T3.1 创建 AppProvider
- **文件**：`lib/providers/app_provider.dart`
- **内容**：全局 Provider，持有 `DatabaseHelper`、各 DAO、各 Service 实例
- **验证**：编译通过

### T3.2 配置路由
- **文件**：`lib/app.dart`
- **内容**：go_router 配置，定义所有页面路由
- **验证**：编译通过

---

## P4 - 通用组件与主题

### T4.1 应用主题
- **文件**：`lib/app.dart`
- **内容**：定义 `ThemeData`，主色调（建议金棕色系，符合酒店气质）
- **验证**：编译通过

### T4.2 状态标签组件
- **文件**：`lib/widgets/status_tag.dart`
- **内容**：根据 `ReservationStatus` 显示不同颜色标签
- **测试**：widget test
- **验证**：测试通过

### T4.3 时间段选择器组件
- **文件**：`lib/widgets/time_range_picker.dart`
- **内容**：
  - 快捷时段按钮（从 DB 加载）
  - 自定义开始/结束时间选择器
- **测试**：widget test
- **验证**：测试通过

### T4.4 底部导航栏
- **文件**：`lib/widgets/main_scaffold.dart`
- **内容**：5 个 tab：首页、预订、查询、统计、设置
- **验证**：编译通过

---

## P5 - 首页（今日概览）

### T5.1 今日预订统计卡片
- **文件**：`lib/pages/home/home_page.dart`
- **内容**：显示今日已预订/已完成/已取消数量
- **验证**：手测显示正确

### T5.2 即将到店列表
- **文件**：`lib/pages/home/home_page.dart`（扩展）
- **内容**：
  - 查询今日 `booked` 且开始时间在当前时间前后30分钟
  - 高亮显示
- **验证**：手测

### T5.3 今日时段分布迷你图
- **文件**：`lib/pages/home/home_page.dart`（扩展）
- **内容**：用 fl_chart 画今日各小时预订数柱状图
- **验证**：手测

### T5.4 首页快捷操作
- **内容**：新建预订按钮、查看空闲按钮
- **验证**：手测跳转

---

## P6 - 预订管理

### T6.1 预订列表页 - 基础结构
- **文件**：`lib/pages/reservation/reservation_list_page.dart`
- **内容**：
  - 日期选择器（默认今天）
  - 状态筛选 tab（全部/已预订/已完成/已取消）
  - 列表展示
- **验证**：手测

### T6.2 预订列表项
- **文件**：`lib/pages/reservation/widgets/reservation_tile.dart`
- **内容**：
  - 显示时间、客户、桌位/包厢、人数、状态
  - 已取消样式区分（灰色斜体）
  - 即将到店高亮
- **验证**：手测

### T6.3 预订列表项操作
- **内容**：滑动或长按操作菜单
  - 标记完成、标记取消、编辑、删除
- **验证**：手测

### T6.4 新建预订页 - 基础表单
- **文件**：`lib/pages/reservation/reservation_form_page.dart`
- **内容**：
  - 日期、时段选择
  - 客户称谓、联系方式、人数、备注输入
- **验证**：手测

### T6.5 新建预订页 - 桌位/包厢选择
- **内容**：
  - 预订类型切换：大厅桌 / 包厢
  - 选大厅桌 → 调用空闲查询展示可用桌位
  - 选包厢 → 展示可用包厢
  - 人数过滤
- **验证**：手测

### T6.6 新建预订页 - 冲突校验与保存
- **内容**：
  - 保存前调用 `ConflictService.hasConflict()`
  - 冲突时提示并阻止
  - 通过则插入数据库
- **测试**：集成测试
- **验证**：测试通过 + 手测

### T6.7 预订详情页
- **文件**：`lib/pages/reservation/reservation_detail_page.dart`
- **内容**：展示完整信息 + 编辑入口 + 状态变更按钮
- **验证**：手测

### T6.8 预订编辑
- **文件**：`lib/pages/reservation/reservation_form_page.dart`（复用）
- **内容**：编辑模式，随时可改
- **验证**：手测

---

## P7 - 空闲查询

### T7.1 空闲查询页 - 查询条件
- **文件**：`lib/pages/availability/availability_page.dart`
- **内容**：日期、时段、人数输入
- **验证**：手测

### T7.2 空闲查询结果展示
- **内容**：
  - 按楼层 → 区域分组
  - 桌位/包厢卡片，标记空闲/占用
  - 占用时显示占用来源
- **验证**：手测

### T7.3 空闲查询结果操作
- **内容**：点击空闲桌位/包厢直接跳转新建预订（预填信息）
- **验证**：手测

---

## P8 - 统计报表

### T8.1 统计页框架与时间范围
- **文件**：`lib/pages/statistics/statistics_page.dart`
- **内容**：日/周/月切换
- **验证**：手测

### T8.2 预订量统计
- **内容**：数字卡片 + 趋势折线图（fl_chart）
- **验证**：手测

### T8.3 桌位使用率
- **内容**：横向条形图，按使用次数排序
- **验证**：手测

### T8.4 时段分布
- **内容**：柱状图，横轴小时
- **验证**：手测

### T8.5 区域占比
- **内容**：饼图
- **验证**：手测

---

## P9 - 系统管理

### T9.1 系统管理首页
- **文件**：`lib/pages/settings/settings_page.dart`
- **内容**：入口列表（楼层/区域/桌位/快捷时段/数据管理）
- **验证**：手测

### T9.2 楼层管理
- **文件**：`lib/pages/settings/floor_management_page.dart`
- **内容**：列表 + 新增/编辑/删除（含级联校验）
- **验证**：手测

### T9.3 区域管理
- **文件**：`lib/pages/settings/area_management_page.dart`
- **内容**：按楼层分组 + CRUD
- **验证**：手测

### T9.4 桌位管理
- **文件**：`lib/pages/settings/table_management_page.dart`
- **内容**：按区域分组 + CRUD
- **验证**：手测

### T9.5 快捷时段管理
- **文件**：`lib/pages/settings/time_slot_management_page.dart`
- **内容**：列表 + CRUD
- **验证**：手测

### T9.6 数据管理入口
- **文件**：`lib/pages/settings/data_management_page.dart`
- **内容**：导出/导入按钮（逻辑在 P10 实现）
- **验证**：手测 UI

---

## P10 - 数据导入导出

### T10.1 导出功能对接
- **文件**：`lib/pages/settings/data_management_page.dart`（扩展）
- **内容**：
  - 调用 `BackupService.exportToFile()`
  - 用 file_picker 保存到用户选择位置
  - 成功提示
- **验证**：手测导出文件

### T10.2 导入功能对接
- **内容**：
  - 用 file_picker 选 JSON 文件
  - 确认对话框"将覆盖当前所有数据"
  - 调用 `BackupService.importFromJson()`
  - 展示导入结果
- **验证**：手测导入

### T10.3 导入数据校验
- **内容**：导入前校验 JSON 结构完整性，异常时友好提示
- **测试**：异常数据测试
- **验证**：测试通过

---

## P11 - 集成测试与收尾

### T11.1 端到端测试 - 预订流程
- **测试**：
  - 创建楼层/区域/桌位
  - 新建预订 → 冲突检测 → 保存
  - 列表查看 → 状态变更
- **验证**：测试通过

### T11.2 端到端测试 - 空闲查询
- **测试**：有预订时查询空闲，验证占用标记正确
- **验证**：测试通过

### T11.3 端到端测试 - 导入导出
- **测试**：导出 → 清空 → 导入 → 数据一致
- **验证**：测试通过

### T11.4 全量 lint 与测试
- **命令**：`flutter analyze` + `flutter test`
- **验证**：全部通过

---

## 任务依赖关系

```
P0 (初始化) 
  → P1 (数据层) 
  → P2 (服务层) 
  → P3 (状态管理) 
  → P4 (通用组件)
  → 并行：P5(首页) / P6(预订) / P7(查询) / P8(统计) / P9(系统管理) / P10(导入导出)
  → P11 (集成测试)
```

P5-P10 在 P4 完成后可并行推进，但建议按 P5 → P6 → P7 → P8 → P9 → P10 顺序，因为预订管理是最核心模块，其他模块依赖其组件。

---

## 验证策略

| 层 | 验证方式 |
|----|----------|
| 模型层 | 单元测试（序列化、校验） |
| DAO 层 | 单元测试（内存数据库 CRUD） |
| 服务层 | 单元测试（业务逻辑） |
| 组件层 | Widget 测试 |
| 页面层 | 手动测试 + 集成测试 |
| 全量 | `flutter analyze` + `flutter test` |

---

## 风险与应对

| 风险 | 应对 |
|------|------|
| 时段重叠算法边界错误 | 充分单元测试覆盖边界 |
| 包厢占用逻辑遗漏 | 服务层测试覆盖包厢场景 |
| 导入数据格式错误 | 严格校验 + 友好提示 |
| Flutter 版本兼容 | 锁定版本，CI 验证 |
| 真机性能 | 控制查询数据量，加索引 |

---

## 下一步

待你确认本计划后，进入 **TDD 开发阶段**，从 P0 开始按任务执行。
