import 'package:flutter/material.dart';
import 'package:mail_assistant_mobile/settings/settings.dart';
import 'package:mail_assistant_mobile/theme/app_colors.dart';

/// Ana sayfa — Giriş yapıldıktan sonra gösterilen ekran.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late TabController _tabController;

  // ignore: unused_field
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  final String _userName = "Sadıkcan";
  final int _bekleyenMail = 14;
  final int _onayBekleyenIs = 6;
  final int _kayitliSirket = 101;
  final int _hatirlatici = 5;

  final List<Map<String, dynamic>> _events = [
    {'date': DateTime(2026, 5, 10), 'title': 'Önemli Müşteri Toplantısı', 'priority': 'Acil'},
    {'date': DateTime(2026, 5, 26), 'title': 'Proje Değerlendirme', 'priority': 'Düşük'},
    {'date': DateTime(2026, 5, 15), 'title': 'Sprint Planlama', 'priority': 'Orta'},
    {'date': DateTime(2026, 5, 20), 'title': 'Ekip Toplantısı', 'priority': 'Düşük'},
  ];

  static const List<String> _priorityLevels = ['Düşük', 'Orta', 'Acil'];

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Acil':
        return const Color(0xFFEF4444);
      case 'Orta':
        return const Color(0xFFF59E0B);
      case 'Düşük':
      default:
        return const Color(0xFF16A34A);
    }
  }

  void _deleteEvent(Map<String, dynamic> event) {
    setState(() => _events.remove(event));
  }

  void _showAddEventDialog({DateTime? preselectedDate}) {
    final titleController = TextEditingController();
    DateTime selectedDate = preselectedDate ?? DateTime.now();
    String selectedPriority = 'Düşük';
    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Yeni Etkinlik Ekle",
                style: TextStyle(color: c.textPrimary, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Etkinlik başlığı...",
                      hintStyle: TextStyle(color: c.textHint),
                      filled: true,
                      fillColor: c.inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        builder: (ctx2, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF6366F1),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.inputBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: c.textSecondary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: TextStyle(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _priorityLevels.map((p) {
                      final isSelected = selectedPriority == p;
                      final color = _getPriorityColor(p);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedPriority = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.25)
                                  : c.inputBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : c.cardBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: isSelected ? color : c.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("İptal", style: TextStyle(color: c.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _events.add({
                          'date': selectedDate,
                          'title': titleController.text.trim(),
                          'priority': selectedPriority,
                        });
                      });
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Ekle", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: c.bgGradient,
          ),
        ),
        child: SafeArea(
          child: _currentNavIndex == 0
              ? _buildHomeContent(c)
              : _currentNavIndex == 4
                  ? const ProfilePage()
                  : _buildPlaceholderPage(_getNavLabel(_currentNavIndex), c),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(c),
    );
  }

  Widget _buildHomeContent(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingSection(c),
          const SizedBox(height: 20),
          _buildSearchBar(c),
          const SizedBox(height: 24),
          _buildStatCards(c),
          const SizedBox(height: 28),
          _buildEventsSection(c),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Merhaba $_userName, 👋",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Bugünün Özeti",
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined, color: c.textPrimary, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder, width: 1),
      ),
      child: TextField(
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: "E-Posta, Arşiv, Rehber'de Ara...",
          hintStyle: TextStyle(color: c.textHint, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: c.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatCards(AppColors c) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.mail_outlined,
                count: _bekleyenMail,
                label: "Bekleyen Mail",
                color: const Color(0xFF16A34A),
                c: c,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment_outlined,
                count: _onayBekleyenIs,
                label: "Onay Bekleyen İş",
                color: const Color(0xFFEA580C),
                c: c,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.business_outlined,
                count: _kayitliSirket,
                label: "Kayıtlı Şirket",
                color: const Color(0xFF2563EB),
                c: c,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time,
                count: _hatirlatici,
                label: "Hatırlatıcı",
                color: const Color(0xFF7C3AED),
                c: c,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Önemli Etkinlikler",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: c.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "Takvim"),
              Tab(text: "Liste"),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCalendarView(c),
              _buildListView(c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView(AppColors c) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCalendarGrid(c),
          const SizedBox(height: 16),
          ..._buildEventCards(c),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(AppColors c) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final eventDays = _events
        .where((e) => (e['date'] as DateTime).month == month && (e['date'] as DateTime).year == year)
        .map((e) => (e['date'] as DateTime).day)
        .toSet();

    final dayHeaders = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final monthNames = [
      '', 'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
      'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK',
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: c.textSecondary),
              onPressed: () => setState(() => _focusedMonth = DateTime(year, month - 1)),
            ),
            Text(
              "${monthNames[month]} $year",
              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: c.textSecondary),
              onPressed: () => setState(() => _focusedMonth = DateTime(year, month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders.map((d) => SizedBox(
            width: 36,
            child: Center(
              child: Text(
                d,
                style: TextStyle(color: c.textHint, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(_getWeekCount(year, month), (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - (firstDayWeekday - 2);
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 36, height: 36);
                }
                final isToday = DateTime(year, month, dayNumber) == today;
                final hasEvent = eventDays.contains(dayNumber);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = DateTime(year, month, dayNumber));
                    _showAddEventDialog(preselectedDate: DateTime(year, month, dayNumber));
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFFEA580C) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: isToday ? Colors.white : c.textSecondary,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (hasEvent && !isToday)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  int _getWeekCount(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    return ((daysInMonth + firstDayWeekday - 1) / 7).ceil();
  }

  List<Widget> _buildEventCards(AppColors c) {
    final sortedEvents = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return sortedEvents.map((event) {
      return _EventCardItem(
        event: event,
        isListView: false,
        onDelete: () => _deleteEvent(event),
        onPriorityChanged: (newPriority) => setState(() => event['priority'] = newPriority),
      );
    }).toList();
  }

  Widget _buildListView(AppColors c) {
    final sortedEvents = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 60),
          itemCount: sortedEvents.length,
          itemBuilder: (context, index) {
            final event = sortedEvents[index];
            return _EventCardItem(
              event: event,
              isListView: true,
              onDelete: () => _deleteEvent(event),
              onPriorityChanged: (newPriority) => setState(() => event['priority'] = newPriority),
            );
          },
        ),
        Positioned(
          right: 4,
          bottom: 8,
          child: _AddEventFAB(onPressed: () => _showAddEventDialog()),
        ),
      ],
    );
  }

  Widget _buildPlaceholderPage(String title, AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: c.textHint),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            "Bu sayfa yakında aktif olacak",
            style: TextStyle(fontSize: 14, color: c.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(top: BorderSide(color: c.navBorder, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, "HOME", c),
              _buildNavItem(1, Icons.mail_outlined, Icons.mail, "GELENLER", c),
              _buildCenterNavButton(),
              _buildNavItem(3, Icons.archive_outlined, Icons.archive, "ARŞİV", c),
              _buildNavItem(4, Icons.person_outline, Icons.person, "PROFİL", c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, AppColors c) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? const Color(0xFF6366F1) : c.iconTertiary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? const Color(0xFF6366F1) : c.iconTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 26),
      ),
    );
  }

  String _getNavLabel(int index) {
    switch (index) {
      case 1: return "GELENLER";
      case 3: return "ARŞİV";
      case 4: return "PROFİL";
      default: return "";
    }
  }
}

class _EventCardItem extends StatefulWidget {
  final Map<String, dynamic> event;
  final bool isListView;
  final VoidCallback onDelete;
  final ValueChanged<String> onPriorityChanged;

  const _EventCardItem({
    required this.event,
    required this.isListView,
    required this.onDelete,
    required this.onPriorityChanged,
  });

  @override
  State<_EventCardItem> createState() => _EventCardItemState();
}

class _EventCardItemState extends State<_EventCardItem>
    with SingleTickerProviderStateMixin {
  bool _showDeleteConfirm = false;
  bool _showPriorityMenu = false;
  late AnimationController _deleteAnimController;
  late Animation<double> _deleteSlideAnimation;
  late Animation<double> _deleteFadeAnimation;

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Acil':
        return const Color(0xFFEF4444);
      case 'Orta':
        return const Color(0xFFF59E0B);
      case 'Düşük':
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  void initState() {
    super.initState();
    _deleteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _deleteSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _deleteAnimController, curve: Curves.easeOutCubic),
    );
    _deleteFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _deleteAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _deleteAnimController.dispose();
    super.dispose();
  }

  void _toggleDeleteConfirm(bool show) {
    setState(() => _showDeleteConfirm = show);
    if (show) {
      _deleteAnimController.forward(from: 0);
    } else {
      _deleteAnimController.reverse();
    }
  }


  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final date = widget.event['date'] as DateTime;
    final priority = widget.event['priority'] as String;
    final priorityColor = _getPriorityColor(priority);
    final monthNames = [
      '', 'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
      'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK',
    ];

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _toggleDeleteConfirm(true);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _showDeleteConfirm
              ? (c.isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFF0F0))
              : c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showDeleteConfirm
                ? Colors.red.withValues(alpha: 0.5)
                : c.cardBorder,
            width: _showDeleteConfirm ? 1.5 : 1.0,
          ),
          boxShadow: _showDeleteConfirm
              ? [BoxShadow(color: Colors.red.withValues(alpha: 0.15), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            if (widget.isListView)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: priorityColor),
                    child: Text(date.day.toString()),
                  ),
                ),
              )
            else ...[
              Column(
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c.textPrimary),
                  ),
                  Text(
                    monthNames[date.month],
                    style: TextStyle(fontSize: 10, color: c.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 40, color: c.divider),
            ],
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isListView) ...[
                    Text(
                      "${date.day} ${monthNames[date.month]}",
                      style: TextStyle(fontSize: 11, color: c.textHint),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.event['title'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                  ),
                  if (widget.isListView) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${date.day} ${monthNames[date.month][0]}${monthNames[date.month].substring(1).toLowerCase()} ${date.year}",
                      style: TextStyle(fontSize: 12, color: c.textHint),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _showDeleteConfirm
                    ? _buildDeleteConfirmPanel()
                    : _buildPriorityAndDeleteRow(priority, priorityColor, c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmPanel() {
    return AnimatedBuilder(
      key: const ValueKey('delete_confirm'),
      animation: _deleteAnimController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_deleteSlideAnimation.value, 0),
          child: Opacity(
            opacity: _deleteFadeAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Silinsin mi?",
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 6),
          _buildAnimatedIconButton(
            icon: Icons.check_circle_rounded,
            color: Colors.redAccent,
            onPressed: widget.onDelete,
            tooltip: 'Sil',
          ),
          const SizedBox(width: 4),
          _buildAnimatedIconButton(
            icon: Icons.cancel_rounded,
            color: Colors.white54,
            onPressed: () => _toggleDeleteConfirm(false),
            tooltip: 'İptal',
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildPriorityAndDeleteRow(String priority, Color priorityColor, AppColors c) {
    const priorities = ['Düşük', 'Orta', 'Acil'];

    Future<void> openMenu(BuildContext chipCtx) async {
      final box = chipCtx.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      final screen = MediaQuery.of(chipCtx).size;

      setState(() => _showPriorityMenu = true);

      final selected = await showMenu<String>(
        context: chipCtx,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height + 4,
          screen.width - offset.dx - size.width,
          screen.height - offset.dy - size.height - 4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: c.card,
        elevation: c.isDark ? 8 : 3,
        constraints: const BoxConstraints(minWidth: 140),
        items: priorities.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final pc = _getPriorityColor(p);
          final isSelected = priority == p;
          return PopupMenuItem<String>(
            value: p,
            padding: EdgeInsets.zero,
            height: 44,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: isSelected ? pc.withValues(alpha: 0.1) : Colors.transparent,
                border: i < priorities.length - 1
                    ? Border(bottom: BorderSide(color: c.divider, width: 0.5))
                    : null,
              ),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: pc, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: pc.withValues(alpha: 0.4), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 10),
                Text(p, style: TextStyle(
                  color: isSelected ? pc : c.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                )),
                const Spacer(),
                if (isSelected) Icon(Icons.check_rounded, color: pc, size: 16),
              ]),
            ),
          );
        }).toList(),
      );

      if (!mounted) return;
      setState(() => _showPriorityMenu = false);
      if (selected != null) widget.onPriorityChanged(selected);
    }

    return Row(
      key: const ValueKey('priority_row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(builder: (chipCtx) => GestureDetector(
          onTap: () => openMenu(chipCtx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _showPriorityMenu
                    ? priorityColor.withValues(alpha: 0.7)
                    : priorityColor.withValues(alpha: 0.4),
                width: _showPriorityMenu ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    priority,
                    key: ValueKey(priority),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: priorityColor),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _showPriorityMenu ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Icon(Icons.keyboard_arrow_down, color: priorityColor, size: 14),
                ),
              ],
            ),
          ),
        )),
        const SizedBox(width: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleDeleteConfirm(true),
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.red.withValues(alpha: 0.15),
            highlightColor: Colors.red.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, color: c.textSecondary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddEventFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const _AddEventFAB({required this.onPressed});

  @override
  State<_AddEventFAB> createState() => _AddEventFABState();
}

class _AddEventFABState extends State<_AddEventFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
