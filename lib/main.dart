import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Facet Calculator',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0C0E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFA31A),
        surface: Color(0xFF17191D),
      ),
      fontFamily: 'SF Pro Display',
      useMaterial3: true,
    ),
    home: const CalculatorScreen(),
  );
}

class Calculation {
  const Calculation(this.expression, this.result);
  final String expression;
  final String result;
}

enum CalculatorAppearance { light, dark, glass }

class _Palette {
  const _Palette({
    required this.background,
    required this.surface,
    required this.key,
    required this.utility,
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.border,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color key;
  final Color utility;
  final Color primary;
  final Color secondary;
  final Color muted;
  final Color border;
  final Color shadow;

  static const dark = _Palette(
    background: Color(0xFF080A0D),
    surface: Color(0xFF15181D),
    key: Color(0xFF2C3037),
    utility: Color(0xFF5E626A),
    primary: Color(0xFFF7F8FA),
    secondary: Color(0xFFFFA31A),
    muted: Color(0xFF858A94),
    border: Color(0x1AFFFFFF),
    shadow: Color(0x99000000),
  );

  static const light = _Palette(
    background: Color(0xFFE9EDF3),
    surface: Color(0xFFF9FAFC),
    key: Color(0xFFE1E5EB),
    utility: Color(0xFFC8CED7),
    primary: Color(0xFF171A1F),
    secondary: Color(0xFFEA7B16),
    muted: Color(0xFF737A85),
    border: Color(0x180F172A),
    shadow: Color(0x240F172A),
  );

  static const glass = _Palette(
    background: Color(0xFF07121D),
    surface: Color(0x4DFFFFFF),
    key: Color(0x24FFFFFF),
    utility: Color(0x42FFFFFF),
    primary: Color(0xFFF5FBFF),
    secondary: Color(0xFF73DBFF),
    muted: Color(0xFFB5C8D4),
    border: Color(0x38FFFFFF),
    shadow: Color(0x66000000),
  );
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final FocusNode _keyboardFocus = FocusNode();
  final List<Calculation> _history = [];
  String _display = '0';
  double? _storedValue;
  String? _pendingOperator;
  String? _lastOperator;
  double? _lastOperand;
  bool _replaceDisplay = true;
  bool _justEvaluated = false;
  CalculatorAppearance _appearance = CalculatorAppearance.dark;

  static const _operatorSymbols = {'/': '÷', '*': '×', '-': '−', '+': '+'};

  _Palette get _palette => switch (_appearance) {
    CalculatorAppearance.light => _Palette.light,
    CalculatorAppearance.dark => _Palette.dark,
    CalculatorAppearance.glass => _Palette.glass,
  };

  bool get _isGlass => _appearance == CalculatorAppearance.glass;

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  double get _currentValue =>
      double.tryParse(_display.replaceAll(',', '')) ?? 0;

  String get _expressionPreview {
    if (_pendingOperator != null && _storedValue != null) {
      return '${_format(_storedValue!)} ${_operatorSymbols[_pendingOperator]}';
    }
    if (_justEvaluated && _lastOperator != null && _lastOperand != null) {
      return '${_format(_storedValue ?? _currentValue)} ${_operatorSymbols[_lastOperator]} ${_format(_lastOperand!)}';
    }
    return _history.isEmpty ? 'Ready' : _history.first.expression;
  }

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value.abs() < 1e-12) value = 0;
    final abs = value.abs();
    if (abs >= 1e12 || (abs > 0 && abs < 1e-8)) {
      return value.toStringAsExponential(6).replaceAll(RegExp(r'0+e'), 'e');
    }
    var raw = value.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
    final parts = raw.split('.');
    final sign = parts[0].startsWith('-') ? '-' : '';
    final digits = parts[0].replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    raw = '$sign$grouped';
    if (parts.length == 2) raw += '.${parts[1]}';
    return raw;
  }

  String _plainDisplay() => _display.replaceAll(',', '');

  void _inputDigit(String digit) {
    setState(() {
      if (_replaceDisplay || _justEvaluated) {
        _display = digit;
        _replaceDisplay = false;
        _justEvaluated = false;
      } else {
        final plain = _plainDisplay();
        if (plain.replaceAll(RegExp(r'[-.]'), '').length >= 12) return;
        _display = plain == '0' ? digit : '$plain$digit';
      }
      _display = _formatInput(_display);
    });
  }

  String _formatInput(String value) {
    if (value.endsWith('.')) {
      return '${_format(double.parse(value.substring(0, value.length - 1)))}.';
    }
    final parts = value.split('.');
    final whole = double.tryParse(parts.first) ?? 0;
    final formatted = _format(whole);
    return parts.length == 2 ? '$formatted.${parts[1]}' : formatted;
  }

  void _decimal() {
    setState(() {
      if (_replaceDisplay || _justEvaluated) {
        _display = '0.';
        _replaceDisplay = false;
        _justEvaluated = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _storedValue = null;
      _pendingOperator = null;
      _lastOperator = null;
      _lastOperand = null;
      _replaceDisplay = true;
      _justEvaluated = false;
    });
  }

  void _backspace() {
    if (_replaceDisplay || _justEvaluated) return;
    setState(() {
      final plain = _plainDisplay();
      final shortened = plain.length > 1
          ? plain.substring(0, plain.length - 1)
          : '0';
      _display = (shortened == '-' || shortened.isEmpty)
          ? '0'
          : _formatInput(shortened);
      if (_display == '0') _replaceDisplay = true;
    });
  }

  void _toggleSign() {
    if (_display == '0' || _display == 'Error') return;
    setState(
      () => _display = _display.startsWith('-')
          ? _display.substring(1)
          : '-$_display',
    );
  }

  void _percent() {
    if (_display == 'Error') return;
    setState(() {
      var value = _currentValue;
      if (_storedValue != null &&
          (_pendingOperator == '+' || _pendingOperator == '-')) {
        value = _storedValue! * value / 100;
      } else {
        value /= 100;
      }
      _display = _format(value);
      _replaceDisplay = true;
    });
  }

  double? _calculate(double left, String operator, double right) {
    switch (operator) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '*':
        return left * right;
      case '/':
        return right == 0 ? null : left / right;
    }
    return right;
  }

  void _chooseOperator(String operator) {
    if (_display == 'Error') _clear();
    setState(() {
      if (_pendingOperator != null &&
          !_replaceDisplay &&
          _storedValue != null) {
        final result = _calculate(
          _storedValue!,
          _pendingOperator!,
          _currentValue,
        );
        if (result == null) return _showError();
        _storedValue = result;
        _display = _format(result);
      } else {
        _storedValue = _currentValue;
      }
      _pendingOperator = operator;
      _replaceDisplay = true;
      _justEvaluated = false;
    });
  }

  void _equals() {
    if (_display == 'Error') return;
    setState(() {
      final operator = _pendingOperator ?? _lastOperator;
      final left = _pendingOperator != null
          ? (_storedValue ?? 0)
          : _currentValue;
      final right = _pendingOperator != null ? _currentValue : _lastOperand;
      if (operator == null || right == null) return;
      final result = _calculate(left, operator, right);
      if (result == null) return _showError();
      final expression =
          '${_format(left)} ${_operatorSymbols[operator]} ${_format(right)}';
      final formattedResult = _format(result);
      _history.insert(0, Calculation(expression, formattedResult));
      _display = formattedResult;
      _storedValue = result;
      _lastOperator = operator;
      _lastOperand = right;
      _pendingOperator = null;
      _replaceDisplay = true;
      _justEvaluated = true;
    });
  }

  void _showError() {
    _display = 'Error';
    _storedValue = null;
    _pendingOperator = null;
    _lastOperator = null;
    _lastOperand = null;
    _replaceDisplay = true;
    _justEvaluated = false;
  }

  void _useHistory(Calculation item) {
    setState(() {
      _display = item.result;
      _storedValue = double.tryParse(item.result.replaceAll(',', ''));
      _pendingOperator = null;
      _replaceDisplay = true;
      _justEvaluated = true;
    });
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final key = event.logicalKey;
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) _inputDigit(char);
    if (char == '.') _decimal();
    if (['+', '-', '*', '/'].contains(char)) _chooseOperator(char!);
    if (char == '%') _percent();
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.equal) {
      _equals();
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _backspace();
    }
    if (key == LogicalKeyboardKey.escape) _clear();
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .68,
        child: _HistoryPanel(
          history: _history,
          onUse: _useHistory,
          onClear: () => setState(_history.clear),
          showClose: true,
          palette: _palette,
          glass: _isGlass,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          color: palette.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isGlass) const _AuroraBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 860;
                    final padding = wide ? 20.0 : 8.0;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: wide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildCalculator(true)),
                                    const SizedBox(width: 14),
                                    SizedBox(
                                      width: 300,
                                      child: _HistoryPanel(
                                        history: _history,
                                        onUse: _useHistory,
                                        onClear: () => setState(_history.clear),
                                        palette: palette,
                                        glass: _isGlass,
                                      ),
                                    ),
                                  ],
                                )
                              : _buildCalculator(false),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculator(bool wide) {
    final palette = _palette;
    return _GlassSurface(
      palette: palette,
      glass: _isGlass,
      radius: wide ? 38 : 32,
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 26 : 16, 12, wide ? 26 : 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: palette.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'FACET',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: palette.muted,
                    ),
                  ),
                  const Spacer(),
                  _AppearanceToggle(
                    value: _appearance,
                    palette: palette,
                    onChanged: (value) => setState(() => _appearance = value),
                  ),
                  if (!wide) ...[
                    const SizedBox(width: 6),
                    _TopButton(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: _showHistory,
                      palette: palette,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 28,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        _expressionPreview,
                        key: ValueKey(_expressionPreview),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      key: const Key('display'),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, .12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _display,
                          key: ValueKey(_display),
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 62,
                            height: 1,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(flex: 72, child: _buildKeypad()),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = <_KeyData>[
      _KeyData(
        _replaceDisplay ? 'AC' : 'C',
        _clear,
        tone: _KeyTone.utility,
        semantic: 'Clear',
      ),
      _KeyData(
        '±',
        _toggleSign,
        tone: _KeyTone.utility,
        semantic: 'Toggle positive or negative',
      ),
      _KeyData('%', _percent, tone: _KeyTone.utility, semantic: 'Percent'),
      _KeyData(
        '÷',
        () => _chooseOperator('/'),
        tone: _KeyTone.operator,
        active: _pendingOperator == '/',
        semantic: 'Divide',
      ),
      _KeyData('7', () => _inputDigit('7')),
      _KeyData('8', () => _inputDigit('8')),
      _KeyData('9', () => _inputDigit('9')),
      _KeyData(
        '×',
        () => _chooseOperator('*'),
        tone: _KeyTone.operator,
        active: _pendingOperator == '*',
        semantic: 'Multiply',
      ),
      _KeyData('4', () => _inputDigit('4')),
      _KeyData('5', () => _inputDigit('5')),
      _KeyData('6', () => _inputDigit('6')),
      _KeyData(
        '−',
        () => _chooseOperator('-'),
        tone: _KeyTone.operator,
        active: _pendingOperator == '-',
        semantic: 'Subtract',
      ),
      _KeyData('1', () => _inputDigit('1')),
      _KeyData('2', () => _inputDigit('2')),
      _KeyData('3', () => _inputDigit('3')),
      _KeyData(
        '+',
        () => _chooseOperator('+'),
        tone: _KeyTone.operator,
        active: _pendingOperator == '+',
        semantic: 'Add',
      ),
      _KeyData(
        '⌫',
        _backspace,
        icon: Icons.backspace_outlined,
        semantic: 'Backspace',
      ),
      _KeyData('0', () => _inputDigit('0')),
      _KeyData('.', _decimal, semantic: 'Decimal point'),
      _KeyData('=', _equals, tone: _KeyTone.equals, semantic: 'Equals'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 9.0;
        final keyHeight = (constraints.maxHeight - gap * 4) / 5;
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: keyHeight,
          ),
          itemBuilder: (_, index) => _CalculatorKey(
            data: keys[index],
            palette: _palette,
            glass: _isGlass,
          ),
        );
      },
    );
  }
}

enum _KeyTone { number, utility, operator, equals }

class _KeyData {
  const _KeyData(
    this.label,
    this.onTap, {
    this.tone = _KeyTone.number,
    this.icon,
    this.active = false,
    this.semantic,
  });
  final String label;
  final VoidCallback onTap;
  final _KeyTone tone;
  final IconData? icon;
  final bool active;
  final String? semantic;
}

class _CalculatorKey extends StatelessWidget {
  const _CalculatorKey({
    required this.data,
    required this.palette,
    required this.glass,
  });
  final _KeyData data;
  final _Palette palette;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground = palette.primary;
    switch (data.tone) {
      case _KeyTone.utility:
        background = palette.utility;
      case _KeyTone.operator:
        background = data.active ? palette.primary : palette.secondary;
        foreground = data.active
            ? palette.secondary
            : (glass ? const Color(0xFF07121D) : Colors.white);
      case _KeyTone.equals:
        background = palette.secondary;
        foreground = glass ? const Color(0xFF07121D) : Colors.white;
      case _KeyTone.number:
        background = palette.key;
    }
    const radius = BorderRadius.only(
      topLeft: Radius.circular(23),
      topRight: Radius.circular(8),
      bottomLeft: Radius.circular(8),
      bottomRight: Radius.circular(23),
    );
    return Semantics(
      button: true,
      label: data.semantic ?? data.label,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass ? 16 : 0,
            sigmaY: glass ? 16 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: Border.all(
                color: glass ? palette.border : Colors.transparent,
              ),
              boxShadow: glass
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: .07),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  data.onTap();
                },
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
                child: Center(
                  child: data.icon != null
                      ? Icon(data.icon, size: 24, color: foreground)
                      : Text(
                          data.label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 27,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.palette,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _Palette palette;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    icon: Icon(icon, size: 21),
    style: IconButton.styleFrom(
      backgroundColor: palette.key,
      foregroundColor: palette.secondary,
    ),
  );
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.onUse,
    required this.onClear,
    required this.palette,
    required this.glass,
    this.showClose = false,
  });
  final List<Calculation> history;
  final ValueChanged<Calculation> onUse;
  final VoidCallback onClear;
  final _Palette palette;
  final bool glass;
  final bool showClose;

  @override
  Widget build(BuildContext context) => _GlassSurface(
    palette: palette,
    glass: glass,
    radius: 30,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'History',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: palette.secondary),
                  ),
                ),
              if (showClose)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.primary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 36,
                          color: palette.muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No calculations yet',
                          style: TextStyle(color: palette.muted, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: palette.border),
                    itemBuilder: (_, index) {
                      final item = history[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 4,
                          ),
                          onTap: () => onUse(item),
                          title: Text(
                            item.expression,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            item.result,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.palette,
    required this.glass,
    required this.child,
    this.radius = 32,
  });
  final _Palette palette;
  final bool glass;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius * .34),
      bottomLeft: Radius.circular(radius * .34),
      bottomRight: Radius.circular(radius),
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass ? 30 : 0,
          sigmaY: glass ? 30 : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: borderRadius,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle({
    required this.value,
    required this.palette,
    required this.onChanged,
  });
  final CalculatorAppearance value;
  final _Palette palette;
  final ValueChanged<CalculatorAppearance> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: palette.key,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: palette.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item(
          CalculatorAppearance.light,
          Icons.light_mode_rounded,
          'Light mode',
        ),
        _item(CalculatorAppearance.dark, Icons.dark_mode_rounded, 'Dark mode'),
        _item(
          CalculatorAppearance.glass,
          Icons.blur_on_rounded,
          'Liquid glass mode',
        ),
      ],
    ),
  );

  Widget _item(CalculatorAppearance appearance, IconData icon, String label) {
    final selected = appearance == value;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => onChanged(appearance),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? palette.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 17,
              color: selected
                  ? (appearance == CalculatorAppearance.light
                        ? Colors.white
                        : const Color(0xFF07121D))
                  : palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07121D), Color(0xFF102A3A), Color(0xFF111324)],
          ),
        ),
      ),
      Positioned(
        top: -130,
        right: -80,
        child: _orb(const Color(0xFF45D7FF), 330),
      ),
      Positioned(
        bottom: -150,
        left: -90,
        child: _orb(const Color(0xFF835CFF), 360),
      ),
      Positioned(
        top: 240,
        left: 100,
        child: _orb(const Color(0xFF16E0BD), 180),
      ),
    ],
  );

  Widget _orb(Color color, double size) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .46),
        shape: BoxShape.circle,
      ),
    ),
  );
}
