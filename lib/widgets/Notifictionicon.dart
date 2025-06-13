// lib/widgets/notifictionicon.dart
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import '../models/notification_item.dart'; // تأكدي من المسار الصحيح
import '../services/notification_manager.dart'; // تأكدي من المسار الصحيح
import 'package:flutter/foundation.dart'; // لـ debugPrint

class NotificationIcon extends StatefulWidget {
  final Function? onNotificationsUpdated; // Callback عند الحاجة لإعلام الـ Parent بتحديث هام

  const NotificationIcon({super.key, this.onNotificationsUpdated});

  @override
  NotificationIconState createState() => NotificationIconState();
}

class NotificationIconState extends State<NotificationIcon> {
  final GlobalKey _iconKey = GlobalKey();
  bool _isNotificationPopupOpen = false;
  List<NotificationItem> _activeNotifications = [];
  bool _isLoadingNotifications = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAndRefreshNotifications(notifyParent: false); // لا حاجة لإعلام الـ Parent عند التهيئة الأولية
  }

  Future<void> _loadAndRefreshNotifications({bool markAsRead = false, required bool notifyParent}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingNotifications = true;
    });
    try {
      if (markAsRead) {
        await NotificationManager.markAllActiveNotificationsAsRead();
      }
      _activeNotifications = await NotificationManager.loadActiveNotifications();
      // بعد وضع علامة "مقروء"، يتم تحديث حالة isRead لكل إشعار.
      // لذا _unreadCount سيُحسب بشكل صحيح بناءً على الحالة المحدثة.
      _unreadCount = _activeNotifications.where((n) => !n.isRead && n.isActive).length; 
      debugPrint("NotificationIcon: Loaded ${_activeNotifications.length} active notifications. Unread: $_unreadCount");
    } catch (e) {
      debugPrint("NotificationIcon: Error loading notifications: $e");
      _activeNotifications = [];
      _unreadCount = 0;
    }
    if (mounted) {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
    if (notifyParent && widget.onNotificationsUpdated != null) {
        widget.onNotificationsUpdated!();
    }
  }

  // هذه الدالة يمكن استدعاؤها من الخارج لتحديث حالة الأيقونة
  void refreshNotifications() {
    debugPrint("NotificationIcon: refreshNotifications() called from outside.");
    // عادةً، لا نحتاج لإعلام الـ parent هنا، فقط تحديث الأيقونة
    _loadAndRefreshNotifications(markAsRead: false, notifyParent: false);
  }


  void _toggleNotificationPopup(BuildContext context) {
    if (_isLoadingNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("جاري تحميل الإشعارات...", textDirection: TextDirection.rtl)),
      );
      return;
    }

    // عند فتح القائمة، قم بتحميل الإشعارات مع وضع علامة "مقروء" عليها
    // لا نحتاج عادةً لإعلام الـ Parent هنا، لأن التغيير الرئيسي هو مرئي (الشارة تقل)
    _loadAndRefreshNotifications(markAsRead: true, notifyParent: false).then((_) {
      if (!mounted) return;
      setState(() {
        _isNotificationPopupOpen = !_isNotificationPopupOpen;
      });

      if (_isNotificationPopupOpen) {
        final RenderBox? renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          debugPrint("NotificationIcon: Could not find renderBox. Popup won't show correctly.");
          if (mounted) setState(() => _isNotificationPopupOpen = false);
          return;
        }
        final Offset position = renderBox.localToGlobal(Offset.zero);
        final Size iconSize = renderBox.size;

        showDialog(
          context: context,
          barrierColor: Colors.transparent, // للسماح بالـ GestureDetector بالتقاط النقرات خارج الـ Dialog
          builder: (BuildContext dialogContext) {
            return StatefulBuilder( // للسماح بتحديث محتوى الـ Dialog عند مسح إشعار
              builder: (BuildContext context, StateSetter setDialogState) {
                return GestureDetector( // لإغلاق الـ Dialog عند النقر خارج محتواه
                  onTap: () {
                    if (mounted) {
                      setState(() { _isNotificationPopupOpen = false; });
                    }
                    Navigator.of(dialogContext).pop();
                     // بعد الإغلاق، نحدث حالة الأيقونة (العدد)
                     // ولا حاجة لإعلام الـ Parent عادةً
                    _loadAndRefreshNotifications(markAsRead: false, notifyParent: false);
                  },
                  child: Stack(
                    children: [
                      Positioned.fill( // خلفية معتمة
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),
                      Positioned(
                        top: position.dy + iconSize.height + 5,
                        right: 16, // يمكنك ضبط هذه القيم لتناسب تصميمك
                        left: 16,
                        child: Material( // يوفر الـ elevation والـ shape
                          color: Colors.transparent, 
                          elevation: 8.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: GestureDetector( // لمنع إغلاق الـ Dialog عند النقر على محتواه
                             onTap: () {}, // اتركها فارغة أو قم بمعالجة النقر على عنصر الإشعار هنا إذا أردت
                             child: Container(
                              width: MediaQuery.of(context).size.width * 0.9, // عرض الـ Popup
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "الإشعارات",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontFamily: 'Cairo'),
                                    textAlign: TextAlign.right,
                                  ),
                                  const Divider(height: 15, thickness: 0.7),
                                  if (_isLoadingNotifications && _activeNotifications.isEmpty) // عرض التحميل إذا كانت القائمة فارغة في البداية
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  else if (_activeNotifications.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.0),
                                      child: Center(
                                        child: Text(
                                          "لا توجد إشعارات حاليًا.",
                                          style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                                        ),
                                      ),
                                    )
                                  else
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _activeNotifications.length,
                                        itemBuilder: (ctx, index) {
                                          final notification = _activeNotifications[index];
                                          // الإشعارات التي تم فتح القائمة من أجلها أصبحت مقروءة
                                          // (لأننا استدعينا markAsRead: true في _loadAndRefreshNotifications)
                                          // لذا، اللون المميز سيظهر فقط للإشعارات الجديدة التي وصلت *أثناء* فتح القائمة ولم يتم إعادة تحميلها بعد
                                          // ولكن عمليًا، عند فتح القائمة، الكل يُعتبر مقروءًا.
                                          Color itemBackgroundColor = notification.isRead
                                              ? Colors.white 
                                              : Theme.of(context).primaryColor.withOpacity(0.05);

                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 5),
                                            padding: const EdgeInsets.only(top: 10, bottom:10, right: 12, left: 0),
                                            decoration: BoxDecoration(
                                              color: itemBackgroundColor,
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.grey.shade300),
                                              boxShadow: [
                                                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0,1))
                                              ]
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  tooltip: "مسح الإشعار",
                                                  onPressed: () async {
                                                    String currentNotificationId = notification.id;
                                                    
                                                    // 1. قم بإزالة الإشعار من القائمة المعروضة في الـ Dialog فورًا
                                                    setDialogState(() {
                                                      _activeNotifications.removeWhere((n) => n.id == currentNotificationId);
                                                      // لا نحدث _unreadCount هنا لأننا سنعيد تحميل كل شيء
                                                    });

                                                    // 2. قم بالعملية الفعلية في الـ Storage
                                                    await NotificationManager.dismissNotification(currentNotificationId);
                                                    
                                                    // 3. أعد تحميل الإشعارات لتحديث حالة الأيقونة الرئيسية (_unreadCount)
                                                    //    والقائمة في الـ Dialog إذا بقيت مفتوحة (على الرغم من أنها ستُزال).
                                                    //    لا حاجة لإعلام الـ Parent هنا لأن التغيير هو مسح إشعار.
                                                    if(mounted) {
                                                       _loadAndRefreshNotifications(markAsRead: false, notifyParent: false);
                                                    }
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        notification.title,
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: Theme.of(context).primaryColorDark,
                                                            fontWeight: FontWeight.bold,
                                                            fontFamily: 'Cairo'),
                                                        textAlign: TextAlign.right,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        notification.timeAgoDisplay,
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey.shade600,
                                                            fontFamily: 'Cairo'),
                                                        textAlign: TextAlign.right,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                CircleAvatar(
                                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                                  child: Icon(_getIconForNotificationType(notification.type), color: Theme.of(context).primaryColor, size: 22),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        ).then((_) { // يتم استدعاء هذا عند إغلاق الـ Dialog (سواء بالـ Navigator.pop أو بالـ GestureDetector)
          if (mounted) {
            setState(() {
              _isNotificationPopupOpen = false;
            });
             // بعد إغلاق الـ dialog، تأكد من تحديث حالة الأيقونة (العدد)
             // لا حاجة لوضع علامة "مقروء" هنا مرة أخرى، ولا لإعلام الـ Parent بشكل افتراضي.
            _loadAndRefreshNotifications(markAsRead: false, notifyParent: false);
          }
          // لا نستدعي widget.onNotificationsUpdated هنا بشكل عام
          // إذا كان هناك منطق محدد يتطلب إعلام الـ Parent، يجب أن يكون مشروطًا
        });
      } else {
         // إذا تم "إلغاء فتح" الـ popup قبل عرضه (نادر، لكن احتياطي)
         // أو إذا تم إغلاقه بطريقة أخرى لم تمر عبر .then (مثل زر الرجوع في Android)
        if (mounted) {
           _loadAndRefreshNotifications(markAsRead: false, notifyParent: false);
        }
      }
    });
  }

  IconData _getIconForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.sessionEnded: return Icons.check_circle_outline_rounded;
      case NotificationType.sessionUpcoming: return Icons.update_rounded;
      case NotificationType.sessionReady: return Icons.play_circle_fill_rounded;
      case NotificationType.monthlyTestAvailable: return Icons.assignment_turned_in_outlined;
      case NotificationType.threeMonthTestAvailable: return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Center(
        child: IconButton(
          key: _iconKey,
          tooltip: "الإشعارات",
          icon: badges.Badge(
            position: badges.BadgePosition.topEnd(top: -10, end: -8),
            showBadge: !_isLoadingNotifications && _unreadCount > 0,
            badgeContent: Text(
              _isLoadingNotifications ? "" : _unreadCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red.shade700,
              padding: const EdgeInsets.all(5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_none_rounded, color: Theme.of(context).primaryColor, size: 28),
          ),
          onPressed: () => _toggleNotificationPopup(context),
        ),
      ),
    );
  }
}