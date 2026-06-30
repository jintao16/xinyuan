# 鑫源酒店 - 首页与空闲查询页改进设计

## 范围

针对首页与空闲查询页的 4 类问题进行修复与增强：

1. 首页顶部时间快捷切换（昨日 / 今日 / 明日 / 后日 / 大后日）
2. 日历控件汉化 + 农历 + 节假日
3. 时间选择器改为时、分上下滑动滚轮
4. 「查询空闲」按钮与背景区分 + 空闲查询页黑底/双下划线 Bug 修复

---

## 1. 首页顶部时间快捷切换

### 现状

`HomePage` 是 `StatelessWidget`，`PageHeader` 副标题固定为 `今日 · $today`，统计数据、即将到店、今日时段均基于 `provider.todayReservations`（只读今日）。

### 设计

#### 1.1 HomePage 改为 StatefulWidget

新增本地状态 `String _selectedDate`（默认 `TimeUtil.today()`），并新增 `Future<void> _loadReservations(String date)` 方法，调用 `provider.getReservationsByDate(date)` 拿到当日预订列表 `_reservations`，本地计算 `bookedCount / completedCount / cancelledCount / upcoming / hours 分布`。

- `initState` 中初始化 `_selectedDate = TimeUtil.today()` 并加载。
- 切换日期时调用 `_loadReservations` 并 `setState`。
- 不改动 `AppProvider` 的 `_todayReservations` 缓存（保持今日缓存语义不变）。

#### 1.2 顶部快捷日期切换条

在 `PageHeader` 下方新增一行横向 `FilterPill` 切换条：

```
[昨日] [今日*] [明日] [后日] [大后日]
```

- 使用既有 `FilterPill` 组件，`active` 判定：`_selectedDate == TimeUtil.dateOffset(today, offset)`。
- 点击后：`setState(() => _selectedDate = TimeUtil.dateOffset(TimeUtil.today(), offset))` 并调用 `_loadReservations`。
- `PageHeader` 副标题改为：`今日 · $today` → `${label} · ${TimeUtil.formatDateZh(_selectedDate)}`，label 根据偏移显示「昨日/今日/明日/后日/大后日」；非 5 个快捷项时 label 直接显示日期。

#### 1.3 章节标题与统计联动

- 「今日时段」/「今日全部预订」/「即将到店」章节的"今日"文案改为动态：当选中今日时显示「今日」，否则显示对应日期标签。
- 「即将到店」仅当选中今日时显示；非今日时该区块隐藏（因为 `isUpcoming` 基于当前时刻）。

---

## 2. 日历控件汉化 + 农历 + 节假日

### 依赖

新增 `lunar: ^1.7.1`（已查证 pub.dev 最新稳定版）。

### 设计

#### 2.1 自定义日历对话框 `LunarDatePickerDialog`

新文件 `lib/widgets/lunar_date_picker.dart`，提供静态方法：

```dart
static Future<DateTime?> show(BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
})
```

内部为一个 `Dialog`/`BottomSheet`，结构：

- 顶部：年份/月份切换（左右箭头 + `2026年6月` 标题）
- 中部：星期表头（日 一 二 三 四 五 六）
- 主体：6 行 7 列网格，每个单元格：
  - 上行：公历日数字
  - 下行：农历日（初一显示月名如「五月」，否则显示日名如「初五」）；若当日有节日（`Lunar.getFestivals()` / `Solar.getFestivals()`）则优先显示节日名（截断 4 字）
  - 节假日当天：背景使用 `AppTheme.accent.withOpacity(0.12)` 色块；选中态：金棕色实心圆背景
  - 今日：边框描边
- 底部：「取消」「确定」按钮

#### 2.2 农历与节假日获取

使用 `lunar` 包：

```dart
final solar = Solar.fromDate(date);
final lunar = solar.getLunar();
final lunarDayText = lunar.getDayInChinese(); // 初一、初二... 卅
final lunarMonthText = lunar.getMonthInChinese(); // 正、二、三...
final festivals = [...lunar.getFestivals(), ...solar.getFestivals()];
final jieQi = lunar.getJieQi(); // 节气：立春、雨水...
```

显示优先级：节日 > 节气 > 农历日。

#### 2.3 替换调用点

- `availability_page.dart` 的 `_pickDate` → `LunarDatePickerDialog.show(...)`
- `reservation_form_page.dart` 的 `_pickDate` → 同上

#### 2.4 汉化

整个 Dialog 全中文 UI，无英文字段。

---

## 3. 时间选择器改为上下滑动滚轮

### 设计

#### 3.1 新组件 `CupertinoTimePickerDialog`

新文件 `lib/widgets/time_wheel_picker.dart`，提供静态方法：

```dart
static Future<String?> show(BuildContext context, {required String initialTime})
```

内部使用 `CupertinoDatePicker`：

```dart
CupertinoDatePicker(
  mode: CupertinoDatePickerMode.time,
  initialDateTime: DateTime(2020, 1, 1, hh, mm),
  use24hFormat: true,
  minuteInterval: 1,
  onDateTimeChanged: (dt) => selected = dt,
)
```

弹窗形式：底部弹起 `CupertinoModalPopup`/`Dialog`，上方有「取消」「确定」按钮，下方是 `CupertinoDatePicker`。返回 `"HH:mm"` 字符串。

#### 3.2 替换调用点

- `availability_page.dart` 的 `_TimeField._pick` → `CupertinoTimePickerDialog.show(...)`
- `reservation_form_page.dart` 的 `_TimePickerField._pick` → 同上

---

## 4. 「查询空闲」按钮区分 + 空闲查询页黑底/双下划线 Bug 修复

### Bug 根因

`AvailabilityPage` 当前直接 `return ListView(...)`，没有 `Scaffold`/`Material`/`Container` 提供背景色。被 `Navigator.push` 推入后：

- 没有背景 → 黑底
- `Text` 没有继承到 `DefaultTextStyle`（Material 提供）→ Flutter 给 Text 加黄色双下划线（`Debug baseline` 提示线，实际是没有 Material 祖先时的渲染异常）
- 同理 `_FloorSection`、`_AreaCard` 中的 Text 也出现红线/双线

### 修复方案

#### 4.1 为 AvailabilityPage 包 Scaffold

将 `AvailabilityPage.build` 改为返回 `Scaffold`：

```dart
return Scaffold(
  backgroundColor: Colors.transparent,  // 让 MainScaffold 的环境背景透出
  body: ListView(...)
);
```

由于 `MainScaffold` 的环境背景（`_AmbientBackground`）只在 `MainScaffold` 内部，被 push 的新页面不在那个 Stack 里，所以需要自带一个相同的环境背景。

**方案 A（推荐）**：把 `_AmbientBackground` 提取为独立组件 `lib/widgets/ambient_background.dart`，在 `MainScaffold` 和 `AvailabilityPage`（以及任何被 push 的页面）外层都用它做背景。

**方案 B**：Scaffold 用一个静态渐变背景（不带光斑）。

采用方案 A 以保持视觉一致。

#### 4.2 「查询空闲」按钮区分

`home_page.dart` 第 117 行的 `OutlinedButton.icon` 改为带金棕色填充的按钮：

```dart
ElevatedButton.icon(
  onPressed: ...,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.accentSoft.withOpacity(0.18),
    foregroundColor: AppTheme.accentDeep,
    side: BorderSide(color: AppTheme.accent),
    elevation: 0,
  ),
  icon: const Icon(CupertinoIcons.search, size: 18),
  label: const Text('查询空闲'),
)
```

与左侧主操作按钮（实心金棕底白字）形成主次对比，同时与页面浅色背景明显区分。

---

## 5. 文件改动清单

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `pubspec.yaml` | 修改 | 新增 `lunar: ^1.7.1` 依赖 |
| `lib/widgets/ambient_background.dart` | 新增 | 提取的环境背景组件 |
| `lib/widgets/lunar_date_picker.dart` | 新增 | 自定义汉化日历对话框 |
| `lib/widgets/time_wheel_picker.dart` | 新增 | Cupertino 滚轮时间选择器 |
| `lib/main_scaffold.dart` | 修改 | 使用提取的 `AmbientBackground` |
| `lib/pages/home/home_page.dart` | 修改 | StatefulWidget + 日期快捷条 + 按钮样式 |
| `lib/pages/availability/availability_page.dart` | 修改 | 包 Scaffold + 背景修复 + 时间选择器替换 + 日历替换 |
| `lib/pages/reservation/reservation_form_page.dart` | 修改 | 时间选择器替换 + 日历替换 |

---

## 6. 验证

- `flutter analyze` 无错误
- `flutter test` 既有测试通过
- 手动验证：
  - 首页顶部出现 5 个快捷日期切换，切换后统计数据、章节标题、预订列表同步变化
  - 日历控件全中文，每个日期格子有农历/节日，节假日有色块
  - 时间选择器为上下滑动滚轮
  - 「查询空闲」按钮与背景明显区分
  - 进入空闲查询页背景为正常的暖色渐变（非黑色），文字下方无双下划线/红线
