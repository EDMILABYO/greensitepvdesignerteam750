import 'package:flutter/material.dart';
import 'package:greensitepvdesignerteam750app/app/utils/colors.dart';
import 'package:greensitepvdesignerteam750app/app/screens/home/home_screen.dart';
import 'package:greensitepvdesignerteam750app/app/screens/auth/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 3
        : width >= 620
        ? 2
        : 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.solar_power, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  'GreenSite PV Designer',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Dimensionnez, analysez et optimisez vos projets solaires pour sites BTS isoles.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: crossAxisCount == 1 ? 4.4 : 3.1,
                    children: const [
                      _FeatureTile(
                        icon: Icons.solar_power,
                        title: 'Dimensionnement PV',
                        text: 'Calcul des panneaux selon la charge BTS.',
                      ),
                      _FeatureTile(
                        icon: Icons.battery_charging_full,
                        title: 'Batteries',
                        text: 'Capacite, autonomie et degradation integrees.',
                      ),
                      _FeatureTile(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Ensoleillement',
                        text: 'Variabilite saisonniere et rendement global.',
                      ),
                      _FeatureTile(
                        icon: Icons.payments_outlined,
                        title: 'Analyse TCO',
                        text: 'Comparaison solaire contre diesel traditionnel.',
                      ),
                      _FeatureTile(
                        icon: Icons.security_outlined,
                        title: 'Securite site',
                        text: 'Risques de vol, vandalisme et protections.',
                      ),
                      _FeatureTile(
                        icon: Icons.energy_savings_leaf_outlined,
                        title: 'Optimisation BTS',
                        text: 'Priorisation et reduction de la consommation.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Commencer'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'J\'ai deja un compte',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
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
