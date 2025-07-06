import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/email_provider.dart';
import '../models/email.dart';
import 'settings_screen.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchAndDistributeEmails();

  }

  Future<void> fetchAndDistributeEmails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);

    final authClient = authProvider.authClient;

    if (authClient == null) return;

    final gmail = GmailApi(authClient);
    final messagesResponse = await gmail.users.messages.list('me', maxResults: 10);
    final messageList = messagesResponse.messages ?? [];

    // emailProvider.clearEmails(); // Clear previous emails

    for (final message in messageList) {
      final fullMessage = await gmail.users.messages.get('me', message.id!);
      final headers = {
        for (var h in fullMessage.payload?.headers ?? []) h.name: h.value
      };
      final snippet = fullMessage.snippet ?? '';

      final email = Email(
        id: message.id!,
        sender: headers['From'] ?? 'Unknown',
        subject: headers['Subject'] ?? '(No Subject)',
        preview: snippet,
        date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(fullMessage.internalDate ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        isPhishing: false, // Placeholder - replace with classification later
      );

      // emailProvider.addEmail(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox Intel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          EmailListScreen(isPhishing: false),
          EmailListScreen(isPhishing: true),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning),
            label: 'Blocked',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class EmailListScreen extends StatelessWidget {
  final bool isPhishing;

  const EmailListScreen({
    super.key,
    required this.isPhishing,
  });

  @override
  Widget build(BuildContext context) {
    final emailProvider = Provider.of<EmailProvider>(context);
    final emails = isPhishing ? emailProvider.phishingEmails : emailProvider.safeEmails;

    if (emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPhishing ? Icons.warning : Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isPhishing ? 'No blocked emails' : 'No emails in inbox',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isPhishing ? 'All your emails are safe' : 'Your inbox is empty',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: email.isPhishing
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                email.isPhishing ? Icons.warning : Icons.check,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            title: Text(
              email.subject,
              style: TextStyle(
                fontWeight: email.isRead ? FontWeight.normal : FontWeight.bold,
                color: email.isPhishing ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.sender,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: email.isPhishing ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
                Text(
                  email.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(email.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (email.isPhishing)
                  Text(
                    'Blocked',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            onTap: () {
              emailProvider.markAsRead(email.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email from ${email.sender}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
