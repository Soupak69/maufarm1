import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../provider/font_provider.dart';
import '../../provider/theme_provider.dart';
import '../../provider/contrast_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fontProvider = context.watch<FontScaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final contrastProvider = context.watch<ContrastProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language selector
          ListTile(
            title: Text('language'.tr()),
            trailing: DropdownButton<Locale>(
              value: context.locale,
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
              ],
              onChanged: (locale) async {
                if (locale != null) {
                  await context.setLocale(locale);
                  SemanticsService.announce(
                    locale.languageCode == 'en'
                        ? 'Language changed to English'
                        : 'Langue changée en Français',
                    Directionality.of(context),
                  );
                }
              },
            ),
          ),
          const Divider(),

          // Dark mode toggle
          Semantics(
            label: 'Dark mode toggle',
            toggled: themeProvider.isDarkMode,
            child: SwitchListTile(
              title: Text('dark_mode'.tr()),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
                SemanticsService.announce(
                  value ? 'Dark mode enabled' : 'Dark mode disabled',
                  Directionality.of(context),
                );
              },
            ),
          ),
          const Divider(),

          // Font size controls
          ListTile(
            title: Text('${'font_size'.tr()}: ${(fontProvider.scale * 100).toInt()}%'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Decrease font size',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      fontProvider.decrease();
                      SemanticsService.announce(
                        'Font size decreased to ${(fontProvider.scale * 100).toInt()} percent',
                        Directionality.of(context),
                      );
                    },
                  ),
                ),
                Semantics(
                  label: 'Increase font size',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      fontProvider.increase();
                      SemanticsService.announce(
                        'Font size increased to ${(fontProvider.scale * 100).toInt()} percent',
                        Directionality.of(context),
                      );
                    },
                  ),
                ),
                Semantics(
                  label: 'Reset font size',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      fontProvider.reset();
                      SemanticsService.announce(
                        'Font size reset to 100 percent',
                        Directionality.of(context),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Contrast slider
          Semantics(
            label: 'Contrast slider',
            value: '${(contrastProvider.contrast * 100).toInt()}%',
            increasedValue: '${(contrastProvider.contrast * 100 + 10).toInt()}%',
            decreasedValue: '${(contrastProvider.contrast * 100 - 10).toInt()}%',
            child: ListTile(
              title: Text('contrast'.tr()),
              subtitle: Slider(
                value: contrastProvider.contrast,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(contrastProvider.contrast * 100).toInt()}%',
                onChanged: (value) {
                  contrastProvider.setContrast(value);
                  SemanticsService.announce(
                    'Contrast adjusted to ${(value * 100).toInt()} percent',
                    Directionality.of(context),
                  );
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset contrast',
                onPressed: () {
                  contrastProvider.resetContrast();
                  SemanticsService.announce(
                    'Contrast reset to 100 percent',
                    Directionality.of(context),
                  );
                },
              ),
            ),
          ),
          const Divider(),

          // Screen reader status (optional - just for information)
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: Text('screen_reader'.tr()),
            subtitle: Text(
              MediaQuery.of(context).accessibleNavigation
                  ? 'screen_reader_active'.tr()
                  : 'screen_reader_inactive'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}