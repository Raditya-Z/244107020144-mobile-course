import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(const AcademicOverview());

class AcademicOverview extends StatefulWidget {
  const AcademicOverview({super.key});

  @override
  State<AcademicOverview> createState() => _AcademicOverviewState();
}

class _AcademicOverviewState extends State<AcademicOverview> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: false,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Academic Overview'),
        ),
        actions: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                label: 'Mode gelap',
                hint: 'Ketuk untuk mengaktifkan atau menonaktifkan mode gelap',
                toggled: isDark,
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;

          return Column(
            children: [
              // HEADER PROFIL
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 60,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Raditya Zandra Fadhillah'),
                          Text('244107020144'),
                          Text('Politeknik Negeri Malang'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // KARTU
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: const [
                    DashboardCard(title: 'Assignments', value: '8',),
                    DashboardCard(title: 'Attendance', value: '92%',),
                    DashboardCard(title: 'Portfolio', value: 'Ready',),
                    DashboardCard(title: 'GPA', value: '3.66',),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(title),
                ),
              ),
              ExcludeSemantics(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}