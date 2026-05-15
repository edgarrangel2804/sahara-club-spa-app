import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/user_profile.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';
import 'package:sahara_club_spa_app/features/admin/widgets/kpi_card.dart';
import 'package:sahara_club_spa_app/features/admin/widgets/revenue_chart.dart';
import 'package:sahara_club_spa_app/features/admin/widgets/agenda_widget.dart';
import 'package:sahara_club_spa_app/features/admin/widgets/terapeutas_widget.dart';
import 'package:sahara_club_spa_app/features/admin/widgets/clientes_widget.dart';
import 'package:sahara_club_spa_app/features/admin/widgets/alerts_widget.dart';
import 'package:sahara_club_spa_app/features/admin/pages/agenda_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/clientes_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/finances_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/admin_config_screen.dart';
import 'package:sahara_club_spa_app/features/admin/pages/terapeutas_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/admin_messages_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _repo = SaharaAdminRepository();
  int _selectedIndex = 0;
  bool _isLoading = true;

  Map<String, double> _financials = {};
  Map<String, dynamic> _operational = {};
  List<Map<String, dynamic>> _agenda = [];
  List<Map<String, dynamic>> _terapeutas = [];
  List<double> _chartValues = [];
  List<String> _chartLabels = [];

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _refreshData();
  }

  Future<void> _loadProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      if (mounted) setState(() => _profile = UserProfile.fromMap(data));
    } catch (e) {
      debugPrint('AdminDashboard._loadProfile: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getFinancialStats(),
        _repo.getOperationalStats(),
        _repo.getTodayAgenda(),
        _repo.getTerapeutasPerformance(),
        _repo.getRevenueChartData(),
      ]);

      setState(() {
        _financials = results[0] as Map<String, double>;
        _operational = results[1] as Map<String, dynamic>;
        _agenda = results[2] as List<Map<String, dynamic>>;
        _terapeutas = results[3] as List<Map<String, dynamic>>;
        final chart = results[4] as Map<String, dynamic>;
        _chartValues = chart['values'] as List<double>;
        _chartLabels = chart['labels'] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminDashboard._refreshData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      const AdminAgendaPage(),
      const AdminClientesPage(),
      const AdminFinancesPage(),
      AdminMessagesPage(repo: _repo),
      const AdminConfigScreen(),
    ];

    return Scaffold(
      backgroundColor: SaharaColors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: SaharaColors.black,
            border: Border(bottom: BorderSide(color: SaharaColors.grayDark.withValues(alpha: 0.6))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (_selectedIndex == 0)
                    Row(
                      children: [
                        const Icon(Icons.spa_outlined, color: SaharaColors.gold, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Sahara Club',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            color: SaharaColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      ['', 'Agenda', 'Usuarios', 'Finanzas', 'Mensajes', 'Configuración'][_selectedIndex],
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        color: SaharaColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Spacer(),
                  if (_selectedIndex == 0)
                    GestureDetector(
                      onTap: _refreshData,
                      child: const Icon(Icons.refresh_rounded, color: SaharaColors.grayText, size: 22),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: SaharaColors.black,
        border: Border(top: BorderSide(color: SaharaColors.grayDark.withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Panel'),
              _navItem(1, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Agenda'),
              _navItem(2, Icons.people_outline_rounded, Icons.people_rounded, 'Usuarios'),
              _navItem(3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Finanzas'),
              _navItem(4, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Mensajes'),
              _navItem(5, Icons.settings_outlined, Icons.settings_rounded, 'Config'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? SaharaColors.gold : SaharaColors.grayText,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? SaharaColors.gold : SaharaColors.grayText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final fmt = NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: 0);
    final userName = _profile?.fullName ??
        AuthService().currentUser?.userMetadata?['full_name'] as String? ??
        'Administrador';

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: SaharaColors.gold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'BIENVENIDO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SaharaColors.grayText,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hola, ${userName.split(' ')[0]}',
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                color: SaharaColors.whiteSoft,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 28),

            // Quick nav carousel
            _buildQuickNav(),
            const SizedBox(height: 28),

            // KPIs
            _buildKpis(fmt),
            const SizedBox(height: 20),

            // Chart
            Text(
              'RENDIMIENTO DE INGRESOS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SaharaColors.grayText,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            AdminRevenueChart(
              data: _chartValues.isEmpty ? List.filled(7, 0.0) : _chartValues,
              labels: _chartLabels.isEmpty ? ['D', 'L', 'M', 'X', 'J', 'V', 'S'] : _chartLabels,
            ),
            const SizedBox(height: 20),

            // Agenda
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: AdminAgendaWidget(appointments: _agenda),
            ),
            const SizedBox(height: 20),

            // Terapeutas
            GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminTerapeutasPage())),
              child: TerapeutasWidget(terapeutas: _terapeutas),
            ),
            const SizedBox(height: 20),

            // Clientes
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 2),
              child: ClientesWidget(
                stats: {
                  'new': _operational['new_clients_month'] as int? ?? 0,
                  'returning': _operational['returning_clients'] as int? ?? 0,
                  'inactive': _operational['inactive_clients'] as int? ?? 0,
                },
              ),
            ),
            const SizedBox(height: 20),

            // Alerts
            AdminAlertsWidget(
              alerts: [
                if ((_operational['cancelled_today'] as int? ?? 0) > 0)
                  '${_operational['cancelled_today']} citas canceladas hoy.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNav() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _navCard('Terapeutas', Icons.self_improvement_rounded, SaharaColors.gold,
              () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminTerapeutasPage()))),
          _navCard('Agenda', Icons.calendar_today_outlined, const Color(0xFF8B5CF6),
              () => setState(() => _selectedIndex = 1)),
          _navCard('Finanzas', Icons.bar_chart_rounded, const Color(0xFF10B981),
              () => setState(() => _selectedIndex = 3)),
        ],
      ),
    );
  }

  Widget _navCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: SaharaGradients.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SaharaColors.grayDark),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SaharaColors.whiteSoft,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis(NumberFormat fmt) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: AdminKpiCard(
                  title: 'Ingresos Hoy',
                  value: fmt.format(_financials['revenue_today'] ?? 0),
                  icon: Icons.bolt_rounded,
                  accentColor: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: AdminKpiCard(
                  title: 'Ingresos Semana',
                  value: fmt.format(_financials['revenue_week'] ?? 0),
                  icon: Icons.calendar_today_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: AdminKpiCard(
                  title: 'Ingresos Mes',
                  value: fmt.format(_financials['revenue_month'] ?? 0),
                  icon: Icons.analytics_rounded,
                  accentColor: SaharaColors.gold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminKpiCard(
                title: 'Clientes',
                value: '${_operational['clients_count'] ?? 0}',
                icon: Icons.people_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
