import 'package:file_explorer/app/app.dart';
import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/settings/data/repositories/in_memory_settings_store.dart';
import 'package:file_explorer/features/settings/data/repositories/settings_store_provider.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shortcut tiles follow theme accent after settings load',
      (tester) async {
    final store = InMemorySettingsStore();
    await store.saveString(SettingKey.themeAccent, AppThemeAccent.green.name);
    await store.saveString(SettingKey.themeMode, AppThemeMode.dark.name);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          storageRepositoryProvider.overrideWithValue(
            const FakeStorageRepository(),
          ),
          storagePermissionRepositoryProvider.overrideWithValue(
            const FakeStoragePermissionRepository(),
          ),
        ],
        child: const FileExplorerApp(),
      ),
    );

    Color iconColor() {
      // Storage header chip follows the loaded accent; shortcut tiles use
      // fixed kind colors by design (immune to stale-theme flash).
      final icon = tester.widget<Icon>(find.byIcon(Icons.phone_android_rounded));
      return icon.color!;
    }

    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    final expectedAccent = app.darkTheme!.colorScheme.primary;
    expect(
      iconColor(),
      expectedAccent,
      reason: 'accent-driven icons should switch from the default (purple) to '
          'the loaded accent (green) once settings finish loading',
    );
  });
}
