# 实现计划

## 任务清单

### 任务 1：添加 lunar 依赖
- 文件：`pubspec.yaml`
- 在 dependencies 下新增 `lunar: ^1.7.1`
- 验证：`flutter pub get` 成功

### 任务 2：提取 AmbientBackground 组件
- 新增文件：`lib/widgets/ambient_background.dart`
- 内容：将 `main_scaffold.dart` 中的 `_AmbientBackground` 和 `_Blob` 类提取为 public 的 `AmbientBackground`（公开类），`_Blob` 保持私有即可
- 修改 `lib/main_scaffold.dart`：删除内部 `_AmbientBackground`/`_Blob` 定义，改为 `import` 并使用 `AmbientBackground()`
- 验证：`flutter analyze` 无错误

### 任务 3：实现 LunarDatePickerDialog
- 新增文件：`lib/widgets/lunar_date_picker.dart`
- 提供 `static Future<DateTime?> show(BuildContext, {required DateTime initialDate, DateTime? firstDate, DateTime? lastDate})`
- 内部：`showGeneralDialog`/`Dialog`，包含月份切换、星期表头、6×7 网格（每格显示公历+农历/节日）、取消/确定按钮
- 使用 `lunar` 包：`Solar.fromDate(date).getLunar()` 获取农历日、节日、节气
- 视觉：选中态金棕色实心圆，今日描边，节假日浅色块
- 验证：`flutter analyze` 无错误

### 任务 4：实现 CupertinoTimePickerDialog
- 新增文件：`lib/widgets/time_wheel_picker.dart`
- 提供 `static Future<String?> show(BuildContext, {required String initialTime})`
- 内部：`showCupertinoModalPopup` + 底部容器 + `CupertinoDatePicker(mode: time, use24hFormat: true)` + 取消/确定按钮
- 返回 `"HH:mm"` 字符串
- 验证：`flutter analyze` 无错误

### 任务 5：改造 HomePage 为 StatefulWidget + 日期快捷切换
- 文件：`lib/pages/home/home_page.dart`
- 改为 `StatefulWidget`，新增状态：`String _selectedDate`、`List<Reservation> _reservations = []`、`bool _loading = false`
- `initState` 调用 `_loadReservations`
- 新增 `_loadReservations(String date)`：调用 `context.read<AppProvider>().getReservationsByDate(date)`，setState 更新 `_reservations`
- 顶部在 `PageHeader` 下方新增日期快捷条：5 个 `FilterPill`（昨日/今日/明日/后日/大后日），active 判定基于 `_selectedDate` 与 `TimeUtil.dateOffset(TimeUtil.today(), offset)`
- `PageHeader` 副标题动态：`${label} · ${TimeUtil.formatDateZh(_selectedDate)}`
- 统计/即将到店/时段/全部预订章节基于 `_reservations` 而非 `provider.todayReservations`
- "今日" 章节文案改为动态标签（如选中明日则显示"明日全部预订"）
- "即将到店"区块仅在 `_selectedDate == TimeUtil.today()` 时显示
- "查询空闲"按钮改为金棕色填充样式（见任务 7）
- 验证：`flutter analyze` 无错误

### 任务 6：修复 AvailabilityPage 黑底/双下划线 Bug
- 文件：`lib/pages/availability/availability_page.dart`
- `build` 方法返回 `Scaffold`，`backgroundColor: Colors.transparent`
- `body` 外层用 `Stack`：底层 `AmbientBackground()`，上层 `SafeArea` + 原 `ListView`
- 时间选择器 `_TimeField._pick` 改为调用 `CupertinoTimePickerDialog.show`
- 日期选择器 `_pickDate` 改为调用 `LunarDatePickerDialog.show`
- 验证：`flutter analyze` 无错误

### 任务 7：修改「查询空闲」按钮样式
- 文件：`lib/pages/home/home_page.dart`
- 将 `OutlinedButton.icon` 改为 `ElevatedButton.icon`，自定义 `style`：
  - `backgroundColor: AppTheme.accentSoft.withOpacity(0.18)`
  - `foregroundColor: AppTheme.accentDeep`
  - `side: BorderSide(color: AppTheme.accent)`
  - `elevation: 0`
- 验证：与左侧"新建预订"形成主次对比，且与背景区分明显

### 任务 8：替换 ReservationFormPage 的时间/日期选择器
- 文件：`lib/pages/reservation/reservation_form_page.dart`
- `_TimePickerField._pick` 改为调用 `CupertinoTimePickerDialog.show`
- `_pickDate` 改为调用 `LunarDatePickerDialog.show`
- 验证：`flutter analyze` 无错误

### 任务 9：最终验证
- 运行 `flutter analyze`
- 运行 `flutter test`
- 确保所有改动符合设计文档
