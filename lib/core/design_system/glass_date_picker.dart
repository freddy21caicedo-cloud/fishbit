import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';

enum DatePickerSelectionMode { single, range }

/// Representación inmutable de una fecha civil (Año, Mes, Día) sin zona horaria UTC
class CivilDate {
  final int year;
  final int month;
  final int day;

  const CivilDate(this.year, this.month, this.day);

  factory CivilDate.fromDate(DateTime dt) => CivilDate(dt.year, dt.month, dt.day);

  factory CivilDate.today() {
    final now = DateTime.now();
    return CivilDate(now.year, now.month, now.day);
  }

  factory CivilDate.parse(String str) {
    final parts = str.split('-');
    if (parts.length == 3) {
      return CivilDate(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return CivilDate.today();
  }

  DateTime toDateTime() => DateTime(year, month, day);

  String toIso8601() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  String toDisplayString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$d/$m/$year';
  }

  bool isSameDay(CivilDate other) =>
      year == other.year && month == other.month && day == other.day;

  bool isBefore(CivilDate other) {
    if (year != other.year) return year < other.year;
    if (month != other.month) return month < other.month;
    return day < other.day;
  }

  bool isAfter(CivilDate other) {
    if (year != other.year) return year > other.year;
    if (month != other.month) return month > other.month;
    return day > other.day;
  }

  bool isBetween(CivilDate start, CivilDate end) =>
      (isAfter(start) && isBefore(end)) || isSameDay(start) || isSameDay(end);

  CivilDate addDays(int days) {
    final dt = DateTime(year, month, day).add(Duration(days: days));
    return CivilDate(dt.year, dt.month, dt.day);
  }

  CivilDate addMonths(int months) {
    var newYear = year;
    var newMonth = month + months;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    final daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
    final newDay = day > daysInNewMonth ? daysInNewMonth : day;
    return CivilDate(newYear, newMonth, newDay);
  }

  CivilDate addYears(int years) {
    final newYear = year + years;
    final daysInNewMonth = DateUtils.getDaysInMonth(newYear, month);
    final newDay = day > daysInNewMonth ? daysInNewMonth : day;
    return CivilDate(newYear, month, newDay);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CivilDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() => toIso8601();
}

class CivilDateRange {
  final CivilDate start;
  final CivilDate? end;

  const CivilDateRange({required this.start, this.end});

  String toDisplayString() {
    if (end == null || start.isSameDay(end!)) {
      return start.toDisplayString();
    }
    return '${start.toDisplayString()} - ${end!.toDisplayString()}';
  }
}

/// Campo de fecha estilo shadcn/ui (Popover + Calendar)
class GlassDatePickerField extends StatefulWidget {
  final String label;
  final CivilDate? initialDate;
  final CivilDateRange? initialRange;
  final DatePickerSelectionMode mode;
  final ValueChanged<CivilDate>? onDateChanged;
  final ValueChanged<CivilDateRange>? onRangeChanged;
  final String? placeholder;
  final Color accentColor;
  final bool enabled;

  const GlassDatePickerField({
    super.key,
    required this.label,
    this.initialDate,
    this.initialRange,
    this.mode = DatePickerSelectionMode.single,
    this.onDateChanged,
    this.onRangeChanged,
    this.placeholder,
    this.accentColor = AppColors.cyanWater,
    this.enabled = true,
  });

  @override
  State<GlassDatePickerField> createState() => _GlassDatePickerFieldState();
}

class _GlassDatePickerFieldState extends State<GlassDatePickerField> {
  CivilDate? _selectedDate;
  CivilDateRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? CivilDate.today();
    _selectedRange = widget.initialRange;
  }

  @override
  void didUpdateWidget(covariant GlassDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
    }
    if (widget.initialRange != oldWidget.initialRange) {
      _selectedRange = widget.initialRange;
    }
  }

  void _showCalendarPopover() async {
    if (!widget.enabled) return;

    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GlassCalendarPopover(
            mode: widget.mode,
            initialDate: _selectedDate,
            initialRange: _selectedRange,
            accentColor: widget.accentColor,
          ),
        ),
      ),
    );

    if (result != null) {
      if (widget.mode == DatePickerSelectionMode.single && result is CivilDate) {
        setState(() => _selectedDate = result);
        widget.onDateChanged?.call(result);
      } else if (widget.mode == DatePickerSelectionMode.range && result is CivilDateRange) {
        setState(() => _selectedRange = result);
        widget.onRangeChanged?.call(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.mode == DatePickerSelectionMode.single
        ? (_selectedDate?.toDisplayString() ?? widget.placeholder ?? 'Seleccionar fecha')
        : (_selectedRange?.toDisplayString() ?? widget.placeholder ?? 'Seleccionar rango');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMicro.copyWith(
            color: widget.accentColor,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _showCalendarPopover,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accentColor.withValues(alpha: isDark ? 0.35 : 0.45),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? widget.accentColor.withValues(alpha: 0.08) : const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 17, color: widget.accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textSecondaryDark.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Calendario Popover shadcn/ui con modifiers react-day-picker (range_start, range_middle, range_end, outside)
class GlassCalendarPopover extends StatefulWidget {
  final DatePickerSelectionMode mode;
  final CivilDate? initialDate;
  final CivilDateRange? initialRange;
  final Color accentColor;

  const GlassCalendarPopover({
    super.key,
    this.mode = DatePickerSelectionMode.single,
    this.initialDate,
    this.initialRange,
    this.accentColor = AppColors.cyanWater,
  });

  @override
  State<GlassCalendarPopover> createState() => _GlassCalendarPopoverState();
}

class _GlassCalendarPopoverState extends State<GlassCalendarPopover> {
  late CivilDate _currentMonth;
  CivilDate? _selectedSingleDate;
  CivilDate? _rangeStart;
  CivilDate? _rangeEnd;
  late CivilDate _focusedDate;
  final FocusNode _focusNode = FocusNode();

  static const List<String> _weekdays = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
  static const List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    final today = CivilDate.today();
    _selectedSingleDate = widget.initialDate ?? today;
    _rangeStart = widget.initialRange?.start;
    _rangeEnd = widget.initialRange?.end;
    _focusedDate = _selectedSingleDate ?? _rangeStart ?? today;
    _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onDaySelected(CivilDate day) {
    if (widget.mode == DatePickerSelectionMode.single) {
      setState(() {
        _selectedSingleDate = day;
        _focusedDate = day;
      });
      Navigator.of(context).pop(day);
    } else {
      // Range mode
      setState(() {
        if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
          _rangeStart = day;
          _rangeEnd = null;
        } else if (_rangeStart != null && _rangeEnd == null) {
          if (day.isBefore(_rangeStart!)) {
            _rangeEnd = _rangeStart;
            _rangeStart = day;
          } else {
            _rangeEnd = day;
          }
        }
        _focusedDate = day;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() {
          _focusedDate = _focusedDate.addDays(-1);
          if (_focusedDate.month != _currentMonth.month) {
            _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
          }
        });
        break;
      case LogicalKeyboardKey.arrowRight:
        setState(() {
          _focusedDate = _focusedDate.addDays(1);
          if (_focusedDate.month != _currentMonth.month) {
            _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
          }
        });
        break;
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _focusedDate = _focusedDate.addDays(-7);
          if (_focusedDate.month != _currentMonth.month) {
            _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
          }
        });
        break;
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _focusedDate = _focusedDate.addDays(7);
          if (_focusedDate.month != _currentMonth.month) {
            _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
          }
        });
        break;
      case LogicalKeyboardKey.pageUp:
        setState(() {
          if (isShiftPressed) {
            _currentMonth = _currentMonth.addYears(-1);
          } else {
            _currentMonth = _currentMonth.addMonths(-1);
          }
          _focusedDate = CivilDate(_currentMonth.year, _currentMonth.month, 1);
        });
        break;
      case LogicalKeyboardKey.pageDown:
        setState(() {
          if (isShiftPressed) {
            _currentMonth = _currentMonth.addYears(1);
          } else {
            _currentMonth = _currentMonth.addMonths(1);
          }
          _focusedDate = CivilDate(_currentMonth.year, _currentMonth.month, 1);
        });
        break;
      case LogicalKeyboardKey.home:
        setState(() {
          final dayOfWeek = _focusedDate.toDateTime().weekday; // 1 = Lu, 7 = Do
          _focusedDate = _focusedDate.addDays(-(dayOfWeek - 1));
          if (_focusedDate.month != _currentMonth.month) {
            _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
          }
        });
        break;
      case LogicalKeyboardKey.end:
        setState(() {
          final dayOfWeek = _focusedDate.toDateTime().weekday;
          _focusedDate = _focusedDate.addDays(7 - dayOfWeek);
          if (_focusedDate.month != _currentMonth.month) {
            _currentMonth = CivilDate(_focusedDate.year, _focusedDate.month, 1);
          }
        });
        break;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _onDaySelected(_focusedDate);
        break;
    }
  }

  void _applyPreset(String preset) {
    final today = CivilDate.today();
    if (preset == 'Hoy') {
      if (widget.mode == DatePickerSelectionMode.single) {
        Navigator.of(context).pop(today);
      } else {
        Navigator.of(context).pop(CivilDateRange(start: today, end: today));
      }
    } else if (preset == 'Ayer') {
      final yest = today.addDays(-1);
      if (widget.mode == DatePickerSelectionMode.single) {
        Navigator.of(context).pop(yest);
      } else {
        Navigator.of(context).pop(CivilDateRange(start: yest, end: yest));
      }
    } else if (preset == 'Últimos 7d') {
      Navigator.of(context).pop(CivilDateRange(start: today.addDays(-6), end: today));
    } else if (preset == 'Últimos 30d') {
      Navigator.of(context).pop(CivilDateRange(start: today.addDays(-29), end: today));
    } else if (preset == 'Este Mes') {
      final start = CivilDate(today.year, today.month, 1);
      Navigator.of(context).pop(CivilDateRange(start: start, end: today));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = CivilDate.today();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(18),
        blur: 24,
        opacity: 0.16,
        borderColor: Colors.white.withValues(alpha: 0.16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del Mes y Flechas de Navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                  onPressed: () => setState(() => _currentMonth = _currentMonth.addMonths(-1)),
                  tooltip: 'Mes anterior (PageUp)',
                ),
                Text(
                  '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                  onPressed: () => setState(() => _currentMonth = _currentMonth.addMonths(1)),
                  tooltip: 'Mes siguiente (PageDown)',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips Rápidos de Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('Hoy'),
                  const SizedBox(width: 6),
                  _buildPresetChip('Ayer'),
                  if (widget.mode == DatePickerSelectionMode.range) ...[
                    const SizedBox(width: 6),
                    _buildPresetChip('Últimos 7d'),
                    const SizedBox(width: 6),
                    _buildPresetChip('Últimos 30d'),
                    const SizedBox(width: 6),
                    _buildPresetChip('Este Mes'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Días de la semana (Lu Ma Mi Ju Vi Sá Do)
            Row(
              children: _weekdays.map((w) {
                return Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Grid Semanal estructurado (react-day-picker table structure)
            _buildCalendarTable(today),

            // Footer con confirmación en modo rango
            if (widget.mode == DatePickerSelectionMode.range) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _rangeStart != null
                          ? (_rangeEnd != null
                              ? '${_rangeStart!.toDisplayString()} - ${_rangeEnd!.toDisplayString()}'
                              : '${_rangeStart!.toDisplayString()} - ...')
                          : 'Selecciona rango',
                      style: AppTypography.bodySmall.copyWith(color: widget.accentColor, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: _rangeStart != null
                        ? () {
                            final finalEnd = _rangeEnd ?? _rangeStart!;
                            Navigator.of(context).pop(CivilDateRange(start: _rangeStart!, end: finalEnd));
                          }
                        : null,
                    child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label) {
    return InkWell(
      onTap: () => _applyPreset(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCalendarTable(CivilDate today) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Lu, 7 = Do
    final prevMonth = _currentMonth.addMonths(-1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    final totalLeadingDays = firstDayWeekday - 1;
    final totalCells = ((totalLeadingDays + daysInMonth) / 7).ceil() * 7;
    final totalWeeks = totalCells ~/ 7;

    final List<Widget> weekRows = [];

    for (var week = 0; week < totalWeeks; week++) {
      final List<Widget> dayCells = [];

      for (var col = 0; col < 7; col++) {
        final index = week * 7 + col;
        CivilDate date;
        bool isOutside = false;

        if (index < totalLeadingDays) {
          // Días del mes anterior (outside/muted)
          final day = daysInPrevMonth - (totalLeadingDays - index - 1);
          date = CivilDate(prevMonth.year, prevMonth.month, day);
          isOutside = true;
        } else if (index >= totalLeadingDays + daysInMonth) {
          // Días del mes siguiente (outside/muted)
          final day = index - (totalLeadingDays + daysInMonth) + 1;
          final nextMonth = _currentMonth.addMonths(1);
          date = CivilDate(nextMonth.year, nextMonth.month, day);
          isOutside = true;
        } else {
          // Días del mes actual
          final day = index - totalLeadingDays + 1;
          date = CivilDate(_currentMonth.year, _currentMonth.month, day);
          isOutside = false;
        }

        dayCells.add(
          Expanded(
            child: _buildDayCell(date, today, isOutside: isOutside),
          ),
        );
      }

      weekRows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: dayCells),
        ),
      );
    }

    return Column(children: weekRows);
  }

  Widget _buildDayCell(CivilDate cellDate, CivilDate today, {required bool isOutside}) {
    final isToday = cellDate.isSameDay(today);
    final isFocused = cellDate.isSameDay(_focusedDate);

    bool isSelectedSingle = false;
    bool isRangeStart = false;
    bool isRangeEnd = false;
    bool isRangeMiddle = false;

    if (widget.mode == DatePickerSelectionMode.single) {
      isSelectedSingle = _selectedSingleDate != null && cellDate.isSameDay(_selectedSingleDate!);
    } else {
      if (_rangeStart != null) {
        isRangeStart = cellDate.isSameDay(_rangeStart!);
      }
      if (_rangeEnd != null) {
        isRangeEnd = cellDate.isSameDay(_rangeEnd!);
      }
      if (_rangeStart != null && _rangeEnd != null) {
        isRangeMiddle = cellDate.isAfter(_rangeStart!) && cellDate.isBefore(_rangeEnd!);
      }
    }

    final isEndpoint = isSelectedSingle || isRangeStart || isRangeEnd;

    // Estructura shadcn/ui: range_start, range_middle, range_end
    BorderRadius borderRadius;
    if (isRangeStart && isRangeEnd) {
      borderRadius = BorderRadius.circular(10);
    } else if (isRangeStart) {
      borderRadius = const BorderRadius.horizontal(left: Radius.circular(10));
    } else if (isRangeEnd) {
      borderRadius = const BorderRadius.horizontal(right: Radius.circular(10));
    } else if (isRangeMiddle) {
      borderRadius = BorderRadius.zero;
    } else {
      borderRadius = BorderRadius.circular(10);
    }

    Color bgColor = Colors.transparent;
    if (isEndpoint) {
      bgColor = widget.accentColor;
    } else if (isRangeMiddle) {
      bgColor = widget.accentColor.withValues(alpha: 0.18);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color textColor;
    if (isEndpoint) {
      textColor = widget.accentColor.computeLuminance() > 0.45 ? Colors.black : Colors.white;
    } else if (isRangeMiddle) {
      textColor = widget.accentColor;
    } else if (isOutside) {
      textColor = isDark ? Colors.white24 : AppColors.textTertiaryLight;
    } else if (isToday) {
      textColor = widget.accentColor;
    } else {
      textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    }

    return SizedBox(
      height: 36,
      child: InkWell(
        onTap: () {
          if (isOutside) {
            setState(() => _currentMonth = CivilDate(cellDate.year, cellDate.month, 1));
          }
          _onDaySelected(cellDate);
        },
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: isFocused && !isEndpoint
                ? Border.all(color: widget.accentColor.withValues(alpha: 0.7), width: 1.8)
                : (isToday && !isEndpoint ? Border.all(color: widget.accentColor.withValues(alpha: 0.3)) : null),
          ),
          child: Center(
            child: Text(
              '${cellDate.day}',
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: isEndpoint || (isToday && !isOutside) ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
