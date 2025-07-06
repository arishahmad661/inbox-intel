import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;
import '../models/email.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  GoogleSignInAccount? _googleAccount;
  auth.AuthClient? _authClient;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [GmailApi.gmailReadonlyScope],
  );

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  GoogleSignInAccount? get googleAccount => _googleAccount;
  auth.AuthClient? get authClient => _authClient;
  List<Map<String, String>> _topEmails = [];
  List<Map<String, String>> get topEmails => _topEmails;

  Future<bool> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // User cancelled login

      final authData = await account.authentication;

      final credentials = auth.AccessCredentials(
        auth.AccessToken("Bearer", authData.accessToken!, DateTime.now().toUtc().add(Duration(hours: 1))),
        authData.idToken,
        [GmailApi.gmailReadonlyScope],
      );

      _authClient = auth.authenticatedClient(http.Client(), credentials);

      _googleAccount = account;
      _userEmail = account.email;
      _isAuthenticated = true;

      fetchAndDistributeEmails();
      notifyListeners();
      return true;
    } catch (e) {
      print("Google Sign-In error: $e");
      return false;
    }
  }

  void logout() async {
    await _googleSignIn.signOut();
    _isAuthenticated = false;
    _userEmail = null;
    _googleAccount = null;
    _authClient = null;
    notifyListeners();
  }

  Future<void> fetchTopEmails({int maxResults = 20}) async {
    if (_authClient == null) return;

    try {
      final gmail = GmailApi(_authClient!);
      final messagesResponse = await gmail.users.messages.list(
        'me',
        maxResults: maxResults,
        labelIds: ['INBOX'],
      );

      final emails = <Map<String, String>>[];

      for (final msg in messagesResponse.messages ?? []) {
        final message = await gmail.users.messages.get('me', msg.id!);

        final headers = message.payload?.headers ?? [];
        final subject = headers.firstWhere(
              (h) => h.name == 'Subject',
          orElse: () => MessagePartHeader(name: 'Subject', value: '(No Subject)'),
        ).value;

        final from = headers.firstWhere(
              (h) => h.name == 'From',
          orElse: () => MessagePartHeader(name: 'From', value: '(Unknown Sender)'),
        ).value;

        emails.add({
          'subject': subject ?? '',
          'from': from ?? '',
        });
      }

      _topEmails = emails;

      notifyListeners();
    } catch (e) {
      print("Failed to fetch emails: $e");
    }
  }

  Future<void> saveEmailsToStorage(List<Email> emails) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = emails.map((e) => e.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString('emails', jsonString);
  }

  Future<void> fetchAndDistributeEmails() async {
    if (_authClient == null) return;

    final gmailApi = GmailApi(_authClient!);
    final messagesResponse = await gmailApi.users.messages.list('me', maxResults: 10);
    final messageList = messagesResponse.messages ?? [];

    print("Total mails fetched: ${messageList.length}");
    final List<Email> emailList = [];

    for (final message in messageList) {
      final fullMessage = await gmailApi.users.messages.get('me', message.id!, format: 'full');

      // Helper to extract a header
      String? getHeader(Message message, String name) {
        final headers = message.payload?.headers ?? [];
        return headers.firstWhere(
              (h) => h.name?.toLowerCase() == name.toLowerCase(),
          orElse: () => MessagePartHeader(),
        ).value;
      }

      final snippet = fullMessage.snippet ?? '';
      final sender = getHeader(fullMessage, 'From') ?? 'Unknown';
      final subject = getHeader(fullMessage, 'Subject') ?? '(No Subject)';
      final internalDate = int.tryParse(fullMessage.internalDate ?? '') ??
          DateTime.now().millisecondsSinceEpoch;

      final email = Email(
        id: message.id!,
        sender: sender,
        subject: subject,
        preview: snippet,
        date: DateTime.fromMillisecondsSinceEpoch(internalDate),
        isPhishing: false, // Replace with logic for Bard or other classifier
      );
      emailList.add(email);

      print('Email: ${email.subject} from ${email.sender}');

      // await saveEmailsToStorage(emailList);
      // Add to provider if needed:
      // Provider.of<EmailProvider>(context, listen: false).addEmail(email);
      // OR: if this is inside EmailProvider class: this.addEmail(email);
    }

    Future<void> saveEmailsToFile(List<Email> emailList) async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/emails.txt');

      // Convert each Email object to a string and join them
      String content = emailList.map((email) => email.toText()).join('\n---\n');

      await file.writeAsString(content);
      print('Emails saved to: ${file.path}');
    }

    saveEmailsToFile(emailList);




  }

}
