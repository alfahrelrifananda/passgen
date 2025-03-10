import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SaveTab extends StatefulWidget {
  const SaveTab({super.key});

  @override
  State<SaveTab> createState() => _SaveTabState();
}

class _SaveTabState extends State<SaveTab> {
  List<PasswordEntry> _savedPasswords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPasswords();
  }

  Future<void> _loadSavedPasswords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedIds = prefs.getStringList('saved_password_ids') ?? [];

      List<PasswordEntry> passwords = [];

      for (String id in savedIds) {
        String? title = prefs.getString('title_$id');
        String? password = prefs.getString('password_$id');
        String? dateStr = prefs.getString('date_$id');

        if (title != null && password != null && dateStr != null) {
          DateTime date = DateTime.parse(dateStr);
          passwords.add(PasswordEntry(
            id: id,
            title: title,
            password: password,
            createdAt: date,
          ));
        }
      }

      // Sort by newest first
      passwords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _savedPasswords = passwords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading passwords: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deletePassword(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedIds = prefs.getStringList('saved_password_ids') ?? [];

      savedIds.remove(id);
      await prefs.setStringList('saved_password_ids', savedIds);

      // Remove the individual password entries
      await prefs.remove('title_$id');
      await prefs.remove('password_$id');
      await prefs.remove('date_$id');

      // Update the UI
      setState(() {
        _savedPasswords.removeWhere((entry) => entry.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting password: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPasswordDetails(PasswordEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Password:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.password,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    tooltip: 'Copy to clipboard',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Created: ${_formatDate(entry.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deletePassword(entry.id);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Generate an icon based on the password title
  IconData _getIconForTitle(String title) {
    // Simple but deterministic way to pick an icon based on the title
    final iconOptions = [
      Icons.lock,
      Icons.security,
      Icons.password,
      Icons.key,
      Icons.shield,
      Icons.account_circle,
      Icons.web,
      Icons.phone_android,
      Icons.credit_card,
      Icons.shopping_bag,
    ];

    // Create a deterministic "random" selection based on the title
    int sum = 0;
    for (int i = 0; i < title.length; i++) {
      sum += title.codeUnitAt(i);
    }

    return iconOptions[sum % iconOptions.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSavedPasswords,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Saved Passwords'),
                titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                background: Container(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSavedPasswords,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_savedPasswords.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_open,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved passwords yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generated passwords will appear here once saved',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final entry = _savedPasswords[index];
                    return Dismissible(
                      key: Key(entry.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deletePassword(entry.id);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          child: Icon(_getIconForTitle(entry.title)),
                        ),
                        title: Text(entry.title),
                        subtitle:
                            Text('Created: ${_formatDate(entry.createdAt)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPasswordDetails(entry),
                      ),
                    );
                  },
                  childCount: _savedPasswords.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Model class for password entries
class PasswordEntry {
  final String id;
  final String title;
  final String password;
  final DateTime createdAt;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.password,
    required this.createdAt,
  });
}
