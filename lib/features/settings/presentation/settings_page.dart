import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_version.dart';
import '../../../core/widgets/balance_help_button.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/backup_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/somia_shell.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final directory = await getApplicationSupportDirectory();
      final bytes = await BackupService.export(getIt<AppDatabase>(), directory);
      final now = DateTime.now();
      final date = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final saved = await FilePicker.saveFile(
        fileName: 'somia-backup-$date.sqlite',
        bytes: bytes,
        mimeType: 'application/vnd.sqlite3',
      );
      if (mounted && saved != null) _message('Backup exportado com sucesso.');
    } catch (error) {
      if (mounted) _message('Não foi possível exportar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null || !mounted) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Restaurar backup?'),
              content: const Text(
                  'Na próxima abertura, os dados atuais serão substituídos. '
                  'Exporte um backup dos dados atuais antes de continuar.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Restaurar')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final directory = await getApplicationSupportDirectory();
      await BackupService.stageRestore(bytes, directory);
      if (mounted) {
        _message('Backup validado. Feche e abra o Somia para aplicar.');
      }
    } catch (error) {
      if (mounted) _message('Não foi possível restaurar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Ajustes'), leading: somiaMenuLeading(context)),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Somia',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  const Card(
                      child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Versão do aplicativo'),
                          subtitle: SelectableText(AppVersion.label))),
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Entender os saldos'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showBalanceHelp(context))),
                  const Card(
                      child: ListTile(
                          title: Text('Seus dados'),
                          subtitle: Text(
                              'As informações ficam armazenadas neste dispositivo.'))),
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.file_upload_outlined),
                          title: const Text('Exportar backup'),
                          subtitle: const Text(
                              'Salve uma cópia do banco local em outro lugar.'),
                          onTap: _busy ? null : _export)),
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.restore_outlined),
                          title: const Text('Restaurar backup'),
                          subtitle: const Text(
                              'Selecione um arquivo .sqlite e reinicie o aplicativo.'),
                          onTap: _busy ? null : _restore)),
                  if (_busy) const Center(child: CircularProgressIndicator()),
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: const Text('Categorias e subcategorias'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.goNamed(AppRoutes.categories))),
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: const Text('Transferências'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.goNamed(AppRoutes.transfers))),
                ]))),
      );
}
