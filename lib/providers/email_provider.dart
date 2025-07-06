import 'package:flutter/material.dart';
import '../models/email.dart';

class EmailProvider with ChangeNotifier {
  final List<Email> _emails = [
    Email(
      id: '1',
      sender: 'security@company.com',
      subject: 'Important: Security Update Required',
      preview: 'Please update your security settings immediately...',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isPhishing: false,
    ),
    Email(
      id: '2',
      sender: 'paypal@service.com',
      subject: 'Your account has been locked',
      preview: 'Click here to verify your account information...',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      isPhishing: true,
    ),
    Email(
      id: '3',
      sender: 'support@bank.com',
      subject: 'Transaction Alert',
      preview: 'A new transaction has been made on your account...',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isPhishing: false,
    ),
    Email(
      id: '4',
      sender: 'noreply@amazon.com',
      subject: 'Your order has been shipped',
      preview: 'Your recent order #12345 has been shipped...',
      date: DateTime.now().subtract(const Duration(days: 2)),
      isPhishing: false,
    ),
    Email(
      id: '5',
      sender: 'security@apple.com',
      subject: 'Your Apple ID has been locked',
      preview: 'Click here to unlock your account...',
      date: DateTime.now().subtract(const Duration(days: 3)),
      isPhishing: true,
    ),
  ];

  List<Email> get allEmails => _emails;
  List<Email> get phishingEmails => _emails.where((email) => email.isPhishing).toList();
  List<Email> get safeEmails => _emails.where((email) => !email.isPhishing).toList();

  void markAsRead(String emailId) {
    final index = _emails.indexWhere((email) => email.id == emailId);
    if (index != -1) {
      _emails[index] = Email(
        id: _emails[index].id,
        sender: _emails[index].sender,
        subject: _emails[index].subject,
        preview: _emails[index].preview,
        date: _emails[index].date,
        isPhishing: _emails[index].isPhishing,
        isRead: true,
      );
      notifyListeners();
    }
  }
}


class EmailProviderr with ChangeNotifier {
  final List<Email> _emails = [];

  List<Email> get safeEmails => _emails.where((e) => !e.isPhishing).toList();
  List<Email> get phishingEmails => _emails.where((e) => e.isPhishing).toList();

  void addEmail(Email email) {
    _emails.add(email);
    notifyListeners();
  }

  void clearEmails() {
    _emails.clear();
    notifyListeners();
  }

  // Optional: method to batch add emails
  void addEmails(List<Email> emails) {
    _emails.addAll(emails);
    notifyListeners();
  }
}
