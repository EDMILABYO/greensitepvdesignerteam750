import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(const GreenSiteApp());

const landingForest = Color(0xFF082F28);
const landingForestMid = Color(0xFF0C4A38);
const landingForestDeep = Color(0xFF082B24);
const landingGreen = Color(0xFF63B642);
const landingGreenLight = Color(0xFF7FC84A);
const appForest = Color(0xFF082F28);
const appForestMid = Color(0xFF0C4A38);
const appForestDeep = Color(0xFF082B24);
const appGreen = Color(0xFF63B642);
const appGreenDark = Color(0xFF0B5D43);
const appGreenLight = Color(0xFF7FC84A);
const appNavy = Color(0xFF102B24);
const appAmber = Color(0xFFF5B942);
const appSurface = Color(0xFFFFFFFF);
const appBackground = Color(0xFFF6FAF7);
const appMutedText = Color(0xFF5E7068);

class GreenSiteApp extends StatefulWidget {
  const GreenSiteApp({super.key});

  @override
  State<GreenSiteApp> createState() => _GreenSiteAppState();
}

class _GreenSiteAppState extends State<GreenSiteApp> {
  final state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GreenSite PV Simulator',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: appGreen,
            primary: appGreen,
            secondary: appGreenLight,
            tertiary: appAmber,
            surface: appSurface,
            surfaceContainerHighest: const Color(0xFFDDEBE2),
          ),
          scaffoldBackgroundColor: appBackground,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: appSurface,
            foregroundColor: appNavy,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            backgroundColor: appSurface,
            indicatorColor: appGreen.withValues(alpha: 0.18),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? appGreenDark
                    : appMutedText,
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
          navigationRailTheme: NavigationRailThemeData(
            backgroundColor: appSurface,
            indicatorColor: appGreen.withValues(alpha: 0.18),
            selectedIconTheme: const IconThemeData(color: appGreenDark),
            unselectedIconTheme: const IconThemeData(color: appMutedText),
            selectedLabelTextStyle: const TextStyle(
              color: appGreenDark,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelTextStyle: const TextStyle(color: appMutedText),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: appGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: appGreenLight,
              minimumSize: const Size(48, 48),
              side: BorderSide(color: appGreen.withValues(alpha: 0.62)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: appSurface,
            prefixIconColor: appGreenDark,
            labelStyle: const TextStyle(color: appMutedText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appNavy.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appNavy.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: appGreen, width: 1.6),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFEAF3EF),
            side: BorderSide(color: appGreen.withValues(alpha: 0.12)),
            labelStyle: const TextStyle(
              color: appGreenDark,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          cardTheme: CardThemeData(
            color: appSurface,
            elevation: 1,
            shadowColor: appNavy.withValues(alpha: 0.08),
            surfaceTintColor: appSurface,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: appNavy.withValues(alpha: 0.08)),
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
  String userEmail = 'student@example.com';
  String userRole = 'student';
  Uint8List? profilePhotoBytes;
  bool syncing = false;
  String syncStatus = 'Mode demo pret';
  final List<ClientProfile> clients = [ClientProfile.demo()];
  final List<SiteProfile> sites = [SiteProfile.demo()];
  final List<EquipmentItem> equipment = EquipmentItem.demoItems();
  final List<SimulationRecord> simulations = [];
  final List<AdminUserProfile> adminUsers = [];

  SiteProfile get activeSite => sites.first;
  bool get isAdmin => userRole == 'admin';

  void logout() {
    token = null;
    userName = 'Etudiant Demo';
    userEmail = 'student@example.com';
    userRole = 'student';
    profilePhotoBytes = null;
    adminUsers.clear();
    syncStatus = 'Deconnecte';
    notifyListeners();
  }

  Future<void> pickProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      imageQuality: 82,
    );
    if (image == null) return;
    profilePhotoBytes = await image.readAsBytes();
    notifyListeners();
  }

  void removeProfilePhoto() {
    profilePhotoBytes = null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    token = null;
    adminUsers.clear();
    syncStatus = 'Connexion a API Render...';
    notifyListeners();
    final response = await api.login(email, password);
    token = response['access_token'] as String?;
    _applyUser(response['user'], fallbackEmail: email);
    await syncFromApi();
    notifyListeners();
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String role = 'student',
  }) async {
    token = null;
    adminUsers.clear();
    syncStatus = 'Creation du compte sur API Render...';
    notifyListeners();
    final response = await api.register(name, email, password, role: role);
    token = response['access_token'] as String?;
    _applyUser(response['user'], fallbackEmail: email, fallbackName: name);
    await syncFromApi();
    notifyListeners();
  }

  void _applyUser(
    dynamic user, {
    required String fallbackEmail,
    String? fallbackName,
  }) {
    final map = user is Map<String, dynamic> ? user : <String, dynamic>{};
    userName = map['full_name'] as String? ?? fallbackName ?? userName;
    userEmail = map['email'] as String? ?? fallbackEmail;
    userRole = map['role'] as String? ?? 'student';
  }

  Future<void> syncFromApi() async {
    if (token == null) return;
    syncing = true;
    syncStatus = 'Synchronisation API...';
    notifyListeners();
    try {
      final remoteClients = await api.listClients(token!);
      final remoteSites = await api.listSites(token!);
      clients
        ..clear()
        ..addAll(remoteClients.map(ClientProfile.fromJson));
      sites
        ..clear()
        ..addAll(remoteSites.map(SiteProfile.fromJson));
      if (sites.isEmpty) {
        sites.add(SiteProfile.demo());
      }
      if (clients.isEmpty) {
        clients.add(ClientProfile.demo());
      }
      await syncAdminData();
      syncStatus = 'Connecte a API Render';
    } catch (_) {
      syncStatus = 'API indisponible, donnees locales conservees';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> syncAdminData() async {
    if (!isAdmin || token == null) return;
    try {
      final remoteUsers = await api.listUsers(token!);
      adminUsers
        ..clear()
        ..addAll(remoteUsers.map(AdminUserProfile.fromJson));
    } catch (_) {
      if (adminUsers.isEmpty) {
        adminUsers.add(AdminUserProfile.demo(userName, userEmail, userRole));
      }
    }
    notifyListeners();
  }

  Future<void> addClient(ClientProfile client) async {
    if (token != null) {
      try {
        final created = await api.createClient(token!, client);
        clients.insert(0, ClientProfile.fromJson(created));
        notifyListeners();
        return;
      } catch (_) {
        syncStatus = 'Client ajoute localement';
      }
    }
    clients.insert(0, client);
    notifyListeners();
  }

  Future<void> updateClient(
    ClientProfile oldClient,
    ClientProfile client,
  ) async {
    final index = clients.indexOf(oldClient);
    if (index == -1) return;
    if (token != null && oldClient.id != null) {
      try {
        final updated = await api.updateClient(token!, oldClient.id!, client);
        clients[index] = ClientProfile.fromJson(updated);
        notifyListeners();
        return;
      } catch (_) {
        syncStatus = 'Client modifie localement';
      }
    }
    clients[index] = client;
    notifyListeners();
  }

  Future<void> deleteClient(ClientProfile client) async {
    if (token != null && client.id != null) {
      try {
        await api.deleteClient(token!, client.id!);
      } catch (_) {
        syncStatus = 'Suppression locale uniquement';
      }
    }
    clients.remove(client);
    notifyListeners();
  }

  Future<void> addSite(SiteProfile site) async {
    if (token != null) {
      try {
        final created = await api.createSite(token!, site);
        sites.insert(0, SiteProfile.fromJson(created));
        notifyListeners();
        return;
      } catch (_) {
        syncStatus = 'Site ajoute localement';
      }
    }
    sites.insert(0, site);
    notifyListeners();
  }

  Future<void> updateSite(SiteProfile oldSite, SiteProfile site) async {
    final index = sites.indexOf(oldSite);
    if (index == -1) return;
    if (token != null && oldSite.id != null) {
      try {
        final updated = await api.updateSite(token!, oldSite.id!, site);
        sites[index] = SiteProfile.fromJson(updated);
        notifyListeners();
        return;
      } catch (_) {
        syncStatus = 'Site modifie localement';
      }
    }
    sites[index] = site;
    notifyListeners();
  }

  Future<void> deleteSite(SiteProfile site) async {
    if (sites.length == 1) return;
    if (token != null && site.id != null) {
      try {
        await api.deleteSite(token!, site.id!);
      } catch (_) {
        syncStatus = 'Suppression locale uniquement';
      }
    }
    sites.remove(site);
    notifyListeners();
  }

  Future<void> addEquipment(EquipmentItem item) async {
    if (token != null && activeSite.id != null) {
      try {
        final created = await api.createEquipment(token!, activeSite.id!, item);
        equipment.add(EquipmentItem.fromJson(created));
        notifyListeners();
        return;
      } catch (_) {
        syncStatus = 'Equipement ajoute localement';
      }
    }
    equipment.add(item);
    notifyListeners();
  }

  void removeEquipment(EquipmentItem item) {
    equipment.remove(item);
    notifyListeners();
  }

  void deleteSimulation(SimulationRecord record) {
    simulations.removeWhere((simulation) => simulation.id == record.id);
    notifyListeners();
  }

  void clearHistory() {
    simulations.clear();
    notifyListeners();
  }

  FeasibilityResult runFeasibility(FeasibilityInputs inputs) {
    return calculateFeasibility(activeSite, equipment, inputs);
  }

  ImplementationResult runImplementation(
    ImplementationInputs inputs,
    SimulationResult? latestDesign,
  ) {
    return calculateImplementation(activeSite, inputs, latestDesign);
  }

  MaintenanceResult runMaintenance(MaintenanceInputs inputs) {
    return evaluateMaintenance(inputs);
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
      defaultValue: 'https://greensitepvdesignerteam750s.onrender.com',
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
    String password, {
    String role = 'student',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    return _decode(response);
  }

  Future<List<dynamic>> listClients(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/clients'),
      headers: _authHeaders(token),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> createClient(
    String token,
    ClientProfile client,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: _authHeaders(token),
      body: jsonEncode(client.toJson()),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateClient(
    String token,
    int id,
    ClientProfile client,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clients/$id'),
      headers: _authHeaders(token),
      body: jsonEncode(client.toJson()),
    );
    return _decode(response);
  }

  Future<void> deleteClient(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/clients/$id'),
      headers: _authHeaders(token),
    );
    if (response.statusCode >= 400) throw Exception(response.body);
  }

  Future<List<dynamic>> listUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _authHeaders(token),
    );
    return _decodeList(response);
  }

  Future<List<dynamic>> listSites(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sites'),
      headers: _authHeaders(token),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> createSite(
    String token,
    SiteProfile site,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sites'),
      headers: _authHeaders(token),
      body: jsonEncode(site.toJson()),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateSite(
    String token,
    int id,
    SiteProfile site,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sites/$id'),
      headers: _authHeaders(token),
      body: jsonEncode(site.toJson()),
    );
    return _decode(response);
  }

  Future<void> deleteSite(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sites/$id'),
      headers: _authHeaders(token),
    );
    if (response.statusCode >= 400) throw Exception(response.body);
  }

  Future<Map<String, dynamic>> createEquipment(
    String token,
    int siteId,
    EquipmentItem item,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sites/$siteId/equipment'),
      headers: _authHeaders(token),
      body: jsonEncode(item.toJson()),
    );
    return _decode(response);
  }

  Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _errorDetail(response.body));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _errorDetail(response.body));
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  String _errorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List) return detail.join(', ');
      }
    } catch (_) {
      // Keep raw body fallback below.
    }
    return body.isEmpty ? 'Erreur API inconnue' : body;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

String authErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 401) {
      return 'Email ou mot de passe incorrect.';
    }
    if (error.statusCode == 409) {
      return 'Ce compte existe deja.';
    }
    if (error.statusCode == 422) {
      return 'Verifiez les informations saisies.';
    }
    if (error.statusCode >= 500) {
      return "Erreur serveur API. Verifiez le deploiement Render et la base PostgreSQL.";
    }
    return error.message;
  }
  return "Impossible de joindre l'API Render. Verifiez la connexion.";
}

class ClientProfile {
  const ClientProfile({
    this.id,
    required this.name,
    required this.organization,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
  });

  factory ClientProfile.demo() => const ClientProfile(
    name: 'Client academique',
    organization: 'Green Site Demo',
    phone: '+243 000 000 000',
    email: 'client@example.com',
    address: 'Goma, RDC',
    notes: 'Client fictif pour presentation academique.',
  );

  factory ClientProfile.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return ClientProfile(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      organization: map['organization'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  final int? id;
  final String name;
  final String organization;
  final String phone;
  final String email;
  final String address;
  final String notes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'organization': organization,
    'phone': phone,
    'email': email,
    'address': address,
    'notes': notes,
  };
}

class AdminUserProfile {
  const AdminUserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AdminUserProfile.demo(String name, String email, String role) {
    return AdminUserProfile(
      id: 0,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
  }

  factory AdminUserProfile.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return AdminUserProfile(
      id: (map['id'] as num?)?.round() ?? 0,
      name: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
}

class SiteProfile {
  const SiteProfile({
    this.id,
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

  factory SiteProfile.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return SiteProfile(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      country: map['country'] as String? ?? '',
      siteType: map['site_type'] as String? ?? '',
      description: map['description'] as String? ?? '',
      operatingHoursPerDay:
          (map['operating_hours_per_day'] as num?)?.toDouble() ?? 24,
      autonomyDays: (map['autonomy_days'] as num?)?.toDouble() ?? 2,
      solarIrradiationHours:
          (map['solar_irradiation_hours'] as num?)?.toDouble() ?? 5,
      systemEfficiency: (map['system_efficiency'] as num?)?.toDouble() ?? 0.8,
      systemVoltage: (map['system_voltage'] as num?)?.round() ?? 48,
    );
  }

  final int? id;
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'country': country,
    'site_type': siteType,
    'description': description,
    'operating_hours_per_day': operatingHoursPerDay,
    'autonomy_days': autonomyDays,
    'solar_irradiation_hours': solarIrradiationHours,
    'system_efficiency': systemEfficiency,
    'system_voltage': systemVoltage,
  };
}

class EquipmentItem {
  const EquipmentItem({
    this.id,
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

  factory EquipmentItem.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return EquipmentItem(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Autre',
      powerWatts: (map['power_watts'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.round() ?? 1,
      hoursPerDay: (map['hours_per_day'] as num?)?.toDouble() ?? 24,
    );
  }

  final int? id;
  final String name;
  final String category;
  final double powerWatts;
  final int quantity;
  final double hoursPerDay;

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'power_watts': powerWatts,
    'quantity': quantity,
    'hours_per_day': hoursPerDay,
  };
}

class SimulationInputs {
  const SimulationInputs({
    this.panelPowerWatts = 550,
    this.panelTechnology = 'Monocristallin',
    this.batteryCapacityAh = 200,
    this.batteryVoltage = 12,
    this.batteryTechnology = 'LiFePO4',
    this.batteryDod = 0.8,
    this.controllerType = 'MPPT',
    this.mpptEfficiency = 0.96,
    this.wiringLossPercent = 3,
    this.temperatureLossPercent = 5,
    this.dustLossPercent = 3,
    this.inverterEfficiency = 0.93,
    this.safetyFactor = 1.25,
    this.panelUnitPrice = 150,
    this.batteryUnitPrice = 250,
    this.inverterPrice = 500,
    this.controllerPrice = 300,
    this.accessoriesPrice = 400,
    this.laborPrice = 500,
    this.maintenancePrice = 0,
  });

  final double panelPowerWatts;
  final String panelTechnology;
  final double batteryCapacityAh;
  final double batteryVoltage;
  final String batteryTechnology;
  final double batteryDod;
  final String controllerType;
  final double mpptEfficiency;
  final double wiringLossPercent;
  final double temperatureLossPercent;
  final double dustLossPercent;
  final double inverterEfficiency;
  final double safetyFactor;
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
    required this.globalEfficiency,
    required this.selectedArchitecture,
    required this.protections,
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
  final double globalEfficiency;
  final String selectedArchitecture;
  final List<String> protections;
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

class FeasibilityInputs {
  const FeasibilityInputs({
    this.averageGhiKwhM2Day = 5,
    this.dieselLitersPerKwh = 0.35,
    this.dieselPricePerLiter = 1.5,
    this.generatorMaintenancePerYear = 1200,
    this.solarCapex = 6500,
    this.solarOpexPerYear = 350,
    this.studyYears = 20,
    this.co2KgPerLiter = 2.68,
    this.logisticsFactor = 1.15,
  });

  final double averageGhiKwhM2Day;
  final double dieselLitersPerKwh;
  final double dieselPricePerLiter;
  final double generatorMaintenancePerYear;
  final double solarCapex;
  final double solarOpexPerYear;
  final int studyYears;
  final double co2KgPerLiter;
  final double logisticsFactor;
}

class FeasibilityResult {
  const FeasibilityResult({
    required this.annualEnergyKwh,
    required this.annualDieselLiters,
    required this.annualDieselOpex,
    required this.dieselTco,
    required this.solarTco,
    required this.annualSavings,
    required this.paybackYears,
    required this.co2AvoidedKgPerYear,
    required this.feasibilityScore,
    required this.verdict,
    required this.recommendations,
  });

  final double annualEnergyKwh;
  final double annualDieselLiters;
  final double annualDieselOpex;
  final double dieselTco;
  final double solarTco;
  final double annualSavings;
  final double? paybackYears;
  final double co2AvoidedKgPerYear;
  final int feasibilityScore;
  final String verdict;
  final List<String> recommendations;
}

class ImplementationInputs {
  const ImplementationInputs({
    this.latitude = -1.68,
    this.measuredDailyEnergyKwh = 50,
    this.measuredBatteryVoltage = 48,
    this.expectedBatteryVoltage = 48,
    this.smartSleepSavingsPercent = 8,
  });

  final double latitude;
  final double measuredDailyEnergyKwh;
  final double measuredBatteryVoltage;
  final double expectedBatteryVoltage;
  final double smartSleepSavingsPercent;
}

class ImplementationResult {
  const ImplementationResult({
    required this.recommendedTiltDegrees,
    required this.recommendedOrientation,
    required this.theoreticalDailyEnergyKwh,
    required this.performanceRatio,
    required this.energyGapKwh,
    required this.batteryVoltageStatus,
    required this.optimizedLoadPowerWatts,
    required this.installationChecklist,
    required this.testProtocol,
    required this.operationalRecommendations,
    required this.alerts,
  });

  final double recommendedTiltDegrees;
  final String recommendedOrientation;
  final double theoreticalDailyEnergyKwh;
  final double performanceRatio;
  final double energyGapKwh;
  final String batteryVoltageStatus;
  final double optimizedLoadPowerWatts;
  final List<String> installationChecklist;
  final List<String> testProtocol;
  final List<String> operationalRecommendations;
  final List<String> alerts;
}

class MaintenanceInputs {
  const MaintenanceInputs({
    this.availabilityPercent = 99,
    this.performanceRatio = 0.85,
    this.batterySocPercent = 80,
    this.batterySohPercent = 92,
    this.batteryCycles = 450,
    this.daysSincePanelCleaning = 20,
    this.daysSinceElectricalInspection = 45,
    this.annualDieselLitersAvoided = 4500,
    this.sitesReplicableCount = 1,
  });

  final double availabilityPercent;
  final double performanceRatio;
  final double batterySocPercent;
  final double batterySohPercent;
  final int batteryCycles;
  final int daysSincePanelCleaning;
  final int daysSinceElectricalInspection;
  final double annualDieselLitersAvoided;
  final int sitesReplicableCount;
}

class MaintenanceResult {
  const MaintenanceResult({
    required this.healthScore,
    required this.availabilityStatus,
    required this.energyStatus,
    required this.batteryStatus,
    required this.co2AvoidedKgPerYear,
    required this.networkCo2PotentialKgPerYear,
    required this.nextPanelCleaningDays,
    required this.nextElectricalInspectionDays,
    required this.maintenanceTasks,
    required this.alerts,
    required this.kpis,
    required this.valorizationPoints,
  });

  final int healthScore;
  final String availabilityStatus;
  final String energyStatus;
  final String batteryStatus;
  final double co2AvoidedKgPerYear;
  final double networkCo2PotentialKgPerYear;
  final int nextPanelCleaningDays;
  final int nextElectricalInspectionDays;
  final List<String> maintenanceTasks;
  final List<String> alerts;
  final List<String> kpis;
  final List<String> valorizationPoints;
}

MaintenanceResult evaluateMaintenance(MaintenanceInputs inputs) {
  var score = 100;
  final alerts = <String>[];
  if (inputs.availabilityPercent < 99) {
    score -= 15;
    alerts.add('Disponibilite inferieure a 99%: analyser les coupures.');
  }
  if (inputs.performanceRatio < 0.8) {
    score -= 20;
    alerts.add('Performance ratio faible: nettoyer panneaux et verifier MPPT.');
  }
  if (inputs.batterySocPercent < 30) {
    score -= 15;
    alerts.add('SOC batterie faible: risque de coupure.');
  }
  if (inputs.batterySohPercent < 80) {
    score -= 20;
    alerts.add('SOH batterie faible: planifier remplacement.');
  }
  if (inputs.daysSincePanelCleaning > 30) {
    score -= 10;
    alerts.add('Nettoyage panneaux en retard.');
  }
  if (inputs.daysSinceElectricalInspection > 90) {
    score -= 10;
    alerts.add('Inspection electrique en retard.');
  }
  score = max(0, score);
  final co2 = inputs.annualDieselLitersAvoided * 2.68;
  final nextCleaning = max(0, 30 - inputs.daysSincePanelCleaning);
  final nextInspection = max(0, 90 - inputs.daysSinceElectricalInspection);
  return MaintenanceResult(
    healthScore: score,
    availabilityStatus: inputs.availabilityPercent >= 99
        ? 'Excellent'
        : 'A surveiller',
    energyStatus: inputs.performanceRatio >= 0.8 ? 'Normal' : 'Degrade',
    batteryStatus: inputs.batterySohPercent >= 80 ? 'Normal' : 'Critique',
    co2AvoidedKgPerYear: co2,
    networkCo2PotentialKgPerYear: co2 * inputs.sitesReplicableCount,
    nextPanelCleaningDays: nextCleaning,
    nextElectricalInspectionDays: nextInspection,
    maintenanceTasks: [
      'Nettoyage panneaux dans $nextCleaning jours.',
      'Inspection connexions/protections dans $nextInspection jours.',
      'Verifier serrage DC/AC, corrosion, parafoudre et mise a la terre.',
      'Exporter les KPI mensuels pour le rapport de suivi.',
    ],
    alerts: alerts.isEmpty ? ['Aucune alerte critique detectee.'] : alerts,
    kpis: [
      'Disponibilite: ${inputs.availabilityPercent.toStringAsFixed(1)}%',
      'Performance ratio: ${(inputs.performanceRatio * 100).toStringAsFixed(1)}%',
      'SOC batterie: ${inputs.batterySocPercent.toStringAsFixed(1)}%',
      'SOH batterie: ${inputs.batterySohPercent.toStringAsFixed(1)}%',
      'Cycles batterie: ${inputs.batteryCycles}',
    ],
    valorizationPoints: [
      'CO2 evite: ${(co2 / 1000).toStringAsFixed(2)} tonnes/an.',
      'Potentiel ${inputs.sitesReplicableCount} sites: ${(co2 * inputs.sitesReplicableCount / 1000).toStringAsFixed(2)} tonnes/an.',
      'Les KPI soutiennent la strategie RSE et la generalisation multi-sites.',
    ],
  );
}

ImplementationResult calculateImplementation(
  SiteProfile site,
  ImplementationInputs inputs,
  SimulationResult? latestDesign,
) {
  final tilt = max(10, min(35, inputs.latitude.abs() + 10)).toDouble();
  final orientation = inputs.latitude < 0 ? 'Nord' : 'Sud';
  final panelCount = latestDesign?.numberOfPanels ?? 26;
  final pvPower = latestDesign?.requiredPvPowerWc ?? 14300;
  final efficiency = latestDesign?.globalEfficiency ?? site.systemEfficiency;
  final theoreticalEnergy =
      pvPower * site.solarIrradiationHours * efficiency / 1000;
  final performanceRatio = theoreticalEnergy > 0
      ? inputs.measuredDailyEnergyKwh / theoreticalEnergy
      : 0.0;
  final voltageDelta =
      (inputs.measuredBatteryVoltage - inputs.expectedBatteryVoltage).abs();
  final batteryStatus = voltageDelta <= 2 ? 'Normal' : 'A verifier';
  final criticalLoad =
      latestDesign?.totalPowerWatts ??
      EquipmentItem.demoItems().fold<double>(
        0,
        (sum, item) => sum + item.powerWatts * item.quantity,
      );
  final optimizedLoad =
      criticalLoad * (1 - inputs.smartSleepSavingsPercent / 100);
  final alerts = <String>[
    if (performanceRatio < 0.75)
      'Performance faible: verifier ombrage, poussiere, cablage ou MPPT.',
    if (performanceRatio > 1.15)
      'Production mesuree atypique: verifier les donnees saisies.',
    if (batteryStatus != 'Normal')
      'Tension batterie hors tolerance: inspecter banc batterie et connexions.',
  ];
  return ImplementationResult(
    recommendedTiltDegrees: tilt,
    recommendedOrientation: orientation,
    theoreticalDailyEnergyKwh: theoreticalEnergy,
    performanceRatio: performanceRatio,
    energyGapKwh: inputs.measuredDailyEnergyKwh - theoreticalEnergy,
    batteryVoltageStatus: batteryStatus,
    optimizedLoadPowerWatts: optimizedLoad,
    installationChecklist: [
      "Verifier supports, ancrage mecanique et absence d'ombrage.",
      'Orienter les panneaux vers le $orientation et regler ${tilt.toStringAsFixed(1)} degres.',
      'Controler polarite DC, serrage, section de cable et chute de tension.',
      'Installer mise a la terre, parafoudre, disjoncteurs et fusibles.',
      'Etiqueter PV, batteries, regulateur, onduleur et charges critiques.',
      'Documenter photos, mesures initiales et numero de serie des composants.',
    ],
    testProtocol: [
      'Mesurer tension/courant PV a vide et en charge.',
      'Comparer production mesuree et production theorique sur 24h.',
      'Tester bascule batterie/onduleur et autonomie minimale.',
      'Verifier priorite BTS, routeur, switch et transmission.',
      'Activer supervision distante et seuils d alerte.',
    ],
    operationalRecommendations: [
      'Configurer mise en veille intelligente des charges non critiques.',
      'Suivre le performance ratio pendant 7 jours avant validation finale.',
      'Programmer inspection apres la premiere semaine de fonctionnement.',
      if (panelCount > 20)
        'Grand champ PV: renforcer inspection structure/supports.',
    ],
    alerts: alerts.isEmpty ? ['Aucune alerte critique detectee.'] : alerts,
  );
}

FeasibilityResult calculateFeasibility(
  SiteProfile site,
  List<EquipmentItem> equipment,
  FeasibilityInputs inputs,
) {
  final dailyEnergyWh = equipment.fold<double>(
    0,
    (sum, item) => sum + item.powerWatts * item.quantity * item.hoursPerDay,
  );
  final annualEnergyKwh = dailyEnergyWh * 365 / 1000;
  final annualDieselLiters = annualEnergyKwh * inputs.dieselLitersPerKwh;
  final annualDieselOpex =
      annualDieselLiters * inputs.dieselPricePerLiter * inputs.logisticsFactor +
      inputs.generatorMaintenancePerYear;
  final dieselTco = annualDieselOpex * inputs.studyYears;
  final solarTco =
      inputs.solarCapex + inputs.solarOpexPerYear * inputs.studyYears;
  final annualSavings = max(0, annualDieselOpex - inputs.solarOpexPerYear);
  final paybackYears = annualSavings > 0
      ? inputs.solarCapex / annualSavings
      : null;
  final co2Avoided = annualDieselLiters * inputs.co2KgPerLiter;
  var score = 40;
  if (inputs.averageGhiKwhM2Day >= 4.5) score += 20;
  if (annualSavings > 0) score += 20;
  if (paybackYears != null && paybackYears <= 5) score += 10;
  if (solarTco < dieselTco) score += 10;
  score = min(score, 100);
  final recommendations = <String>[
    'Valider les charges BTS/IP sur une semaine type.',
    'Confirmer le GHI mensuel de ${site.city} avant achat materiel.',
    'Comparer CAPEX solaire et OPEX diesel sur ${inputs.studyYears} ans.',
    if (inputs.averageGhiKwhM2Day < 4)
      'GHI faible: prevoir une marge PV ou une hybridation.',
    if (paybackYears != null && paybackYears > 7)
      'ROI long: optimiser cout panneaux/batteries ou maintenance.',
    if (co2Avoided > 10000)
      'Fort potentiel CO2 a valoriser dans le rapport RSE.',
  ];
  return FeasibilityResult(
    annualEnergyKwh: annualEnergyKwh,
    annualDieselLiters: annualDieselLiters,
    annualDieselOpex: annualDieselOpex,
    dieselTco: dieselTco,
    solarTco: solarTco,
    annualSavings: annualSavings.toDouble(),
    paybackYears: paybackYears,
    co2AvoidedKgPerYear: co2Avoided,
    feasibilityScore: score,
    verdict: score >= 70 ? 'Favorable' : 'A approfondir',
    recommendations: recommendations,
  );
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
  final lossFactor =
      1 -
      (inputs.wiringLossPercent +
              inputs.temperatureLossPercent +
              inputs.dustLossPercent) /
          100;
  final globalEfficiency = max(
    0.1,
    site.systemEfficiency *
        lossFactor *
        inputs.mpptEfficiency *
        inputs.inverterEfficiency,
  );
  final correctedEnergy = dailyEnergy / globalEfficiency;
  final pvPower =
      correctedEnergy / site.solarIrradiationHours * inputs.safetyFactor;
  final panels = max(1, (pvPower / inputs.panelPowerWatts).ceil());
  final batteryWh = dailyEnergy * site.autonomyDays;
  final batteryAh = (batteryWh / site.systemVoltage) / inputs.batteryDod;
  final batteries = max(1, (batteryAh / inputs.batteryCapacityAh).ceil());
  final controller = (pvPower / site.systemVoltage) * inputs.safetyFactor;
  final inverter = totalPower * inputs.safetyFactor;
  final totalCost =
      panels * inputs.panelUnitPrice +
      batteries * inputs.batteryUnitPrice +
      inputs.inverterPrice +
      inputs.controllerPrice +
      inputs.accessoriesPrice +
      inputs.laborPrice +
      inputs.maintenancePrice;
  final recommendations = <String>[
    "Technologie panneau: ${inputs.panelTechnology}.",
    "Technologie batterie: ${inputs.batteryTechnology}.",
    "Regulateur recommande: ${inputs.controllerType}.",
    "Prevoir un EMS pour prioriser les charges BTS/IP critiques.",
    if (dailyEnergy > 30000)
      "Consommation elevee: optimiser les equipements telecom.",
    if (inputs.controllerType != 'MPPT')
      "Passer en MPPT pour maximiser l'extraction d'energie.",
    if (inputs.batteryTechnology == 'Plomb-acide' && inputs.batteryDod > 0.5)
      "Pour le plomb-acide, limiter le DOD a 50%.",
    if (site.autonomyDays > 3)
      "Autonomie superieure a 3 jours: cout fortement accru.",
    if (site.systemEfficiency < 0.7)
      "Rendement faible: choisir des composants de meilleure qualite.",
    if (pvPower > 10000)
      "Puissance PV superieure a 10 kWc: etude technique detaillee recommandee.",
    if (batteryAh > 1200)
      "Batteries importantes: envisager une solution hybride solaire + groupe.",
  ];
  final protections = <String>[
    'Disjoncteur DC entre champ PV et regulateur',
    'Fusibles batterie dimensionnes au courant maximal',
    'Parafoudre DC/AC et mise a la terre',
    'Section de cable limitee a ${inputs.wiringLossPercent.toStringAsFixed(1)}% de pertes',
  ];
  final architecture = site.systemVoltage >= 48
      ? 'PV + batteries + regulateur ${inputs.controllerType} + bus DC 48V + onduleur secouru'
      : 'PV + batteries + regulateur ${inputs.controllerType} + onduleur AC';

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
    globalEfficiency: globalEfficiency,
    selectedArchitecture: architecture,
    protections: protections,
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
          MaterialPageRoute(builder: (_) => const LandingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [appGreenDark, appGreen, Color(0xFF6FBF73)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.solar_power,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'GreenSite PV Simulator',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dimensionnement photovoltaique telecom',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [landingForest, landingForestMid, landingForestDeep],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(28, compact ? 18 : 34, 28, 24),
                    children: [
                      const _LandingLogo(),
                      SizedBox(height: compact ? 26 : 44),
                      Text(
                        'Gerez vos installations\nphotovoltaiques en\ntoute simplicite',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: compact ? 25 : 29,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Suivez la performance de vos centrales,\nanalysez votre production et optimisez\nvotre energie solaire.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: compact ? 22 : 34),
                      const _SolarLandingIllustration(),
                      SizedBox(height: compact ? 26 : 38),
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: landingGreen,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: landingGreen),
                        ),
                        child: const Text('Creer un compte'),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiscoverScreen(),
                          ),
                        ),
                        child: Text(
                          'Decouvrir GreenSite PV',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingLogo extends StatelessWidget {
  const _LandingLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          height: 40,
          child: CustomPaint(painter: _SolarMarkPainter()),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            children: [
              TextSpan(text: 'greensite '),
              TextSpan(
                text: 'PV',
                style: TextStyle(
                  color: landingGreenLight,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SolarLandingIllustration extends StatelessWidget {
  const _SolarLandingIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 250,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 18,
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2C849),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 4,
              child: Icon(
                Icons.eco,
                color: const Color(0xFF5EA244).withValues(alpha: 0.85),
                size: 74,
              ),
            ),
            Positioned(
              right: 18,
              bottom: 8,
              child: Transform.rotate(
                angle: -0.4,
                child: Icon(
                  Icons.eco,
                  color: const Color(0xFF74B94F).withValues(alpha: 0.9),
                  size: 68,
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.75),
                child: Container(
                  width: 170,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5B86A7), Color(0xFF1D4A70)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: CustomPaint(painter: _PanelGridPainter()),
                ),
              ),
            ),
            Positioned(
              bottom: 5,
              left: 92,
              child: Container(width: 8, height: 32, color: Color(0xFF7A8790)),
            ),
            Positioned(
              bottom: 5,
              right: 88,
              child: Container(width: 8, height: 36, color: Color(0xFF7A8790)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolarMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint = Paint()
      ..color = const Color(0xFFF2C849)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final panelPaint = Paint()
      ..color = const Color(0xFFE8FFF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final sunCenter = Offset(size.width * 0.36, size.height * 0.26);
    canvas.drawArc(
      Rect.fromCircle(center: sunCenter, radius: 10),
      pi,
      pi,
      false,
      sunPaint,
    );
    for (final ray in [
      const Offset(-14, -2),
      const Offset(-9, -11),
      const Offset(0, -16),
      const Offset(9, -11),
      const Offset(14, -2),
    ]) {
      canvas.drawLine(sunCenter + ray, sunCenter + ray * 1.25, sunPaint);
    }

    final panel = Path()
      ..moveTo(size.width * 0.18, size.height * 0.58)
      ..lineTo(size.width * 0.72, size.height * 0.58)
      ..lineTo(size.width * 0.86, size.height * 0.92)
      ..lineTo(size.width * 0.04, size.height * 0.92)
      ..close();
    canvas.drawPath(panel, panelPaint);
    for (final x in [0.27, 0.43, 0.59, 0.75]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.58),
        Offset(size.width * (x - 0.12), size.height * 0.92),
        panelPaint,
      );
    }
    for (final y in [0.69, 0.81]) {
      canvas.drawLine(
        Offset(size.width * 0.11, size.height * y),
        Offset(size.width * 0.81, size.height * y),
        panelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PanelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: landingForestDeep,
        foregroundColor: Colors.white,
        title: const Text(
          'Decouvrir GreenSite PV',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [landingForestDeep, landingForestMid, landingForestDeep],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const _LandingLogo(),
                  const SizedBox(height: 24),
                  _DiscoverTile(
                    icon: Icons.solar_power,
                    title: 'Dimensionnement PV',
                    text:
                        'Estimez panneaux, batteries, regulateur, onduleur et protections pour un site telecom.',
                  ),
                  _DiscoverTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Audit de faisabilite',
                    text:
                        'Comparez solaire et diesel avec TCO, retour sur investissement et CO2 evite.',
                  ),
                  _DiscoverTile(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Suivi maintenance',
                    text:
                        'Analysez disponibilite, sante batterie, inspections, nettoyage et alertes.',
                  ),
                  _DiscoverTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Administration',
                    text:
                        'Supervisez utilisateurs, sites, clients et donnees lorsque vous etes connecte en admin.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: landingGreen),
                    ),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Creer un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: landingGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: landingGreenLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    try {
      await AppScope.of(context).login(email.text.trim(), password.text);
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
  String role = 'student';
  bool loading = false;

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
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'student',
              icon: Icon(Icons.school_outlined),
              label: Text('Etudiant'),
            ),
            ButtonSegment(
              value: 'admin',
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: Text('Admin'),
            ),
          ],
          selected: {role},
          onSelectionChanged: (values) => setState(() => role = values.first),
        ),
        FilledButton.icon(
          onPressed: loading ? null : () async => _submit(context),
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt),
          label: const Text('Creer le compte'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => loading = true);
    try {
      await AppScope.of(context).register(
        name.text.trim(),
        email.text.trim(),
        password.text,
        role: role,
      );
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF6EF), appBackground],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: appGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.solar_power,
                      color: appGreenDark,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: appNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: appMutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
          ),
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
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final pages = [
      const DashboardScreen(),
      const ManagementMenuScreen(),
      const StudiesMenuScreen(),
      const OperationsMenuScreen(),
      const ProfileScreen(),
    ];
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Tableau',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_open_outlined),
        selectedIcon: Icon(Icons.folder_open),
        label: 'Gestion',
      ),
      NavigationDestination(
        icon: Icon(Icons.calculate_outlined),
        selectedIcon: Icon(Icons.calculate),
        label: 'Etudes',
      ),
      NavigationDestination(
        icon: Icon(Icons.monitor_heart_outlined),
        selectedIcon: Icon(Icons.monitor_heart),
        label: 'Suivi',
      ),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
    ];

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 18),
                child: _AppMark(),
              ),
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, color: Color(0xFFDDE7E2)),
            Expanded(child: pages[index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: destinations,
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: appGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.solar_power, color: appGreenDark),
    );
  }
}

class ManagementMenuScreen extends StatelessWidget {
  const ManagementMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Gestion',
      children: [
        InfoCard(
          icon: Icons.groups_outlined,
          title: 'Clients',
          subtitle: 'Profils client, contacts et informations de projet',
          lines: ['${state.clients.length} clients'],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ClientsScreen())),
        ),
        InfoCard(
          icon: Icons.cell_tower_outlined,
          title: 'Sites telecom',
          subtitle: 'Sites BTS, localisation et parametres solaires',
          lines: [
            '${state.sites.length} sites',
            '${state.equipment.length} equipements',
          ],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SitesScreen())),
        ),
      ],
    );
  }
}

class StudiesMenuScreen extends StatelessWidget {
  const StudiesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Etudes',
      children: [
        InfoCard(
          icon: Icons.fact_check_outlined,
          title: 'Audit de faisabilite',
          subtitle: 'Comparer diesel et solaire avant conception',
          lines: const ['TCO', 'ROI', 'CO2'],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AuditScreen())),
        ),
        InfoCard(
          icon: Icons.calculate_outlined,
          title: 'Conception PV',
          subtitle: 'Dimensionner panneaux, batteries et protections',
          lines: const ['PV', 'Batteries', 'Couts'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SimulationScreen(asPage: true),
            ),
          ),
        ),
        InfoCard(
          icon: Icons.engineering_outlined,
          title: 'Implementation',
          subtitle: 'Valider les mesures terrain et la performance',
          lines: const ['PR', 'Checklist', 'Tests'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ImplementationScreen()),
          ),
        ),
      ],
    );
  }
}

class OperationsMenuScreen extends StatelessWidget {
  const OperationsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Suivi',
      children: [
        InfoCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Maintenance',
          subtitle: 'Sante batterie, nettoyage et inspections',
          lines: const ['Disponibilite', 'Sante', 'Alertes'],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
        ),
        InfoCard(
          icon: Icons.history,
          title: 'Historique',
          subtitle: 'Consulter les simulations deja enregistrees',
          lines: ['${state.simulations.length} simulations'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HistoryScreen(asPage: true),
            ),
          ),
        ),
      ],
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
        if (state.syncing) const LinearProgressIndicator(),
        InfoCard(
          icon: Icons.cloud_done_outlined,
          title: state.syncStatus,
          subtitle: state.api.baseUrl,
          lines: [
            '${state.clients.length} clients',
            '${state.sites.length} sites',
            '${state.equipment.length} equipements',
          ],
        ),
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

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final ghi = TextEditingController(text: '5');
  final dieselRate = TextEditingController(text: '0.35');
  final dieselPrice = TextEditingController(text: '1.5');
  final generatorMaintenance = TextEditingController(text: '1200');
  final solarCapex = TextEditingController(text: '6500');
  final solarOpex = TextEditingController(text: '350');
  final years = TextEditingController(text: '20');
  final logistics = TextEditingController(text: '115');
  FeasibilityResult? result;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dailyEnergy = state.equipment.fold<double>(
      0,
      (sum, item) => sum + item.powerWatts * item.quantity * item.hoursPerDay,
    );
    return AppPage(
      title: 'Audit faisabilite',
      action: IconButton(
        tooltip: 'Recalculer',
        onPressed: () => _calculate(state),
        icon: const Icon(Icons.refresh),
      ),
      children: [
        InfoCard(
          icon: Icons.electrical_services,
          title: 'Profil de charge actuel',
          subtitle: state.activeSite.name,
          lines: [
            '${state.equipment.length} equipements',
            '${(dailyEnergy / 1000).toStringAsFixed(2)} kWh/jour',
            '${state.activeSite.operatingHoursPerDay.toStringAsFixed(0)} h/jour',
          ],
        ),
        SectionTitle('Gisement solaire et diesel'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: ghi,
                label: 'GHI kWh/m2/j',
                icon: Icons.wb_sunny_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: dieselRate,
                label: 'L diesel/kWh',
                icon: Icons.local_gas_station_outlined,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: dieselPrice,
                label: 'Prix diesel USD/L',
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: logistics,
                label: 'Logistique %',
                icon: Icons.local_shipping_outlined,
              ),
            ),
          ],
        ),
        SectionTitle('Comparaison TCO'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: solarCapex,
                label: 'CAPEX solaire USD',
                icon: Icons.solar_power,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: solarOpex,
                label: 'OPEX solaire/an',
                icon: Icons.build_outlined,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: generatorMaintenance,
                label: 'Maintenance diesel/an',
                icon: Icons.engineering_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: years,
                label: 'Periode annees',
                icon: Icons.timeline,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _calculate(state),
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Analyser la faisabilite'),
        ),
        if (result != null) FeasibilityGrid(result: result!),
        if (result != null)
          InfoCard(
            icon: Icons.verified_outlined,
            title: 'Verdict: ${result!.verdict}',
            subtitle: 'Score de faisabilite ${result!.feasibilityScore}/100',
            lines: [
              'ROI: ${result!.paybackYears?.toStringAsFixed(1) ?? '-'} ans',
              'CO2 evite: ${(result!.co2AvoidedKgPerYear / 1000).toStringAsFixed(1)} t/an',
            ],
          ),
        if (result != null) SectionTitle('Recommandations Phase 1'),
        if (result != null)
          for (final item in result!.recommendations)
            InfoCard(
              icon: Icons.check_circle_outline,
              title: item,
              subtitle: '',
              lines: const [],
            ),
      ],
    );
  }

  void _calculate(AppState state) {
    setState(() {
      result = state.runFeasibility(
        FeasibilityInputs(
          averageGhiKwhM2Day: readDouble(ghi, 5),
          dieselLitersPerKwh: readDouble(dieselRate, 0.35),
          dieselPricePerLiter: readDouble(dieselPrice, 1.5),
          generatorMaintenancePerYear: readDouble(generatorMaintenance, 1200),
          solarCapex: readDouble(solarCapex, 6500),
          solarOpexPerYear: readDouble(solarOpex, 350),
          studyYears: readDouble(years, 20).round(),
          logisticsFactor: readDouble(logistics, 115) / 100,
        ),
      );
    });
  }
}

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Clients',
      action: IconButton(
        tooltip: 'Ajouter client',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ClientFormScreen())),
        icon: const Icon(Icons.person_add_alt),
      ),
      children: [
        for (final client in state.clients)
          InfoCard(
            icon: Icons.business_center_outlined,
            title: client.name,
            subtitle: client.organization,
            lines: [
              if (client.phone.isNotEmpty) client.phone,
              if (client.email.isNotEmpty) client.email,
              if (client.address.isNotEmpty) client.address,
            ],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ClientFormScreen(existing: client),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Supprimer',
              onPressed: () => state.deleteClient(client),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({this.existing, super.key});

  final ClientProfile? existing;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  late final TextEditingController name;
  late final TextEditingController organization;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController address;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final client = widget.existing ?? ClientProfile.demo();
    name = TextEditingController(text: client.name);
    organization = TextEditingController(text: client.organization);
    phone = TextEditingController(text: client.phone);
    email = TextEditingController(text: client.email);
    address = TextEditingController(text: client.address);
    notes = TextEditingController(text: client.notes);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return AppPage(
      title: editing ? 'Modifier client' : 'Nouveau client',
      showBack: true,
      children: [
        AppTextField(
          controller: name,
          label: 'Nom client',
          icon: Icons.person_outline,
        ),
        AppTextField(
          controller: organization,
          label: 'Organisation',
          icon: Icons.business_outlined,
        ),
        AppTextField(
          controller: phone,
          label: 'Telephone',
          icon: Icons.call_outlined,
        ),
        AppTextField(
          controller: email,
          label: 'Email',
          icon: Icons.mail_outline,
        ),
        AppTextField(
          controller: address,
          label: 'Adresse',
          icon: Icons.location_on_outlined,
        ),
        AppTextField(controller: notes, label: 'Notes', icon: Icons.notes),
        FilledButton.icon(
          onPressed: () async {
            final client = ClientProfile(
              id: widget.existing?.id,
              name: name.text,
              organization: organization.text,
              phone: phone.text,
              email: email.text,
              address: address.text,
              notes: notes.text,
            );
            if (editing) {
              await AppScope.of(context).updateClient(widget.existing!, client);
            } else {
              await AppScope.of(context).addClient(client);
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: Icon(editing ? Icons.save_outlined : Icons.add),
          label: Text(editing ? 'Enregistrer' : 'Ajouter'),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Modifier',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SiteFormScreen(existing: site),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: () => state.deleteSite(site),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
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
    final state = AppScope.of(context);
    final equipment = state.equipment;
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
            trailing: IconButton(
              tooltip: 'Supprimer',
              onPressed: () => state.removeEquipment(item),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}

class SiteFormScreen extends StatefulWidget {
  const SiteFormScreen({this.existing, super.key});

  final SiteProfile? existing;

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  late final TextEditingController name;
  late final TextEditingController city;
  late final TextEditingController country;
  late final TextEditingController type;
  late final TextEditingController description;
  late final TextEditingController autonomy;
  late final TextEditingController irradiation;
  late final TextEditingController efficiency;
  late int voltage;

  @override
  void initState() {
    super.initState();
    final site = widget.existing ?? SiteProfile.demo();
    name = TextEditingController(text: site.name);
    city = TextEditingController(text: site.city);
    country = TextEditingController(text: site.country);
    type = TextEditingController(text: site.siteType);
    description = TextEditingController(text: site.description);
    autonomy = TextEditingController(
      text: site.autonomyDays.toStringAsFixed(0),
    );
    irradiation = TextEditingController(
      text: site.solarIrradiationHours.toStringAsFixed(0),
    );
    efficiency = TextEditingController(
      text: (site.systemEfficiency * 100).toStringAsFixed(0),
    );
    voltage = site.systemVoltage;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.existing == null ? 'Creation site' : 'Modifier site',
      showBack: true,
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
          onPressed: () async {
            final site = SiteProfile(
              id: widget.existing?.id,
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
            );
            if (widget.existing == null) {
              await AppScope.of(context).addSite(site);
            } else {
              await AppScope.of(context).updateSite(widget.existing!, site);
            }
            if (context.mounted) Navigator.of(context).pop();
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
          onPressed: () async {
            await AppScope.of(context).addEquipment(
              EquipmentItem(
                name: name.text.isEmpty ? category : name.text,
                category: category,
                powerWatts: readDouble(power, 100),
                quantity: readDouble(quantity, 1).round(),
                hoursPerDay: readDouble(hours, 24),
              ),
            );
            if (context.mounted) Navigator.of(context).pop();
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
  final mpptEfficiency = TextEditingController(text: '96');
  final wiringLoss = TextEditingController(text: '3');
  final temperatureLoss = TextEditingController(text: '5');
  final dustLoss = TextEditingController(text: '3');
  final inverterEfficiency = TextEditingController(text: '93');
  final safetyFactor = TextEditingController(text: '125');
  final panelPrice = TextEditingController(text: '150');
  final batteryPrice = TextEditingController(text: '250');
  final inverter = TextEditingController(text: '500');
  final controller = TextEditingController(text: '300');
  final accessories = TextEditingController(text: '400');
  final labor = TextEditingController(text: '500');
  String panelTechnology = 'Monocristallin';
  String batteryTechnology = 'LiFePO4';
  String controllerType = 'MPPT';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Conception PV',
      showBack: widget.asPage,
      children: [
        SectionTitle('Choix technologiques'),
        DropdownButtonFormField<String>(
          initialValue: panelTechnology,
          decoration: const InputDecoration(
            labelText: 'Technologie panneau',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.solar_power),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Monocristallin',
              child: Text('Monocristallin'),
            ),
            DropdownMenuItem(
              value: 'Polycristallin',
              child: Text('Polycristallin'),
            ),
            DropdownMenuItem(value: 'Bifacial', child: Text('Bifacial')),
          ],
          onChanged: (value) =>
              setState(() => panelTechnology = value ?? panelTechnology),
        ),
        DropdownButtonFormField<String>(
          initialValue: batteryTechnology,
          decoration: const InputDecoration(
            labelText: 'Technologie batterie',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.battery_charging_full),
          ),
          items: const [
            DropdownMenuItem(value: 'LiFePO4', child: Text('LiFePO4')),
            DropdownMenuItem(
              value: 'Plomb-carbone',
              child: Text('Plomb-carbone'),
            ),
            DropdownMenuItem(value: 'Plomb-acide', child: Text('Plomb-acide')),
          ],
          onChanged: (value) =>
              setState(() => batteryTechnology = value ?? batteryTechnology),
        ),
        DropdownButtonFormField<String>(
          initialValue: controllerType,
          decoration: const InputDecoration(
            labelText: 'Regulateur',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.settings_input_component),
          ),
          items: const [
            DropdownMenuItem(value: 'MPPT', child: Text('MPPT')),
            DropdownMenuItem(value: 'PWM', child: Text('PWM')),
          ],
          onChanged: (value) =>
              setState(() => controllerType = value ?? controllerType),
        ),
        SectionTitle('Dimensionnement materiel'),
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
        SectionTitle('Pertes et marges'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: mpptEfficiency,
                label: 'Rendement MPPT %',
                icon: Icons.speed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: inverterEfficiency,
                label: 'Rend. onduleur %',
                icon: Icons.power,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: wiringLoss,
                label: 'Pertes cables %',
                icon: Icons.cable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: temperatureLoss,
                label: 'Pertes temperature %',
                icon: Icons.thermostat,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: dustLoss,
                label: 'Pertes poussiere %',
                icon: Icons.blur_on,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: safetyFactor,
                label: 'Marge securite %',
                icon: Icons.health_and_safety_outlined,
              ),
            ),
          ],
        ),
        SectionTitle('Couts unitaires'),
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
                panelTechnology: panelTechnology,
                batteryCapacityAh: readDouble(batteryAh, 200),
                batteryVoltage: readDouble(batteryVoltage, 12),
                batteryTechnology: batteryTechnology,
                batteryDod: readDouble(dod, 80) / 100,
                controllerType: controllerType,
                mpptEfficiency: readDouble(mpptEfficiency, 96) / 100,
                wiringLossPercent: readDouble(wiringLoss, 3),
                temperatureLossPercent: readDouble(temperatureLoss, 5),
                dustLossPercent: readDouble(dustLoss, 3),
                inverterEfficiency: readDouble(inverterEfficiency, 93) / 100,
                safetyFactor: readDouble(safetyFactor, 125) / 100,
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
        InfoCard(
          icon: Icons.account_tree_outlined,
          title: 'Architecture recommandee',
          subtitle: r.selectedArchitecture,
          lines: [
            'Rendement global ${(r.globalEfficiency * 100).toStringAsFixed(1)}%',
          ],
        ),
        SectionTitle('Protections electriques'),
        for (final protection in r.protections)
          InfoCard(
            icon: Icons.shield_outlined,
            title: protection,
            subtitle: '',
            lines: const [],
          ),
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

class ImplementationScreen extends StatefulWidget {
  const ImplementationScreen({super.key});

  @override
  State<ImplementationScreen> createState() => _ImplementationScreenState();
}

class _ImplementationScreenState extends State<ImplementationScreen> {
  final latitude = TextEditingController(text: '-1.68');
  final measuredEnergy = TextEditingController(text: '50');
  final measuredVoltage = TextEditingController(text: '48');
  final expectedVoltage = TextEditingController(text: '48');
  final sleepSavings = TextEditingController(text: '8');
  ImplementationResult? result;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final latestDesign = state.simulations.isEmpty
        ? null
        : state.simulations.first.result;
    return AppPage(
      title: 'Implementation',
      action: IconButton(
        tooltip: 'Valider',
        onPressed: () => _validate(state, latestDesign),
        icon: const Icon(Icons.task_alt),
      ),
      children: [
        InfoCard(
          icon: Icons.cell_tower,
          title: state.activeSite.name,
          subtitle: 'Validation terrain Phase 3',
          lines: [
            if (latestDesign != null)
              '${latestDesign.numberOfPanels} panneaux dimensionnes',
            '${state.activeSite.solarIrradiationHours} h soleil/jour',
            '${state.activeSite.systemVoltage} V systeme',
          ],
        ),
        SectionTitle('Orientation et mesures terrain'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: latitude,
                label: 'Latitude',
                icon: Icons.explore_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: measuredEnergy,
                label: 'Prod. mesuree kWh/j',
                icon: Icons.monitor_heart_outlined,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: measuredVoltage,
                label: 'Tension batt. mesuree',
                icon: Icons.battery_unknown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: expectedVoltage,
                label: 'Tension attendue',
                icon: Icons.battery_full,
              ),
            ),
          ],
        ),
        AppTextField(
          controller: sleepSavings,
          label: 'Gain veille intelligente %',
          icon: Icons.nightlight_round,
        ),
        FilledButton.icon(
          onPressed: () => _validate(state, latestDesign),
          icon: const Icon(Icons.rule),
          label: const Text('Valider installation'),
        ),
        if (result != null) ImplementationGrid(result: result!),
        if (result != null)
          InfoCard(
            icon: Icons.compass_calibration_outlined,
            title: 'Orientation recommandee',
            subtitle:
                '${result!.recommendedOrientation}, inclinaison ${result!.recommendedTiltDegrees.toStringAsFixed(1)} degres',
            lines: [
              'PR ${(result!.performanceRatio * 100).toStringAsFixed(1)}%',
              'Ecart ${result!.energyGapKwh.toStringAsFixed(1)} kWh',
              'Batterie ${result!.batteryVoltageStatus}',
            ],
          ),
        if (result != null) SectionTitle('Checklist installation'),
        if (result != null)
          for (final item in result!.installationChecklist)
            InfoCard(
              icon: Icons.check_box_outlined,
              title: item,
              subtitle: '',
              lines: const [],
            ),
        if (result != null) SectionTitle('Protocole de tests'),
        if (result != null)
          for (final item in result!.testProtocol)
            InfoCard(
              icon: Icons.science_outlined,
              title: item,
              subtitle: '',
              lines: const [],
            ),
        if (result != null) SectionTitle('Alertes et optimisation'),
        if (result != null)
          for (final alert in result!.alerts)
            InfoCard(
              icon: Icons.warning_amber_outlined,
              title: alert,
              subtitle: '',
              lines: const [],
            ),
        if (result != null)
          for (final item in result!.operationalRecommendations)
            InfoCard(
              icon: Icons.tune_outlined,
              title: item,
              subtitle: '',
              lines: const [],
            ),
      ],
    );
  }

  void _validate(AppState state, SimulationResult? latestDesign) {
    setState(() {
      result = state.runImplementation(
        ImplementationInputs(
          latitude: readDouble(latitude, -1.68),
          measuredDailyEnergyKwh: readDouble(measuredEnergy, 50),
          measuredBatteryVoltage: readDouble(measuredVoltage, 48),
          expectedBatteryVoltage: readDouble(expectedVoltage, 48),
          smartSleepSavingsPercent: readDouble(sleepSavings, 8),
        ),
        latestDesign,
      );
    });
  }
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final availability = TextEditingController(text: '99');
  final performance = TextEditingController(text: '85');
  final soc = TextEditingController(text: '80');
  final soh = TextEditingController(text: '92');
  final cycles = TextEditingController(text: '450');
  final cleaningDays = TextEditingController(text: '20');
  final inspectionDays = TextEditingController(text: '45');
  final dieselAvoided = TextEditingController(text: '4500');
  final sitesCount = TextEditingController(text: '1');
  MaintenanceResult? result;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Suivi maintenance',
      action: IconButton(
        tooltip: 'Evaluer',
        onPressed: () => _evaluate(state),
        icon: const Icon(Icons.refresh),
      ),
      children: [
        InfoCard(
          icon: Icons.assessment_outlined,
          title: 'KPI de suivi',
          subtitle: state.activeSite.name,
          lines: [
            'Disponibilite',
            'Performance ratio',
            'SOC/SOH batterie',
            'CO2 evite',
          ],
        ),
        SectionTitle('Indicateurs operationnels'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: availability,
                label: 'Disponibilite %',
                icon: Icons.cloud_done_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: performance,
                label: 'Performance ratio %',
                icon: Icons.speed,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: soc,
                label: 'SOC batterie %',
                icon: Icons.battery_5_bar,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: soh,
                label: 'SOH batterie %',
                icon: Icons.battery_charging_full,
              ),
            ),
          ],
        ),
        AppTextField(
          controller: cycles,
          label: 'Cycles batterie',
          icon: Icons.loop,
        ),
        SectionTitle('Maintenance preventive'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: cleaningDays,
                label: 'Jours depuis nettoyage',
                icon: Icons.cleaning_services_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: inspectionDays,
                label: 'Jours depuis inspection',
                icon: Icons.fact_check_outlined,
              ),
            ),
          ],
        ),
        SectionTitle('Valorisation'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: dieselAvoided,
                label: 'Diesel evite L/an',
                icon: Icons.local_gas_station_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: sitesCount,
                label: 'Sites generalisables',
                icon: Icons.hub_outlined,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _evaluate(state),
          icon: const Icon(Icons.monitor_heart_outlined),
          label: const Text('Evaluer le suivi'),
        ),
        if (result != null) MaintenanceGrid(result: result!),
        if (result != null)
          InfoCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Etat global ${result!.healthScore}/100',
            subtitle:
                'Disponibilite ${result!.availabilityStatus} - Energie ${result!.energyStatus} - Batterie ${result!.batteryStatus}',
            lines: [
              'CO2 ${(result!.co2AvoidedKgPerYear / 1000).toStringAsFixed(2)} t/an',
              'Reseau ${(result!.networkCo2PotentialKgPerYear / 1000).toStringAsFixed(2)} t/an',
            ],
          ),
        if (result != null) SectionTitle('Planning maintenance'),
        if (result != null)
          for (final task in result!.maintenanceTasks)
            InfoCard(
              icon: Icons.event_available_outlined,
              title: task,
              subtitle: '',
              lines: const [],
            ),
        if (result != null) SectionTitle('Alertes'),
        if (result != null)
          for (final alert in result!.alerts)
            InfoCard(
              icon: Icons.notification_important_outlined,
              title: alert,
              subtitle: '',
              lines: const [],
            ),
        if (result != null) SectionTitle('KPI mensuels'),
        if (result != null)
          for (final kpi in result!.kpis)
            InfoCard(
              icon: Icons.query_stats_outlined,
              title: kpi,
              subtitle: '',
              lines: const [],
            ),
        if (result != null) SectionTitle('Valorisation projet'),
        if (result != null)
          for (final point in result!.valorizationPoints)
            InfoCard(
              icon: Icons.eco_outlined,
              title: point,
              subtitle: '',
              lines: const [],
            ),
      ],
    );
  }

  void _evaluate(AppState state) {
    setState(() {
      result = state.runMaintenance(
        MaintenanceInputs(
          availabilityPercent: readDouble(availability, 99),
          performanceRatio: readDouble(performance, 85) / 100,
          batterySocPercent: readDouble(soc, 80),
          batterySohPercent: readDouble(soh, 92),
          batteryCycles: readDouble(cycles, 450).round(),
          daysSincePanelCleaning: readDouble(cleaningDays, 20).round(),
          daysSinceElectricalInspection: readDouble(inspectionDays, 45).round(),
          annualDieselLitersAvoided: readDouble(dieselAvoided, 4500),
          sitesReplicableCount: readDouble(sitesCount, 1).round(),
        ),
      );
    });
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({this.asPage = false, super.key});

  final bool asPage;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final simulations = state.simulations;
    return AppPage(
      title: 'Historique',
      showBack: asPage,
      action: simulations.isEmpty
          ? null
          : IconButton(
              tooltip: 'Vider',
              onPressed: state.clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
      children: [
        if (simulations.isEmpty)
          const InfoCard(
            icon: Icons.history,
            title: 'Aucune simulation sauvegardee',
            subtitle: "Lancez un calcul pour alimenter l'historique.",
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
            trailing: IconButton(
              tooltip: 'Supprimer',
              onPressed: () => state.deleteSimulation(simulation),
              icon: const Icon(Icons.delete_outline),
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
      showBack: true,
      action: IconButton(
        tooltip: 'Copier',
        onPressed: () => copyReport(context, record),
        icon: const Icon(Icons.copy_all_outlined),
      ),
      children: [
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
        InfoCard(
          icon: Icons.account_tree_outlined,
          title: 'Architecture retenue',
          subtitle: record.result.selectedArchitecture,
          lines: [
            'Rendement global ${(record.result.globalEfficiency * 100).toStringAsFixed(1)}%',
            record.inputs.panelTechnology,
            record.inputs.batteryTechnology,
          ],
        ),
        Text(
          'Protections',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        for (final protection in record.result.protections)
          Text('- $protection'),
        FilledButton.icon(
          onPressed: () => copyReport(context, record),
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Copier le rapport'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SimulationScreen(asPage: true),
            ),
          ),
          icon: const Icon(Icons.add_chart_outlined),
          label: const Text('Nouvelle simulation'),
        ),
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
        const ProfilePhotoCard(),
        InfoCard(
          icon: Icons.person,
          title: state.userName,
          subtitle: 'Role: ${state.isAdmin ? 'administrateur' : 'etudiant'}',
          lines: [
            'Mode API: ${state.token == null ? 'deconnecte' : 'connecte'}',
            state.userEmail,
            'Swagger backend: /docs',
          ],
        ),
        if (state.isAdmin)
          InfoCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Espace administrateur',
            subtitle: 'Supervision globale, utilisateurs et donnees API',
            lines: [
              '${state.adminUsers.length} utilisateurs',
              '${state.clients.length} clients',
              '${state.sites.length} sites',
            ],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            state.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LandingScreen()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Deconnexion'),
        ),
      ],
    );
  }
}

class ProfilePhotoCard extends StatelessWidget {
  const ProfilePhotoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final photo = state.profilePhotoBytes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: appGreen.withValues(alpha: 0.14),
              backgroundImage: photo == null ? null : MemoryImage(photo),
              child: photo == null
                  ? const Icon(Icons.person, color: appGreenDark, size: 42)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: appNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    state.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: appMutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: state.pickProfilePhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(photo == null ? 'Ajouter' : 'Modifier'),
                      ),
                      if (photo != null)
                        OutlinedButton.icon(
                          onPressed: state.removeProfilePhoto,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Retirer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final totalEquipmentPower = state.equipment.fold<double>(
      0,
      (sum, item) => sum + item.powerWatts * item.quantity,
    );
    return AppPage(
      title: 'Administration',
      showBack: true,
      action: IconButton(
        tooltip: 'Synchroniser',
        onPressed: () => state.syncFromApi(),
        icon: const Icon(Icons.sync),
      ),
      children: [
        if (!state.isAdmin)
          const InfoCard(
            icon: Icons.lock_outline,
            title: 'Acces reserve',
            subtitle: 'Connectez-vous avec un compte administrateur.',
            lines: [],
          ),
        if (state.isAdmin) ...[
          InfoCard(
            icon: Icons.cloud_done_outlined,
            title: 'API Render',
            subtitle: state.api.baseUrl,
            lines: [
              state.syncStatus,
              state.token == null ? 'Non authentifie' : 'Authentifie',
            ],
          ),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatCard(
                icon: Icons.people_alt_outlined,
                label: 'Utilisateurs',
                value: '${state.adminUsers.length}',
              ),
              StatCard(
                icon: Icons.business_center_outlined,
                label: 'Clients',
                value: '${state.clients.length}',
              ),
              StatCard(
                icon: Icons.cell_tower_outlined,
                label: 'Sites',
                value: '${state.sites.length}',
              ),
              StatCard(
                icon: Icons.bolt,
                label: 'Charge installee',
                value: '${totalEquipmentPower.toStringAsFixed(0)} W',
              ),
            ],
          ),
          InfoCard(
            icon: Icons.manage_accounts_outlined,
            title: 'Utilisateurs',
            subtitle: 'Consulter les comptes et leurs roles',
            lines: const ['admin', 'student'],
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
          ),
          InfoCard(
            icon: Icons.storage_outlined,
            title: 'Donnees metier',
            subtitle: 'Acces rapide aux clients, sites et simulations',
            lines: const ['Clients', 'Sites', 'Historique'],
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminDataScreen())),
          ),
          FilledButton.icon(
            onPressed: () => state.syncFromApi(),
            icon: const Icon(Icons.sync),
            label: const Text('Synchroniser avec Render'),
          ),
        ],
      ],
    );
  }
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final users = state.adminUsers.isEmpty
        ? [
            AdminUserProfile.demo(
              state.userName,
              state.userEmail,
              state.userRole,
            ),
          ]
        : state.adminUsers;
    return AppPage(
      title: 'Utilisateurs',
      showBack: true,
      action: IconButton(
        tooltip: 'Actualiser',
        onPressed: () => state.syncAdminData(),
        icon: const Icon(Icons.refresh),
      ),
      children: [
        for (final user in users)
          InfoCard(
            icon: user.role == 'admin'
                ? Icons.admin_panel_settings_outlined
                : Icons.school_outlined,
            title: user.name.isEmpty ? user.email : user.name,
            subtitle: user.email,
            lines: [
              'Role: ${user.role}',
              'Cree le ${shortDate(user.createdAt)}',
            ],
          ),
      ],
    );
  }
}

class AdminDataScreen extends StatelessWidget {
  const AdminDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AppPage(
      title: 'Donnees admin',
      showBack: true,
      children: [
        InfoCard(
          icon: Icons.groups_outlined,
          title: 'Clients',
          subtitle: 'Tous les clients visibles par le compte admin',
          lines: ['${state.clients.length} profils'],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ClientsScreen())),
        ),
        InfoCard(
          icon: Icons.cell_tower_outlined,
          title: 'Sites',
          subtitle: 'Inventaire global des sites telecom',
          lines: [
            '${state.sites.length} sites',
            '${state.equipment.length} equipements',
          ],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SitesScreen())),
        ),
        InfoCard(
          icon: Icons.history,
          title: 'Simulations',
          subtitle: 'Historique et rapports de dimensionnement',
          lines: ['${state.simulations.length} simulations locales'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HistoryScreen(asPage: true),
            ),
          ),
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
      (
        'Rendement global',
        '${(result.globalEfficiency * 100).toStringAsFixed(1)}%',
        Icons.speed,
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

class FeasibilityGrid extends StatelessWidget {
  const FeasibilityGrid({required this.result, super.key});

  final FeasibilityResult result;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Energie annuelle',
        '${result.annualEnergyKwh.toStringAsFixed(0)} kWh',
        Icons.bolt,
      ),
      (
        'Diesel/an',
        '${result.annualDieselLiters.toStringAsFixed(0)} L',
        Icons.local_gas_station,
      ),
      (
        'OPEX diesel/an',
        '${result.annualDieselOpex.toStringAsFixed(0)} USD',
        Icons.payments_outlined,
      ),
      (
        'TCO diesel',
        '${result.dieselTco.toStringAsFixed(0)} USD',
        Icons.trending_up,
      ),
      (
        'TCO solaire',
        '${result.solarTco.toStringAsFixed(0)} USD',
        Icons.solar_power,
      ),
      (
        'Economies/an',
        '${result.annualSavings.toStringAsFixed(0)} USD',
        Icons.savings_outlined,
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
        automaticallyImplyLeading: showBack || Navigator.of(context).canPop(),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [if (action != null) action!],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              itemBuilder: (_, index) => children[index],
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: children.length,
            ),
          ),
        ),
      ),
    );
  }
}

class ImplementationGrid extends StatelessWidget {
  const ImplementationGrid({required this.result, super.key});

  final ImplementationResult result;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Production theorique',
        '${result.theoreticalDailyEnergyKwh.toStringAsFixed(1)} kWh/j',
        Icons.solar_power,
      ),
      (
        'Performance ratio',
        '${(result.performanceRatio * 100).toStringAsFixed(1)}%',
        Icons.speed,
      ),
      (
        'Ecart energie',
        '${result.energyGapKwh.toStringAsFixed(1)} kWh',
        Icons.compare_arrows,
      ),
      (
        'Charge optimisee',
        '${result.optimizedLoadPowerWatts.toStringAsFixed(0)} W',
        Icons.energy_savings_leaf_outlined,
      ),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
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

class MaintenanceGrid extends StatelessWidget {
  const MaintenanceGrid({required this.result, super.key});

  final MaintenanceResult result;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Sante', '${result.healthScore}/100', Icons.health_and_safety_outlined),
      (
        'Nettoyage',
        '${result.nextPanelCleaningDays} j',
        Icons.cleaning_services_outlined,
      ),
      (
        'Inspection',
        '${result.nextElectricalInspectionDays} j',
        Icons.fact_check_outlined,
      ),
      (
        'CO2 evite',
        '${(result.co2AvoidedKgPerYear / 1000).toStringAsFixed(1)} t/an',
        Icons.eco_outlined,
      ),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
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

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: appNavy,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: appGreen.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: appGreenDark, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: appNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: appMutedText,
                fontWeight: FontWeight.w600,
              ),
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
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> lines;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: appGreen.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: appGreenDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: appNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: appMutedText,
                          fontWeight: FontWeight.w600,
                        ),
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
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
    );
  }
}

double readDouble(TextEditingController controller, double fallback) {
  return double.tryParse(controller.text.replaceAll(',', '.')) ?? fallback;
}

String shortDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Future<void> copyReport(BuildContext context, SimulationRecord record) async {
  await Clipboard.setData(ClipboardData(text: buildReportText(record)));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Rapport copie')));
}

String buildReportText(SimulationRecord record) {
  final result = record.result;
  final equipment = record.equipment
      .map(
        (item) =>
            '- ${item.name}: ${item.powerWatts.toStringAsFixed(0)} W x ${item.quantity}, ${item.hoursPerDay} h/jour',
      )
      .join('\n');
  final recommendations = result.recommendations
      .map((item) => '- $item')
      .join('\n');
  final protections = result.protections.map((item) => '- $item').join('\n');
  return '''
GreenSite PV Simulator

Site
${record.site.name}
${record.site.city}, ${record.site.country}
${record.site.siteType}

Choix technologiques
Panneau: ${record.inputs.panelTechnology}
Batterie: ${record.inputs.batteryTechnology}
Regulateur: ${record.inputs.controllerType}
Rendement global: ${(result.globalEfficiency * 100).toStringAsFixed(1)}%
Architecture: ${result.selectedArchitecture}

Equipements
$equipment

Resultats
Puissance totale: ${result.totalPowerWatts.toStringAsFixed(0)} W
Energie journaliere: ${(result.dailyEnergyWh / 1000).toStringAsFixed(2)} kWh/jour
Energie corrigee: ${(result.correctedEnergyWh / 1000).toStringAsFixed(2)} kWh/jour
Puissance PV: ${result.requiredPvPowerWc.toStringAsFixed(0)} Wc
Panneaux: ${result.numberOfPanels}
Batterie: ${result.requiredBatteryCapacityWh.toStringAsFixed(0)} Wh / ${result.requiredBatteryCapacityAh.toStringAsFixed(0)} Ah
Batteries: ${result.numberOfBatteries}
Regulateur: ${result.controllerCurrentA.toStringAsFixed(1)} A
Onduleur: ${result.inverterPowerWatts.toStringAsFixed(0)} W
Cout total: ${result.totalCost.toStringAsFixed(0)} USD

Protections
$protections

Recommandations
$recommendations
''';
}
