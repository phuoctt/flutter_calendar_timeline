import 'package:flutter/material.dart';
import 'package:flutter_calendar_timeline/src/separated_flexible.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

enum StartingDayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

class DatePickerTimeLine<T> extends StatefulWidget {
  final DateTime? selectedDate;
  final double height;
  final ValueChanged<DateTime>? onSelectDate;
  final ValueChanged<List<DateTime>>? onScrollWeek;
  final bool Function(DateTime day)? eventLoader;
  final DateTime lastDay;
  final DateTime firstDay;
  final DateTime focusedDay;
  final StartingDayOfWeek startingDayOfWeek;

  const DatePickerTimeLine(
      {Key? key,
      this.height = 56,
      this.startingDayOfWeek = StartingDayOfWeek.sunday,
      required this.firstDay,
      required this.lastDay,
      required this.focusedDay,
      this.selectedDate,
      this.onSelectDate,
      this.onScrollWeek,
      this.eventLoader})
      : super(key: key);

  @override
  State<DatePickerTimeLine<T>> createState() => _DatePickerTimeLineState<T>();
}

class _DatePickerTimeLineState<T> extends State<DatePickerTimeLine<T>> {
  ThemeData get theme => Theme.of(context);

  late PageController _controller;
  int countShow = 7;

  late DateTime _selectedDate;
  int _initialPage = 0;

  late bool _pageCallbackDisabled;

  @override
  void initState() {
    initializeDateFormatting();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    _initialPage = _getInitPage(widget.focusedDay);
    _controller = PageController(initialPage: _initialPage);
    _pageCallbackDisabled = false;
    super.initState();
  }

  DateTime get firstDayWeek => _getFirstDayWeek();

  DateTime get lastDayWeek => _getLastDayWeek();

  int get totalWeekOfYear {
    try {
      return ((lastDayWeek.difference(firstDayWeek).inDays) ~/ 7 + 1);
    } catch (e) {
      return 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DatePickerTimeLine<T> oldWidget) {
    if (_selectedDate != widget.selectedDate) {
      _selectedDate = widget.selectedDate ?? DateTime.now();
      final pageOld = _initialPage;
      final pageNow = _getInitPage(_selectedDate);
      if (pageOld != pageNow) {
        _controller.jumpToPage(pageNow);
        _pageCallbackDisabled = true;
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        onPageChanged: (index) {
          if (!_pageCallbackDisabled) {
            _initialPage = index;
            final startDateOfWeek = firstDayWeek.add(Duration(days: 7 * index));
            widget.onScrollWeek?.call(List.generate(countShow,
                (index) => startDateOfWeek.add(Duration(days: index))));
          }
          _pageCallbackDisabled = false;
        },
        controller: _controller,
        itemCount: totalWeekOfYear,
        itemBuilder: (context, index) {
          final startDateOfWeek = firstDayWeek.add(Duration(days: 7 * index));
          return _buildRowDatePicker(startDateOfWeek);
        },
      ),
    );
  }

  Widget _buildRowDatePicker(DateTime startDateOfWeek) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateBuilder) {
      return SeparatedRow(
        separatorBuilder: () => const SizedBox(
          width: 16,
        ),
        children: List.generate(countShow, (index) {
          DateTime date = startDateOfWeek.add(Duration(days: index));
          bool enable = (date.isAfter(widget.firstDay) &&
                  date.isBefore(widget.lastDay)) ||
              isSameDay(date, widget.firstDay) ||
              isSameDay(date, widget.lastDay);

          var isSelected = isSameDay(date, _selectedDate);
          final bol = widget.eventLoader?.call(date) ?? false;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (!enable) return;
                  setStateBuilder(() {});
                  _selectedDate = date;
                  widget.onSelectDate?.call(date);
                },
                child: Ink(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isSameDay(date, DateTime.now())
                        ? Border.all(
                            color: Colors.blue,
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Opacity(
                    opacity: enable ? 1 : 0.5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDate(date, format: 'EEE'),
                          maxLines: 1,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: index == 6 || index == 5
                                ? Colors.red
                                : isSelected
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        Text(
                          _getDate(date, format: 'dd'),
                          maxLines: 1,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        _buildDotEvent(bol)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildDotEvent(bool visible) => Visibility(
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        visible: visible,
        child: Container(
          height: 6,
          width: 6,
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
        ),
      );

  int _getInitPage(DateTime data) =>
      totalWeekOfYear - ((lastDayWeek.difference(data).inDays) ~/ 7 + 1);

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDate(DateTime? date, {String? format}) {
    const locale = 'vi';
    try {
      return DateFormat(format, locale).format(date!);
    } catch (e) {
      return '';
    }
  }

  DateTime _getFirstDayWeek() {
    final date = DateTime(
      widget.firstDay.year,
      widget.firstDay.month,
      widget.firstDay.day,
    );
    int currentDay = date.weekday;
    return date.subtract(Duration(days: currentDay - _getWeekdayNumber()));
  }

  DateTime _getLastDayWeek() {
    final date = DateTime(
      widget.lastDay.year,
      widget.lastDay.month,
      widget.lastDay.day,
    );
    int currentDay = date.weekday;
    return date.subtract(Duration(days: currentDay - _getWeekdayNumber()));
  }
  int _getWeekdayNumber() {
    return StartingDayOfWeek.values.indexOf(widget.startingDayOfWeek);
  }
}
