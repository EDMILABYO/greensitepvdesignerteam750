import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const GreenSiteApp());

const academicNotice =
    "Les donnees utilisees dans cette application sont simulees et destinees uniquement a un usage academique.";

class GreenSiteApp extends StatefulWidget {
  const GreenSiteApp({super.key});

  @override
  State<GreenSiteApp> createState() => _GreenSiteAppState();
}

class _GreenSiteAppState extends State<GreenSiteApp> {
  final state = AppState();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0E9F6E);
    const navy = Color(0xFF123047);
    return AppScope(
      notifier: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GreenSite PV Simulator',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: green,
            primary: green,
            secondary: navy,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F7F6),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.white,
            foregroundColor: navy,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  AppState({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;
  String? token;
  String userName = 'Etudiant Demo';
  final List<SiteProfile> sites = [SiteProfile.demo()];
  final List<EquipmentItem> equipment = EquipmentItem.demoItems();
  final List<SimulationRecord> simulations = [];

  SiteProfile get activeSite => sites.first;

  Future<void> login(String email, String password) async {
    try {
      final response = await api.login(email, password);
      token = response['access_token'] as String?;
      userName = response['user']?['full_name'] as String? ?? userName;
    } catch (_) {
      token = 'offline-demo-token';
      userName = email.contains('@') ? email.split('@').first : userName;
    }
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await api.register(name, email, password);
      token = response['access_token'] as String?;
      userName = response['user']?['full_name'] as String? ?? name;
    } catch (_) {
      token = 'offline-demo-token';
      userName = name;
    }
    notifyListeners();
  }

  void addSite(SiteProfile site) {
    sites.insert(0, site);
    notifyListeners();
  }

  void addEquipment(EquipmentItem item) {
    equipment.add(item);
    notifyListeners();
  }

  SimulationRecord runSimulation(SimulationInputs inputs) {
    final result = calculate(activeSite, equipment, inputs);
    final record = SimulationRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      site: activeSite,
      equipment: List.of(equipment),
      inputs: inputs,
      result: result,
      createdAt: DateTime.now(),
    );
    simulations.insert(0, record);
    notifyListeners();
    return record;
  }

  DashboardStats get stats {
    if (simulations.isEmpty) {
      return const DashboardStats(0, null, 0, 0);
    }
    final pv = simulations
        .map((s) => s.result.requiredPvPowerWc)
        .reduce((a, b) => a + b);
    final battery = simulations
        .map((s) => s.result.requiredBatteryCapacityAh)
        .reduce((a, b) => a + b);
    return DashboardStats(
      simulations.length,
      simulations.first.createdAt,
      pv / simulations.length,
      battery / simulations.length,
    );
  }
}

class ApiClient {
  ApiClient({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
  });

  final String baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': name,
        'email': email,
        'password': password,
      }),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 400) {
      throw Exception(response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class SiteProfile {
  const SiteProfile({
    required this.name,
    required this.city,
    required this.country,
    required this.siteType,
    required this.description,
    required this.operatingHoursPerDay,
    required this.autonomyDays,
    required this.solarIrradiationHours,
    required this.systemEfficiency,
    required this.systemVoltage,
  });

  factory SiteProfile.demo() => const SiteProfile(
    name: 'HAYATCOM/GOMA Simulation',
    city: 'Goma',
    country: 'RDC',
    siteType: 'Site BTS simule',
    description: 'Profil academique simule pour un Green Site telecom.',
    operatingHoursPerDay: 24,
    autonomyDays: 2,
    solarIrradiationHours: 5,
    systemEfficiency: 0.8,
    systemVoltage: 48,
  );

  final String name;
  final String city;
  final String country;
  final String siteType;
  final String description;
  final double operatingHoursPerDay;
  final double autonomyDays;
  final double solarIrradiationHours;
  final double systemEfficiency;
  final int systemVoltage;
}

class EquipmentItem {
  const EquipmentItem({
    required this.name,
    required this.category,
    required this.powerWatts,
    required this.quantity,
    required this.hoursPerDay,
  });

  static List<EquipmentItem> demoItems() => const [
    EquipmentItem(
      name: 'BTS',
      category: 'BTS / antenne',
      powerWatts: 800,
      quantity: 1,
      hoursPerDay: 24,
    ),
    EquipmentItem(
      name: 'Routeur',
      category: 'Routeur',
      powerWatts: 150,
      quantity: 1,
      hoursPerDay: 24,
    ),
    EquipmentItem(
      name: 'Switch',
      category: 'Switch',
      powerWatts: 100,
      quantity: 1,
      hoursPerDay: 24,
    ),
    EquipmentItem(
      name: 'Faisceau hertzien',
      category: 'Faisceau hertzien',
      powerWatts: 200,
      quantity: 1,
      hoursPerDay: 24,
    ),
    EquipmentItem(
      name: 'Ventilation',
      category: 'Ventilation',
      powerWatts: 300,
      quantity: 1,
      hoursPerDay: 12,
    ),
    EquipmentItem(
      name: 'Eclairage',
      category: 'Eclairage',
      powerWatts: 50,
      quantity: 4,
      hoursPerDay: 10,
    ),
  ];

  final String name;
  final String category;
  final double powerWatts;
  final int quantity;
  final double hoursPerDay;
}

class SimulationInputs {
  const SimulationInputs({
    this.panelPowerWatts = 550,
    this.batteryCapacityAh = 200,
    this.batteryVoltage = 12,
    this.batteryDod = 0.8,
    this.panelUnitPrice = 150,
    this.batteryUnitPrice = 250,
    this.inverterPrice = 500,
    this.controllerPrice = 300,
    this.accessoriesPrice = 400,
    this.laborPrice = 500,
    this.maintenancePrice = 0,
  });

  final double panelPowerWatts;
  final double batteryCapacityAh;
  final double batteryVoltage;
  final double batteryDod;
  final double panelUnitPrice;
  final double batteryUnitPrice;
  final double inverterPrice;
  final double controllerPrice;
  final double accessoriesPrice;
  final double laborPrice;
  final double maintenancePrice;
}

class SimulationResult {
  const SimulationResult({
    required this.totalPowerWatts,
    required this.dailyEnergyWh,
    required this.correctedEnergyWh,
    required this.requiredPvPowerWc,
    required this.numberOfPanels,
    required this.requiredBatteryCapacityWh,
    required this.requiredBatteryCapacityAh,
    required this.numberOfBatteries,
    required this.controllerCurrentA,
    required this.inverterPowerWatts,
    required this.totalCost,
    required this.recommendations,
  });

  final double totalPowerWatts;
  final double dailyEnergyWh;
  final double correctedEnergyWh;
  final double requiredPvPowerWc;
  final int numberOfPanels;
  final double requiredBatteryCapacityWh;
  final double requiredBatteryCapacityAh;
  final int numberOfBatteries;
  final double controllerCurrentA;
  final double inverterPowerWatts;
  final double totalCost;
  final List<String> recommendations;
}

class SimulationRecord {
  const SimulationRecord({
    required this.id,
    required this.site,
    required this.equipment,
    required this.inputs,
    required this.result,
    required this.createdAt,
  });

  final int id;
  final SiteProfile site;
  final List<EquipmentItem> equipment;
  final SimulationInputs inputs;
  final SimulationResult result;
  final DateTime createdAt;
}

class DashboardStats {
  const DashboardStats(
    this.totalSimulations,
    this.lastSimulation,
    this.averagePvPowerWc,
    this.averageBatteryCapacityAh,
  );

  final int totalSimulations;
  final DateTime? lastSimulation;
  final double averagePvPowerWc;
  final double averageBatteryCapacityAh;
}

SimulationResult calculate(
  SiteProfile site,
  List<EquipmentItem> equipment,
  SimulationInputs inputs,
) {
  final totalPower = equipment.fold<double>(
    0,
    (sum, item) => sum + item.powerWatts * item.quantity,
  );
  final dailyEnergy = equipment.fold<double>(
    0,
    (sum, item) => sum + item.powerWatts * item.quantity * item.hoursPerDay,
  );
  final correctedEnergy = dailyEnergy / site.systemEfficiency;
  final pvPower = correctedEnergy / site.solarIrradiationHours;
  final panels = max(1, (pvPower / inputs.panelPowerWatts).ceil());
  final batteryWh = dailyEnergy * site.autonomyDays;
  final batteryAh = (batteryWh / site.systemVoltage) / inputs.batteryDod;
  final batteries = max(1, (batteryAh / inputs.batteryCapacityAh).ceil());
  final controller = (pvPower / site.systemVoltage) * 1.25;
  final inverter = totalPower * 1.25;
  final totalCost =
      panels * inputs.panelUnitPrice +
      batteries * inputs.batteryUnitPrice +
      inputs.inverterPrice +
      inputs.controllerPrice +
      inputs.accessoriesPrice +
      inputs.laborPrice +
      inputs.maintenancePrice;
  final recommendations = <String>[
    "Verifier l'orientation des panneaux, les protections et la ventilation des batteries.",
    if (dailyEnergy > 30000)
      "Consommation elevee: optimiser les equipements telecom.",
    if (site.autonomyDays > 3)
      "Autonomie superieure a 3 jours: cout fortement accru.",
    if (site.systemEfficiency < 0.7)
      "Rendement faible: choisir des composants de meilleure qualite.",
    if (pvPower > 10000)
      "Puissance PV superieure a 10 kWc: etude technique detaillee recommandee.",
    if (batteryAh > 1200)
      "Batteries importantes: envisager une solution hybride solaire + groupe.",
  ];

  return SimulationResult(
    totalPowerWatts: totalPower,
    dailyEnergyWh: dailyEnergy,
    correctedEnergyWh: correctedEnergy,
    requiredPvPowerWc: pvPower,
    numberOfPanels: panels,
    requiredBatteryCapacityWh: batteryWh,
    requiredBatteryCapacityAh: batteryAh,
    numberOfBatteries: batteries,
    controllerCurrentA: controller,
    inverterPowerWatts: inverter,
    totalCost: totalCost,
    recommendations: recommendations,
  );
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    required AppState super.notifier,
    required super.child,
    super.key,
  });

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E9F6E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.solar_power, color: Colors.white, size: 72),
            const SizedBox(height: 16),
            Text(
              'GreenSite PV Simulator',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dimensionnement photovoltaique telecom',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'student@example.com');
  final password = TextEditingController(text: 'password123');
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Connexion',
      subtitle: 'Acces etudiant ou administrateur',
      children: [
        AppTextField(
          controller: email,
          label: 'Email',
          icon: Icons.mail_outline,
        ),
        AppTextField(
          controller: password,
          label: 'Mot de passe',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        FilledButton.icon(
          onPressed: loading ? null : () async => _submit(context),
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: const Text('Se connecter'),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Creer un compte'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => loading = true);
    await AppScope.of(context).login(email.text, password.text);
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController(text: 'Etudiant Demo');
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Inscription',
      subtitle: 'Compte academique pour simulations',
      children: [
        AppTextField(
          controller: name,
          label: 'Nom complet',
          icon: Icons.person_outline,
        ),
        AppTextField(
          controller: email,
          label: 'Email',
          icon: Icons.mail_outline,
        ),
        AppTextField(
          controller: password,
          label: 'Mot de passe',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        FilledButton.icon(
          onPressed: () async {
            await AppScope.of(
              context,
            ).register(name.text, email.text, password.text);
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (_) => false,
              );
            }
          },
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Creer le compte'),
        ),
      ],
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.solar_power, color: Color(0xFF0E9F6E), size: 64),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(subtitle, style: const TextStyle(color: Color(0xFF5F6F7A))),
            const SizedBox(height: 20),
            NoticeCard(text: academicNotice),
            const SizedBox(height: 20),
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const SitesScreen(),
      const SimulationScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau',
          ),
          NavigationDestination(
            icon: Icon(Icons.cell_tower_outlined),
            selectedIcon: Icon(Icons.cell_tower),
            label: 'Sites',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calcul',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final stats = state.stats;
    return AppPage(
      title: 'Tableau de bord',
      action: IconButton(
        tooltip: 'Nouvelle simulation',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SimulationScreen(asPage: true),
          ),
        ),
        icon: const Icon(Icons.add_circle_outline),
      ),
      children: [
        NoticeCard(text: academicNotice),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            StatCard(
              icon: Icons.assignment,
              label: 'Simulations',
              value: '${stats.totalSimulations}',
            ),
            StatCard(
              icon: Icons.event,
              label: 'Derniere',
              value: stats.lastSimulation == null
                  ? '-'
                  : shortDate(stats.lastSimulation!),
            ),
            StatCard(
              icon: Icons.solar_power,
              label: 'PV moyen',
              value: '${stats.averagePvPowerWc.toStringAsFixed(0)} Wc',
            ),
            StatCard(
              icon: Icons.battery_charging_full,
              label: 'Batterie moy.',
              value: '${stats.averageBatteryCapacityAh.toStringAsFixed(0)} Ah',
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SimulationScreen(asPage: true),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle simulation'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HistoryScreen(asPage: true),
            ),
          ),
          icon: const Icon(Icons.history),
          label: const Text('Historique'),
        ),
      ],
    );
  }
}

class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Sites simules',
      action: IconButton(
        tooltip: 'Ajouter un site',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SiteFormScreen())),
        icon: const Icon(Icons.add_location_alt_outlined),
      ),
      children: [
        for (final site in state.sites)
          InfoCard(
            icon: Icons.cell_tower,
            title: site.name,
            subtitle: '${site.city}, ${site.country} - ${site.siteType}',
            lines: [
              'Autonomie: ${site.autonomyDays} jours',
              'Irradiation: ${site.solarIrradiationHours} h/jour',
              'Rendement: ${(site.systemEfficiency * 100).toStringAsFixed(0)}%',
              'Tension: ${site.systemVoltage} V',
            ],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SiteDetailScreen(site: site)),
            ),
          ),
      ],
    );
  }
}

class SiteDetailScreen extends StatelessWidget {
  const SiteDetailScreen({required this.site, super.key});

  final SiteProfile site;

  @override
  Widget build(BuildContext context) {
    final equipment = AppScope.of(context).equipment;
    return AppPage(
      title: 'Details du site',
      action: IconButton(
        tooltip: 'Ajouter equipement',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const EquipmentFormScreen())),
        icon: const Icon(Icons.add),
      ),
      children: [
        InfoCard(
          icon: Icons.cell_tower,
          title: site.name,
          subtitle: site.description,
          lines: ['${site.city}, ${site.country}', site.siteType],
        ),
        Text(
          'Equipements',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        for (final item in equipment)
          InfoCard(
            icon: Icons.electrical_services,
            title: item.name,
            subtitle: item.category,
            lines: [
              '${item.powerWatts.toStringAsFixed(0)} W x ${item.quantity}',
              '${item.hoursPerDay} h/jour',
            ],
          ),
      ],
    );
  }
}

class SiteFormScreen extends StatefulWidget {
  const SiteFormScreen({super.key});

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final name = TextEditingController(text: 'HAYATCOM/GOMA Simulation 1');
  final city = TextEditingController(text: 'Goma');
  final country = TextEditingController(text: 'RDC');
  final type = TextEditingController(text: 'Site telecom BTS');
  final description = TextEditingController(
    text: 'Simulation academique sans donnees reelles.',
  );
  final autonomy = TextEditingController(text: '2');
  final irradiation = TextEditingController(text: '5');
  final efficiency = TextEditingController(text: '80');
  int voltage = 48;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Creation site',
      children: [
        AppTextField(
          controller: name,
          label: 'Nom du site',
          icon: Icons.badge_outlined,
        ),
        AppTextField(
          controller: city,
          label: 'Ville',
          icon: Icons.location_city,
        ),
        AppTextField(controller: country, label: 'Pays', icon: Icons.public),
        AppTextField(
          controller: type,
          label: 'Type de site',
          icon: Icons.cell_tower,
        ),
        AppTextField(
          controller: description,
          label: 'Description',
          icon: Icons.notes,
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: autonomy,
                label: 'Autonomie jours',
                icon: Icons.battery_5_bar,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: irradiation,
                label: 'Soleil h/jour',
                icon: Icons.wb_sunny_outlined,
              ),
            ),
          ],
        ),
        AppTextField(
          controller: efficiency,
          label: 'Rendement global %',
          icon: Icons.speed,
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 12, label: Text('12V')),
            ButtonSegment(value: 24, label: Text('24V')),
            ButtonSegment(value: 48, label: Text('48V')),
          ],
          selected: {voltage},
          onSelectionChanged: (values) =>
              setState(() => voltage = values.first),
        ),
        FilledButton.icon(
          onPressed: () {
            AppScope.of(context).addSite(
              SiteProfile(
                name: name.text,
                city: city.text,
                country: country.text,
                siteType: type.text,
                description: description.text,
                operatingHoursPerDay: 24,
                autonomyDays: readDouble(autonomy, 2),
                solarIrradiationHours: readDouble(irradiation, 5),
                systemEfficiency: readDouble(efficiency, 80) / 100,
                systemVoltage: voltage,
              ),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({super.key});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final name = TextEditingController();
  final power = TextEditingController(text: '100');
  final quantity = TextEditingController(text: '1');
  final hours = TextEditingController(text: '24');
  String category = 'Autre';

  @override
  Widget build(BuildContext context) {
    const categories = [
      'BTS / antenne',
      'Routeur',
      'Switch',
      'Faisceau hertzien',
      'Ventilation',
      'Eclairage',
      'Systeme de securite',
      'Autre',
    ];
    return AppPage(
      title: 'Ajout equipement',
      children: [
        AppTextField(
          controller: name,
          label: "Nom de l'equipement",
          icon: Icons.electrical_services,
        ),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(
            labelText: 'Categorie',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final item in categories)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) => setState(() => category = value ?? category),
        ),
        AppTextField(controller: power, label: 'Puissance W', icon: Icons.bolt),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: quantity,
                label: 'Quantite',
                icon: Icons.numbers,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: hours,
                label: 'Heures/jour',
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () {
            AppScope.of(context).addEquipment(
              EquipmentItem(
                name: name.text.isEmpty ? category : name.text,
                category: category,
                powerWatts: readDouble(power, 100),
                quantity: readDouble(quantity, 1).round(),
                hoursPerDay: readDouble(hours, 24),
              ),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({this.asPage = false, super.key});

  final bool asPage;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final panel = TextEditingController(text: '550');
  final batteryAh = TextEditingController(text: '200');
  final batteryVoltage = TextEditingController(text: '12');
  final dod = TextEditingController(text: '80');
  final panelPrice = TextEditingController(text: '150');
  final batteryPrice = TextEditingController(text: '250');
  final inverter = TextEditingController(text: '500');
  final controller = TextEditingController(text: '300');
  final accessories = TextEditingController(text: '400');
  final labor = TextEditingController(text: '500');

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Parametres simulation',
      showBack: widget.asPage,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: panel,
                label: 'Panneau Wc',
                icon: Icons.solar_power,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: batteryAh,
                label: 'Batterie Ah',
                icon: Icons.battery_full,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: batteryVoltage,
                label: 'Tension batterie',
                icon: Icons.power,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: dod,
                label: 'DOD %',
                icon: Icons.percent,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: panelPrice,
                label: 'Prix panneau',
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: batteryPrice,
                label: 'Prix batterie',
                icon: Icons.attach_money,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: inverter,
                label: 'Onduleur',
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: controller,
                label: 'Regulateur',
                icon: Icons.attach_money,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: accessories,
                label: 'Accessoires',
                icon: Icons.construction,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: labor,
                label: "Main d'oeuvre",
                icon: Icons.engineering,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () {
            final record = AppScope.of(context).runSimulation(
              SimulationInputs(
                panelPowerWatts: readDouble(panel, 550),
                batteryCapacityAh: readDouble(batteryAh, 200),
                batteryVoltage: readDouble(batteryVoltage, 12),
                batteryDod: readDouble(dod, 80) / 100,
                panelUnitPrice: readDouble(panelPrice, 150),
                batteryUnitPrice: readDouble(batteryPrice, 250),
                inverterPrice: readDouble(inverter, 500),
                controllerPrice: readDouble(controller, 300),
                accessoriesPrice: readDouble(accessories, 400),
                laborPrice: readDouble(labor, 500),
              ),
            );
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
            );
          },
          icon: const Icon(Icons.calculate),
          label: const Text('Lancer le calcul'),
        ),
      ],
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.record, super.key});

  final SimulationRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record.result;
    return AppPage(
      title: 'Resultats',
      children: [
        ResultGrid(result: r),
        Text(
          'Recommandations',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        for (final rec in r.recommendations)
          InfoCard(
            icon: Icons.tips_and_updates_outlined,
            title: rec,
            subtitle: '',
            lines: const [],
          ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReportScreen(record: record)),
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Voir le rapport'),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({this.asPage = false, super.key});

  final bool asPage;

  @override
  Widget build(BuildContext context) {
    final simulations = AppScope.of(context).simulations;
    return AppPage(
      title: 'Historique',
      showBack: asPage,
      children: [
        if (simulations.isEmpty)
          const InfoCard(
            icon: Icons.history,
            title: 'Aucune simulation sauvegardee',
            subtitle: 'Lancez un calcul pour alimenter lhistorique.',
            lines: [],
          ),
        for (final simulation in simulations)
          InfoCard(
            icon: Icons.summarize_outlined,
            title: simulation.site.name,
            subtitle: shortDate(simulation.createdAt),
            lines: [
              '${simulation.result.requiredPvPowerWc.toStringAsFixed(0)} Wc',
              '${simulation.result.numberOfPanels} panneaux',
              '${simulation.result.numberOfBatteries} batteries',
              '${simulation.result.totalCost.toStringAsFixed(0)} USD',
            ],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResultScreen(record: simulation),
              ),
            ),
          ),
      ],
    );
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({required this.record, super.key});

  final SimulationRecord record;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Rapport',
      children: [
        NoticeCard(text: academicNotice),
        InfoCard(
          icon: Icons.cell_tower,
          title: record.site.name,
          subtitle: '${record.site.city}, ${record.site.country}',
          lines: [record.site.siteType, record.site.description],
        ),
        Text(
          'Liste des equipements',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        for (final item in record.equipment)
          Text(
            '- ${item.name}: ${item.powerWatts.toStringAsFixed(0)} W x ${item.quantity}, ${item.hoursPerDay} h/jour',
          ),
        const SizedBox(height: 8),
        Text(
          'Hypotheses',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Text(
          '- Energie corrigee = Energie journaliere / rendement global',
        ),
        const Text('- Puissance PV = Energie corrigee / heures solaires'),
        const Text('- Regulateur et onduleur avec marge de 25%'),
        const SizedBox(height: 8),
        ResultGrid(result: record.result),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Profil utilisateur',
      children: [
        InfoCard(
          icon: Icons.person,
          title: state.userName,
          subtitle: 'Role: etudiant',
          lines: [
            'Mode API: ${state.token == 'offline-demo-token' ? 'demo local' : 'connecte'}',
            'Swagger backend: /docs',
          ],
        ),
        NoticeCard(text: academicNotice),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Deconnexion'),
        ),
      ],
    );
  }
}

class ResultGrid extends StatelessWidget {
  const ResultGrid({required this.result, super.key});

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Puissance installee',
        '${result.totalPowerWatts.toStringAsFixed(0)} W',
        Icons.bolt,
      ),
      (
        'Energie/jour',
        '${(result.dailyEnergyWh / 1000).toStringAsFixed(2)} kWh',
        Icons.offline_bolt,
      ),
      (
        'Energie corrigee',
        '${(result.correctedEnergyWh / 1000).toStringAsFixed(2)} kWh',
        Icons.speed,
      ),
      (
        'Puissance PV',
        '${result.requiredPvPowerWc.toStringAsFixed(0)} Wc',
        Icons.solar_power,
      ),
      ('Panneaux', '${result.numberOfPanels}', Icons.grid_view),
      (
        'Batterie Wh',
        '${result.requiredBatteryCapacityWh.toStringAsFixed(0)} Wh',
        Icons.battery_5_bar,
      ),
      (
        'Batterie Ah',
        '${result.requiredBatteryCapacityAh.toStringAsFixed(0)} Ah',
        Icons.battery_full,
      ),
      ('Batteries', '${result.numberOfBatteries}', Icons.battery_charging_full),
      (
        'Regulateur',
        '${result.controllerCurrentA.toStringAsFixed(1)} A',
        Icons.settings_input_component,
      ),
      (
        'Onduleur',
        '${result.inverterPowerWatts.toStringAsFixed(0)} W',
        Icons.power,
      ),
      (
        'Cout total',
        '${result.totalCost.toStringAsFixed(0)} USD',
        Icons.payments_outlined,
      ),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        for (final row in rows)
          StatCard(label: row.$1, value: row.$2, icon: row.$3),
      ],
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.children,
    this.action,
    this.showBack = false,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: Text(title),
        actions: [if (action != null) action!],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, index) => children[index],
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemCount: children.length,
        ),
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE8F8F1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: Color(0xFF0E9F6E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF5F6F7A)),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.lines,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF5F6F7A)),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final line in lines) Chip(label: Text(line)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

double readDouble(TextEditingController controller, double fallback) {
  return double.tryParse(controller.text.replaceAll(',', '.')) ?? fallback;
}

String shortDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
