import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Password generation options
  int _passwordLength = 12;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSpecial = true;
  String _generatedPassword = '';
  bool _isLoading = false;

  // Text controller for password name/title
  final TextEditingController _passwordNameController = TextEditingController();

  @override
  void dispose() {
    _passwordNameController.dispose();
    super.dispose();
  }

  // Generate a random password based on selected criteria
  void _generatePassword() {
    setState(() {
      _isLoading = true;
    });

    // Simulate a loading delay
    Future.delayed(const Duration(milliseconds: 600), () {
      final random = Random.secure();
      const lowerCaseChars = 'abcdefghijklmnopqrstuvwxyz';
      const upperCaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const numberChars = '0123456789';
      const specialChars = '!@#\$%^&*()-_=+[]{}|;:,.<>?/';

      String validChars = '';
      if (_useLowercase) validChars += lowerCaseChars;
      if (_useUppercase) validChars += upperCaseChars;
      if (_useNumbers) validChars += numberChars;
      if (_useSpecial) validChars += specialChars;

      // Ensure at least one character set is selected
      if (validChars.isEmpty) {
        validChars = lowerCaseChars;
      }

      String password = '';
      for (int i = 0; i < _passwordLength; i++) {
        password += validChars[random.nextInt(validChars.length)];
      }

      setState(() {
        _generatedPassword = password;
        _isLoading = false;
      });
    });
  }

  // Copy password to clipboard
  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Save password to SharedPreferences
  void _savePassword() async {
    if (_generatedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a password first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_passwordNameController.text.isEmpty) {
      // Show dialog to enter password name
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Simpan Password'),
          content: TextField(
            controller: _passwordNameController,
            decoration: const InputDecoration(
              labelText: 'Password Name',
              hintText: 'e.g., Gmail, Netflix, Bank',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _performSave();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      _performSave();
    }
  }

  void _performSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing saved passwords
      List<String> savedPasswordIds =
          prefs.getStringList('saved_password_ids') ?? [];

      // Generate a unique ID for this password
      String id = DateTime.now().millisecondsSinceEpoch.toString();

      // Save the password details
      await prefs.setString('password_$id', _generatedPassword);
      await prefs.setString('title_$id', _passwordNameController.text);
      await prefs.setString('date_$id', DateTime.now().toString());

      // Add this ID to the list of saved passwords
      savedPasswordIds.add(id);
      await prefs.setStringList('saved_password_ids', savedPasswordIds);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear the name field after saving
      _passwordNameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving password: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Password Generator'),
              titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              background: Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generatePassword,
                tooltip: 'Generate New Password',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Generated Password:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        child: _isLoading
                            ? Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : Text(
                                _generatedPassword.isEmpty
                                    ? 'Press generate to create password'
                                    : _generatedPassword,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'monospace',
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _generatePassword,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generate'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy to clipboard',
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: _savePassword,
                            icon: const Icon(Icons.save),
                            tooltip: 'Save password',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password Options',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text('Length: $_passwordLength characters'),
                      Slider(
                        value: _passwordLength.toDouble(),
                        min: 6,
                        max: 32,
                        divisions: 26,
                        label: _passwordLength.toString(),
                        onChanged: (value) {
                          setState(() {
                            _passwordLength = value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Uppercase Letters (A-Z)'),
                        value: _useUppercase,
                        onChanged: (value) {
                          setState(() {
                            _useUppercase = value;
                          });
                        },
                        dense: true,
                      ),
                      SwitchListTile(
                        title: const Text('Lowercase Letters (a-z)'),
                        value: _useLowercase,
                        onChanged: (value) {
                          setState(() {
                            _useLowercase = value;
                          });
                        },
                        dense: true,
                      ),
                      SwitchListTile(
                        title: const Text('Numbers (0-9)'),
                        value: _useNumbers,
                        onChanged: (value) {
                          setState(() {
                            _useNumbers = value;
                          });
                        },
                        dense: true,
                      ),
                      SwitchListTile(
                        title: const Text('Special Characters (!@#\$%^&*)'),
                        value: _useSpecial,
                        onChanged: (value) {
                          setState(() {
                            _useSpecial = value;
                          });
                        },
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Password Tips:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildTipTile(
                'Use a minimum of 12 characters',
                'Longer passwords are generally more secure',
                Icons.text_fields,
              ),
              _buildTipTile(
                'Mix character types',
                'Include letters, numbers, and special characters',
                Icons.shuffle,
              ),
              _buildTipTile(
                'Don\'t use personal information',
                'Avoid names, birthdays, or common words',
                Icons.person_off,
              ),
              _buildTipTile(
                'Use different passwords',
                'Each account should have a unique password',
                Icons.diversity_3,
              ),
            ]),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTipTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      dense: true,
    );
  }
}
