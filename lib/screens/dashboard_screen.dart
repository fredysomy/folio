import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/portfolio_provider.dart';
import '../models/holding.dart';
import '../models/stock_holding.dart';
import '../services/background_service.dart';
import '../services/battery_optimization_service.dart';
import '../services/stock_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeTab(),
      const MutualFundsTab(),
      const StocksTab(),
      const ImportTab(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Mutual Funds',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Stocks',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Import',
          ),
        ],
      ),
    );
  }
}

// ─── HOME TAB ──────────────────────────────────────────────────────────────────

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
        final isProfit = provider.totalProfitLoss >= 0;
        final pnlColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Folio'),
            actions: [
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync all (cached)',
                  onPressed: () => provider.syncNavs(),
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: provider.syncNavs,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Portfolio Value Card ──────────────────────────────
                      Card(
                        elevation: 0,
                        color: colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Portfolio Value',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fmt.format(provider.currentNetWorth),
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    isProfit
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: pnlColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${fmt.format(provider.totalProfitLoss.abs())}  '
                                    '(${provider.totalProfitLossPercentage.toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      color: pnlColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Day Movement Card ──────────────────────────────
                      if (provider.lastNetWorthRecord != null)
                        Card(
                          elevation: 0,
                          color: colorScheme.secondaryContainer.withOpacity(
                            0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        (provider.dayChange >= 0
                                                ? Colors.green
                                                : Colors.red)
                                            .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    provider.dayChange >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: provider.dayChange >= 0
                                        ? Colors.green.shade400
                                        : Colors.red.shade400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Day Movement (as of ${DateFormat('dd MMM, hh:mm a').format(DateTime.parse(provider.lastNetWorthRecord!['date']))})',
                                      style: TextStyle(
                                        color: colorScheme.onSecondaryContainer
                                            .withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${provider.dayChange >= 0 ? '+' : ''}${fmt.format(provider.dayChange)} (${provider.dayChangePercentage.toStringAsFixed(2)}%)',
                                      style: TextStyle(
                                        color: provider.dayChange >= 0
                                            ? Colors.green.shade400
                                            : Colors.red.shade400,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Total Invested vs Current ─────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: 'Total Invested',
                              value: fmt.format(provider.totalInvested),
                              icon: Icons.savings_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryTile(
                              label: 'Total Current',
                              value: fmt.format(provider.currentNetWorth),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Section Breakdown ─────────────────────────────────
                      const _SectionHeader(title: 'Breakdown'),
                      Row(
                        children: [
                          Expanded(
                            child: _BreakdownCard(
                              label: 'Mutual Funds',
                              icon: Icons.show_chart,
                              invested: provider.mfInvested,
                              current: provider.mfCurrentValue,
                              count: provider.holdings.length,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BreakdownCard(
                              label: 'Stocks',
                              icon: Icons.candlestick_chart_outlined,
                              invested: provider.stockInvested,
                              current: provider.stockCurrentValue,
                              count: provider.stockHoldings.length,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Recent MF Holdings ────────────────────────────────
                      if (provider.holdings.isNotEmpty) ...[
                        const _SectionHeader(title: 'Recent Mutual Funds'),
                        ...provider.holdings
                            .take(3)
                            .map((h) => _HoldingTile(holding: h)),
                      ],
                      if (provider.stockHoldings.isNotEmpty) ...[
                        const _SectionHeader(title: 'Recent Stocks'),
                        ...provider.stockHoldings
                            .take(3)
                            .map((s) => _StockTile(stock: s)),
                      ],
                      if (provider.holdings.isEmpty &&
                          provider.stockHoldings.isEmpty)
                        const _EmptyState(
                          message:
                              'No holdings yet.\nImport an Excel file to get started.',
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ─── MUTUAL FUNDS TAB ──────────────────────────────────────────────────────────

class MutualFundsTab extends StatelessWidget {
  const MutualFundsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mutual Funds'),
            actions: [
              if (!provider.isLoading) ...[
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync NAVs (cached — skip today\'s fetches)',
                  onPressed: () => provider.syncNavs(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Force refresh all NAVs',
                  onPressed: () => provider.syncNavs(forceRefresh: true),
                ),
              ],
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.holdings.isEmpty
              ? const _EmptyState(
                  message:
                      'No mutual fund holdings.\nGo to Import tab to add data.',
                )
              : Column(
                  children: [
                    // Summary bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invested',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              Text(
                                fmt.format(provider.mfInvested),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Current Value',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              Text(
                                fmt.format(provider.mfCurrentValue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'P&L',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              Builder(
                                builder: (ctx) {
                                  final pnl =
                                      provider.mfCurrentValue -
                                      provider.mfInvested;
                                  return Text(
                                    '${pnl >= 0 ? '+' : ''}${fmt.format(pnl)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pnl >= 0
                                          ? Colors.green.shade400
                                          : Colors.red.shade400,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: provider.holdings.length,
                        itemBuilder: (context, i) =>
                            _HoldingTile(holding: provider.holdings[i]),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─── STOCKS TAB ────────────────────────────────────────────────────────────────

class StocksTab extends StatelessWidget {
  const StocksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Stocks'),
            actions: [
              if (!provider.isLoading) ...[
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync (cached — skip today\'s fetches)',
                  onPressed: () => provider.syncStockPrices(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Force refresh all prices',
                  onPressed: () => provider.syncStockPrices(forceRefresh: true),
                ),
              ],
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.stockHoldings.isEmpty
              ? const _EmptyState(
                  icon: Icons.candlestick_chart_outlined,
                  message: 'No stock holdings.\nGo to Import tab to add data.',
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invested',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              Text(
                                fmt.format(provider.stockInvested),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Current Value',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              Text(
                                fmt.format(provider.stockCurrentValue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'P&L',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              Builder(
                                builder: (ctx) {
                                  final pnl =
                                      provider.stockCurrentValue -
                                      provider.stockInvested;
                                  return Text(
                                    '${pnl >= 0 ? '+' : ''}${fmt.format(pnl)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pnl >= 0
                                          ? Colors.green.shade400
                                          : Colors.red.shade400,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: provider.stockHoldings.length,
                        itemBuilder: (context, i) =>
                            _StockTile(stock: provider.stockHoldings[i]),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─── IMPORT TAB ────────────────────────────────────────────────────────────────

class ImportTab extends StatefulWidget {
  const ImportTab({super.key});

  @override
  State<ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<ImportTab> {
  final _newKeyController = TextEditingController();
  bool _newKeyObscured = true;
  List<String> _apiKeys = [];
  final _stockApiService = StockApiService();
  final _batteryService = BatteryOptimizationService();
  TimeOfDay? _reminderTime;
  bool _reminderLoading = false;
  bool? _batteryOptDisabled;
  bool _batteryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
    _loadReminderTime();
    _checkBatteryOptimization();
  }

  Future<void> _loadApiKeys() async {
    final keys = await _stockApiService.getApiKeys();
    if (mounted) setState(() => _apiKeys = keys);
  }

  Future<void> _addKey() async {
    final key = _newKeyController.text.trim();
    if (key.isEmpty) return;
    await _stockApiService.addApiKey(key);
    _newKeyController.clear();
    await _loadApiKeys();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeKey(String key) async {
    await _stockApiService.removeApiKey(key);
    await _loadApiKeys();
  }

  Future<void> _checkBatteryOptimization() async {
    final status = await _batteryService.isIgnoringOptimizations();
    if (mounted) setState(() => _batteryOptDisabled = status);
  }

  Future<void> _requestBatteryOptimization() async {
    setState(() => _batteryLoading = true);
    await _batteryService.requestIgnoreOptimizations();
    await Future.delayed(const Duration(milliseconds: 600));
    await _checkBatteryOptimization();
    if (mounted) {
      setState(() => _batteryLoading = false);
      if (_batteryOptDisabled == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Battery optimisation disabled for Folio'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadReminderTime() async {
    final time = await BackgroundService().getScheduledTime();
    if (mounted) setState(() => _reminderTime = time);
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime ?? const TimeOfDay(hour: 21, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Choose reminder time',
    );
    if (picked != null) {
      setState(() => _reminderLoading = true);
      try {
        await BackgroundService().updateSchedule(picked);
        if (!mounted) return;
        setState(() => _reminderTime = picked);
        final formatted = picked.format(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily summary set for $formatted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _reminderLoading = false);
        }
      }
    }
  }


  String _obscureKey(String key) {
    if (key.length <= 12) return '••••••••';
    return '${key.substring(0, 8)}••••${key.substring(key.length - 4)}';
  }

  Future<void> _pickMF() async {
    final provider = context.read<PortfolioProvider>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      await provider.importExcel(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mutual Funds imported'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickStocks() async {
    final keys = await _stockApiService.getApiKeys();
    if (keys.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please save your Stock API key first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final provider = context.read<PortfolioProvider>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      await provider.importStockExcel(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stocks imported'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _newKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Import Data')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Stock API Keys ────────────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.key_outlined, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stock API Keys',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${_apiKeys.length} key${_apiKeys.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add multiple keys to rotate (500 req/month each). Keys are used round-robin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Existing keys list
                      if (_apiKeys.isNotEmpty) ...[
                        ..._apiKeys.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${e.key + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _obscureKey(e.value),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  color: colorScheme.error,
                                  onPressed: () => _removeKey(e.value),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                      ],
                      // Add new key
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newKeyController,
                              obscureText: _newKeyObscured,
                              decoration: InputDecoration(
                                hintText: 'sk-live-...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _newKeyObscured
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                    () => _newKeyObscured = !_newKeyObscured,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _addKey,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Daily Summary Notification ──────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Daily Summary Notification',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Receive a Workmanager-based alert with mutual fund and stock moves at your preferred time.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _reminderTime == null
                                      ? 'Loading schedule…'
                                      : 'Scheduled for ${_reminderTime!.format(context)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Updates run once a day and post a notification with the movement breakdown.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: _reminderLoading
                                ? null
                                : _pickReminderTime,
                            child: _reminderLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Set Time'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Battery Optimisation ───────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.battery_saver, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Battery Optimisation',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Disable Android’s battery optimisation for Folio so daily refreshes run even when the phone is sleeping.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            _batteryOptDisabled == true
                                ? Icons.verified_outlined
                                : Icons.warning_amber_outlined,
                            color: _batteryOptDisabled == true
                                ? Colors.green.shade500
                                : Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _batteryOptDisabled == true
                                  ? 'Already allowed – tasks can run freely'
                                  : 'Recommended: allow Folio to bypass optimisation',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonal(
                            onPressed:
                                _batteryOptDisabled == true || _batteryLoading
                                ? null
                                : _requestBatteryOptimization,
                            child: _batteryLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _batteryOptDisabled == true
                                        ? 'Allowed'
                                        : 'Allow',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Import Mutual Funds ───────────────────────────────────────
              _ImportCard(
                icon: Icons.show_chart,
                title: 'Import Mutual Funds',
                description:
                    'Upload your CAS statement or MF holdings report (.xlsx)',
                buttonLabel: 'Choose MF Excel File',
                onTap: provider.isLoading ? null : _pickMF,
                isLoading: provider.isLoading,
              ),
              const SizedBox(height: 12),

              // ── Import Stocks ─────────────────────────────────────────────
              _ImportCard(
                icon: Icons.candlestick_chart_outlined,
                title: 'Import Stocks',
                description:
                    'Upload your broker stock holdings report (.xlsx). Live prices fetched via API.',
                buttonLabel: 'Choose Stock Excel File',
                onTap: provider.isLoading ? null : _pickStocks,
                isLoading: provider.isLoading,
              ),
              const SizedBox(height: 16),

              // ── Instructions ─────────────────────────────────────────────
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock file format',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The Excel file should have columns for:',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      const _Bullet(text: 'Instrument / Stock / Company Name'),
                      const _Bullet(text: 'Quantity / Qty'),
                      const _Bullet(
                        text: 'Avg Cost / Average Price / Buy Price',
                      ),
                      const _Bullet(text: 'ISIN (optional)'),
                      const SizedBox(height: 8),
                      Text(
                        'Compatible with Zerodha Console, Groww, CDSL/NSDL reports.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ImportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isLoading ? 'Importing…' : buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double invested;
  final double current;
  final int count;

  const _BreakdownCard({
    required this.label,
    required this.icon,
    required this.invested,
    required this.current,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final colorScheme = Theme.of(context).colorScheme;
    final pnl = current - invested;
    final isProfit = pnl >= 0;
    final pnlColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;
    final pct = invested == 0 ? 0.0 : (pnl / invested) * 100;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              fmt.format(current),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              '${isProfit ? '+' : ''}${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: pnlColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Invested: ${fmt.format(invested)}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  final Holding holding;
  const _HoldingTile({required this.holding});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isProfit = holding.profitLoss >= 0;
    final pnlColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holding.schemeName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniStat(
                  label: 'Invested',
                  value: fmt.format(holding.investedValue),
                ),
                const SizedBox(width: 16),
                _MiniStat(
                  label: 'Current',
                  value: fmt.format(holding.currentValue),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isProfit ? '+' : ''}${fmt.format(holding.profitLoss)}',
                      style: TextStyle(
                        color: pnlColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${holding.profitLossPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(color: pnlColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final StockHolding stock;
  const _StockTile({required this.stock});

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(
      text: stock.apiName ?? stock.companyName,
    );
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: !loading,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Fix Stock Name for API'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.companyName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the name as the API recognises it.\nE.g. "Hdfc Silver", "Rail Vikas Nigam"',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'API search name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => loading = true);
                      final provider = context.read<PortfolioProvider>();
                      final found = await provider.updateStockApiName(
                        stock.id!,
                        name,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              found
                                  ? 'Price updated for "$name"'
                                  : 'No price found for "$name" — name saved, try again later',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: const Text('Fetch Price'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isProfit = stock.profitLoss >= 0;
    final pnlColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;
    final colorScheme = Theme.of(context).colorScheme;
    final hasPrice = stock.currentPrice != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stock.companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stock.percentChange != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (stock.percentChange! >= 0
                                  ? Colors.green
                                  : Colors.red)
                              .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stock.percentChange! >= 0 ? '+' : ''}${stock.percentChange!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: stock.percentChange! >= 0
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Edit button — always visible, highlighted in amber when no price
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: hasPrice
                        ? colorScheme.onSurfaceVariant
                        : Colors.amber.shade600,
                  ),
                  tooltip: hasPrice
                      ? 'Fix API name'
                      : 'Price unavailable — tap to fix API name',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniStat(
                  label: 'Qty',
                  value: stock.quantity.toStringAsFixed(
                    stock.quantity % 1 == 0 ? 0 : 2,
                  ),
                ),
                const SizedBox(width: 16),
                _MiniStat(label: 'Avg', value: fmt.format(stock.avgBuyPrice)),
                const SizedBox(width: 16),
                if (hasPrice)
                  _MiniStat(
                    label: 'LTP',
                    value: fmt.format(stock.currentPrice),
                  ),
                const Spacer(),
                if (hasPrice)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isProfit ? '+' : ''}${fmt.format(stock.profitLoss)}',
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${stock.profitLossPercentage.toStringAsFixed(2)}%',
                        style: TextStyle(color: pnlColor, fontSize: 11),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () => _showEditDialog(context),
                    child: Text(
                      'Price unavailable — fix',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            if (stock.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Updated: ${_formatDate(stock.lastUpdated!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
