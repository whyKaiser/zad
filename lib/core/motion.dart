import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// تمرير مطّاطي على كل المنصّات — إحساس iOS الأساسي.
class ZadScrollBehavior extends MaterialScrollBehavior {
  const ZadScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

/// ثوابت الحركة. الأرقام مأخوذة من إرشادات Apple للحركة السلسة:
/// الاستجابة ٠٫٣–٠٫٤ ثانية، وبلا ارتداد إلا حين تسبقها حركة من المستخدم.
abstract class ZadMotion {
  /// ردّ فعل الضغط — يجب أن يكون فورياً بحيث لا يُحسّ كتأخير.
  static const pressIn = Duration(milliseconds: 90);
  static const pressOut = Duration(milliseconds: 260);

  /// تغيّر حالة عنصر (اختيار شريحة، تبديل).
  static const state = Duration(milliseconds: 220);

  /// دخول محتوى الشاشة.
  static const enter = Duration(milliseconds: 320);

  /// منحنى ارتداد خفيف — للعودة بعد الضغط فقط، حيث سبقتها حركة فعلية.
  static const springBack = Curves.easeOutBack;
  static const standard = Curves.easeOutCubic;

  /// هل أوقف المستخدم الحركة من إعدادات الجهاز؟
  /// Apple: تقليل الحركة لا يعني إلغاء ردّ الفعل، بل استبداله بتلاشٍ لطيف.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// مدّة تحترم إعداد تقليل الحركة.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// عنصر قابل للضغط بردّ فعل لحظي.
///
/// قاعدة Apple الأولى: الاستجابة تكون عند **الضغط** لا عند الإفلات.
/// `GestureDetector` وحده يترك العنصر ميتاً حتى ينتهي الإجراء، فيبدو التطبيق بطيئاً
/// حتى لو كان سريعاً. هنا يتقلّص العنصر فور اللمس ويعود بارتداد خفيف عند الإفلات.
class ZadTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// مقدار التقلّص. الافتراضي مناسب للبطاقات؛ العناصر الصغيرة تحتاج أقل.
  final double pressedScale;

  /// خفوت خفيف مع التقلّص — يقوّي الإحساس على البطاقات الكبيرة.
  final bool dim;

  /// سلوك اللمس — `opaque` يجعل كامل المساحة قابلة للّمس.
  final HitTestBehavior behavior;

  const ZadTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.dim = false,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ZadTap> createState() => _ZadTapState();
}

class _ZadTapState extends State<ZadTap> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v || !mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduced = ZadMotion.reduced(context);
    final scale = _pressed && enabled && !reduced ? widget.pressedScale : 1.0;

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      // الضغط يبدأ ردّ الفعل فوراً؛ الإفلات أو الإلغاء يعيده.
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: scale,
        // الدخول أسرع من الخروج: الاستجابة فورية والعودة مريحة.
        duration: _pressed ? ZadMotion.pressIn : ZadMotion.pressOut,
        curve: _pressed ? Curves.easeOut : ZadMotion.springBack,
        child: widget.dim
            ? AnimatedOpacity(
                opacity: _pressed && enabled && !reduced ? 0.78 : 1,
                duration: _pressed ? ZadMotion.pressIn : ZadMotion.pressOut,
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}

/// انتقال صفحات بإحساس iOS: انزلاق أفقي **مع إيماءة السحب للرجوع**،
/// ومنظر متوازٍ للصفحة السابقة. الانتقال قابل للمقاطعة لأن الإصبع يقوده،
/// وهو ما يميّز الإحساس الحي عن انتقال ثابت المدة لا يمكن إيقافه.
/// `CupertinoRouteTransitionMixin` يعكس الاتجاه تلقائياً مع RTL.
class ZadPageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  final Widget page;

  ZadPageRoute({required this.page, super.settings});

  @override
  Widget buildContent(BuildContext context) => page;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // تقليل الحركة: تلاشٍ لطيف بلا انزلاق (تجنّب الإحساس الدهليزي).
    if (ZadMotion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return super
        .buildTransitions(context, animation, secondaryAnimation, child);
  }
}

/// اهتزاز لمسي موحّد. Apple: اجعله مقترناً بالحدث المسبِّب نفسه،
/// واحفظه للحظات ذات معنى حتى لا يتعوّد المستخدم على تجاهله.
abstract class Haptics {
  /// إتمام إجراء (حفظ، إضافة، حذف).
  static void light() => HapticFeedback.lightImpact();

  /// تغيير اختيار (شريحة، تبويب، قيمة).
  static void select() => HapticFeedback.selectionClick();
}
