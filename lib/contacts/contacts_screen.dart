import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/contact_item.dart';
import '../services/contacts_service.dart';
import '../theme/app_colors.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool _loading = true;
  String? _error;
  List<ContactItem> _contacts = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contacts = await ContactsService.instance.getContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleVip(ContactItem contact) async {
    final idx = _contacts.indexOf(contact);
    try {
      final newValue = await ContactsService.instance.toggleVip(contact.id);
      if (!mounted) return;
      setState(() {
        _contacts[idx] = ContactItem(
          id: contact.id,
          name: contact.name,
          email: contact.email,
          company: contact.company,
          platforms: contact.platforms,
          isVip: newValue,
          aiProcessingEnabled: contact.aiProcessingEnabled,
          relationshipLabel: contact.relationshipLabel,
          mailCount: contact.mailCount,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(ContactItem contact) async {
    try {
      await ContactsService.instance.deleteContact(contact.id);
      if (!mounted) return;
      setState(() => _contacts.remove(contact));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  List<ContactItem> get _filtered => _query.isEmpty
      ? _contacts
      : _contacts
          .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()) || c.email.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kişiler', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: TextField(
                style: TextStyle(color: c.textPrimary),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Kişi ara...',
                  hintStyle: TextStyle(color: c.textHint),
                  prefixIcon: Icon(Icons.search, color: c.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(c)),
        ],
      ),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)));
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(child: Text('Kişi bulunamadı', style: TextStyle(color: c.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildContactTile(list[index], c),
      ),
    );
  }

  Widget _buildContactTile(ContactItem contact, AppColors c) {
    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.card,
          title: Text('Kişiyi Sil', style: TextStyle(color: c.textPrimary)),
          content: Text('${contact.name} silinsin mi?', style: TextStyle(color: c.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('İptal', style: TextStyle(color: c.textSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Color(0xFFEF4444)))),
          ],
        ),
      ),
      onDismissed: (_) => _delete(contact),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(contact.email, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(contact.relationshipLabel, style: TextStyle(color: c.textHint, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _toggleVip(contact),
              icon: Icon(
                contact.isVip ? Icons.star_rounded : Icons.star_border_rounded,
                color: contact.isVip ? const Color(0xFFF59E0B) : c.iconSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
