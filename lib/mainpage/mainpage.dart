import 'package:flutter/material.dart';

/// Ana sayfa — Giriş yapıldıktan sonra gösterilen ekran.
/// Selamlama, arama, istatistik kartları, takvim ve bottom nav bar içerir.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  // Alt navigasyon barında hangi sekmenin aktif olduğunu takip eder
  int _currentNavIndex = 0;

  // Takvim/Liste sekmeleri için tab controller
  late TabController _tabController;

  // Takvimde seçili gün — ileride backend filtreleme için kullanılacak
  // ignore: unused_field
  DateTime _selectedDate = DateTime.now();

  // Takvimde gösterilen ay
  DateTime _focusedMonth = DateTime.now();

  // Sabit demo verileri — ileride backend'den gelecek
  final String _userName = "Sadıkcan";
  final int _bekleyenMail = 14;
  final int _onayBekleyenIs = 6;
  final int _kayitliSirket = 101;
  final int _hatirlatici = 5;

  // Etkinlik listesi — ileride backend'den gelecek, şimdilik lokal state
  final List<Map<String, dynamic>> _events = [
    {
      'date': DateTime(2026, 5, 10),
      'title': 'Önemli Müşteri Toplantısı',
      'priority': 'Acil',
    },
    {
      'date': DateTime(2026, 5, 26),
      'title': 'Proje Değerlendirme',
      'priority': 'Düşük',
    },
    {
      'date': DateTime(2026, 5, 15),
      'title': 'Sprint Planlama',
      'priority': 'Orta',
    },
    {
      'date': DateTime(2026, 5, 20),
      'title': 'Ekip Toplantısı',
      'priority': 'Düşük',
    },
  ];

  // 3 öncelik seviyesi: Düşük (yeşil), Orta (sarı), Acil (kırmızı)
  static const List<String> _priorityLevels = ['Düşük', 'Orta', 'Acil'];

  /// Öncelik seviyesine göre renk döndürür
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Acil':
        return const Color(0xFFEF4444); // Kırmızı
      case 'Orta':
        return const Color(0xFFF59E0B); // Sarı/Amber
      case 'Düşük':
      default:
        return const Color(0xFF16A34A); // Yeşil
    }
  }

  /// Etkinliği listeden siler
  void _deleteEvent(Map<String, dynamic> event) {
    setState(() {
      _events.remove(event);
    });
  }

  /// Yeni etkinlik ekleme dialog'unu gösterir
  void _showAddEventDialog({DateTime? preselectedDate}) {
    final titleController = TextEditingController();
    DateTime selectedDate = preselectedDate ?? DateTime.now();
    String selectedPriority = 'Düşük';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Yeni Etkinlik Ekle",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık input
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Etkinlik başlığı...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarih seçici
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
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
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Öncelik seçici — 3 buton yan yana
                  Row(
                    children: _priorityLevels.map((p) {
                      final isSelected = selectedPriority == p;
                      final color = _getPriorityColor(p);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedPriority = p;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.25)
                                  : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : Colors.white12,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: isSelected ? color : Colors.white54,
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
                // İptal butonu
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "İptal",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                // Ekle butonu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                  child: const Text(
                    "Ekle",
                    style: TextStyle(color: Colors.white),
                  ),
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
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Tab değiştiğinde + ikonunu gizle/göster
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: _currentNavIndex == 0
              ? _buildHomeContent()
              : _buildPlaceholderPage(_getNavLabel(_currentNavIndex)),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ─── Ana Sayfa İçeriği ───
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingSection(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 28),
          _buildEventsSection(),
        ],
      ),
    );
  }

  // ─── 1. Selamlama Alanı ───
  Widget _buildGreetingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Merhaba $_userName, 👋",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Bugünün Özeti",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        // Bildirim ikonu
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Bildirimler sayfası
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2. Arama Çubuğu ───
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "E-Posta, Arşiv, Rehber'de Ara...",
          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── 3. İstatistik Kartları ───
  Widget _buildStatCards() {
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment_outlined,
                count: _onayBekleyenIs,
                label: "Onay Bekleyen İş",
                color: const Color(0xFFEA580C),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time,
                count: _hatirlatici,
                label: "Hatırlatıcı",
                color: const Color(0xFF7C3AED),
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Önemli Etkinlikler ───
  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Önemli Etkinlikler",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_tabController.index == 1)
              IconButton(
                onPressed: () => _showAddEventDialog(),
                icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1)),
              )
            else
              const SizedBox(height: 48), // Layout kaymaması için
          ],
        ),
        const SizedBox(height: 12),
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
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
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "Takvim"),
              Tab(text: "Liste"),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tab İçerikleri
        SizedBox(
          // Takvim + etkinlik kartları için yeterli yükseklik
          height: 420,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCalendarView(),
              _buildListView(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Takvim Görünümü ───
  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          ..._buildEventCards(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Pazartesi = 1, Pazar = 7
    final firstDayWeekday = DateTime(year, month, 1).weekday;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Etkinlik olan günleri bul
    final eventDays = _events
        .where((e) => (e['date'] as DateTime).month == month && (e['date'] as DateTime).year == year)
        .map((e) => (e['date'] as DateTime).day)
        .toSet();

    final dayHeaders = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    // Ayın Türkçe adı
    final monthNames = [
      '', 'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
      'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK',
    ];

    return Column(
      children: [
        // Ay başlığı ve navigasyon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white54),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(year, month - 1);
                });
              },
            ),
            Text(
              "${monthNames[month]} $year",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white54),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(year, month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Gün başlıkları
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders.map((d) => SizedBox(
            width: 36,
            child: Center(
              child: Text(
                d,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // Takvim günleri
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
                    setState(() {
                      _selectedDate = DateTime(year, month, dayNumber);
                    });
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
                            color: isToday ? Colors.white : Colors.white70,
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

  List<Widget> _buildEventCards() {
    final sortedEvents = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return sortedEvents.map((event) {
      final date = event['date'] as DateTime;
      final priority = event['priority'] as String;
      final priorityColor = _getPriorityColor(priority);
      final monthNames = [
        '', 'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
        'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK',
      ];

      return _EventCardItem(
        event: event,
        isListView: false,
        onDelete: () => _deleteEvent(event),
        onPriorityChanged: (newPriority) {
          setState(() {
            event['priority'] = newPriority;
          });
        },
      );
    }).toList();
  }

  // ─── Liste Görünümü ───
  Widget _buildListView() {
    final sortedEvents = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final monthNames = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final date = event['date'] as DateTime;
        final priority = event['priority'] as String;
        final priorityColor = _getPriorityColor(priority);

        return _EventCardItem(
          event: event,
          isListView: true,
          onDelete: () => _deleteEvent(event),
          onPriorityChanged: (newPriority) {
            setState(() {
              event['priority'] = newPriority;
            });
          },
        );
      },
    );
  }

  // ─── Placeholder Sayfa (diğer sekmeler için) ───
  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Bu sayfa yakında aktif olacak",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. Bottom Navigation Bar ───
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, "HOME"),
              _buildNavItem(1, Icons.mail_outlined, Icons.mail, "GELENLER"),
              // Ortadaki özel buton
              _buildCenterNavButton(),
              _buildNavItem(3, Icons.archive_outlined, Icons.archive, "ARŞİV"),
              _buildNavItem(4, Icons.person_outline, Icons.person, "PROFİL"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? const Color(0xFF6366F1) : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? const Color(0xFF6366F1) : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Merkez buton aksiyonu
      },
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
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  String _getNavLabel(int index) {
    switch (index) {
      case 0: return "HOME";
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

class _EventCardItemState extends State<_EventCardItem> {
  bool _showDeleteConfirm = false;

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
  Widget build(BuildContext context) {
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
        setState(() => _showDeleteConfirm = true);
        return false; // let the inline UI handle it
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showDeleteConfirm ? Colors.red.withValues(alpha: 0.5) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            // Sol Tarih Kısmı
            if (widget.isListView)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              )
            else ...[
              Column(
                children: [
                  Text(
                    date.day.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    monthNames[date.month],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 40, color: Colors.white12),
            ],

            const SizedBox(width: 14),

            // Orta İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isListView) ...[
                    Text(
                      "${date.day} ${monthNames[date.month]}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.event['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.isListView) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${date.day} ${monthNames[date.month][0]}${monthNames[date.month].substring(1).toLowerCase()} ${date.year}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Sağ Taraf: Öncelik ve Silme
            if (_showDeleteConfirm)
              Row(
                children: [
                  const Text("Silinsin mi?", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.redAccent, size: 24),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white54, size: 24),
                    onPressed: () => setState(() => _showDeleteConfirm = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: widget.onPriorityChanged,
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    offset: const Offset(0, 30),
                    itemBuilder: (context) => ['Düşük', 'Orta', 'Acil'].map((p) {
                      final c = _getPriorityColor(p);
                      return PopupMenuItem<String>(
                        value: p,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: c, size: 12),
                            const SizedBox(width: 8),
                            Text(p, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            priority,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: priorityColor, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                    onPressed: () => setState(() => _showDeleteConfirm = true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

