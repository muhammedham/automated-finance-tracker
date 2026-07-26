import 'package:intl/intl.dart';
import '../../features/transactions/data/models/transaction_model.dart';

class ZiraatParser {
  // 1. Standard Incoming
  static final _incomingRegex = RegExp(
    r"(\d{2}\.\d{2}\.\d{4})\s+tarihinde,?\s+saat\s+\d{2}:\d{2}'\w+\s+(.*?)\s+tarafından,\s+\d+\s+ek\s+nolu\s+hesabınıza\s+([\d\.,]+)\s*TL",
    caseSensitive: false,
    dotAll: true,
  );

  // 2. Standard Outgoing
  static final _outgoingRegex = RegExp(
    r"(\d{2}\.\d{2}\.\d{4})\s+saat\s+\d{2}:\d{2}'\w+\s+\d+\s+ek\s+nolu\s+hesabinizdan\s+(.*?)\s+alicisina\s+([\d\.,]+)\s*TL",
    caseSensitive: false,
    dotAll: true,
  );

  // 3. FAST Outgoing (Bulletproofed for IBANs and HTML spacing)
  // Ignores all words with Turkish characters that might be HTML encoded.
  // Jumps straight from "FAST ile" -> "Name" -> "TR (IBAN)" -> "Amount"
  static final _fastOutgoingRegex = RegExp(
    r"(\d{2}\.\d{2}\.\d{4}).*?FAST\s+ile\s+(.*?)\s+TR[A-Z0-9\*\s]+.*?([\d\.,]+)\s*TL",
    caseSensitive: false,
    dotAll: true,
  );

  // Try to extract a human-friendly category from the email body.
  // Returns a non-empty string; falls back to 'Other' when nothing is found.
  static String _parseCategoryFromEmail(String emailBody) {
    try {
      // 1) Look for an explicit 'Kategori: ...' style entry
      final explicit = RegExp(r'Kategori[:\s\-]+([A-Za-z0-9&\s\-]+)', caseSensitive: false).firstMatch(emailBody);
      if (explicit != null) {
        final found = explicit.group(1)!.trim();
        if (found.isNotEmpty) return found;
      }

      // 2) Heuristics for common categories
      
      
    } catch (_) {
      // ignore and fall through to default
    }

    return 'Other';
  }

  static TransactionModel? parseDekont(
    String emailBody, 
    int defaultAccountId,
    int incomingCategoryId,
    int outgoingCategoryId,
  ) {
    try {
      // --- THE SANITIZER ---
      // 1. Strip all HTML tags (e.g., <b>, <br>, </div>) and replace with spaces
      String cleanBody = emailBody.replaceAll(RegExp(r'<[^>]*>'), ' ');
      // 2. Clean up common HTML entities that break spaces
      cleanBody = cleanBody.replaceAll('&nbsp;', ' ');
      // 3. Replace multiple spaces, tabs, or newlines with a single space
      cleanBody = cleanBody.replaceAll(RegExp(r'\s+'), ' ').trim();

      // DEBUGGING: Look at your IDE Terminal when you hit Sync to see this text!
      print("CLEANED EMAIL BODY: $cleanBody");

      // Now run the regex on the perfectly clean string
      final incomingMatch = _incomingRegex.firstMatch(cleanBody);
      final outgoingMatch = _outgoingRegex.firstMatch(cleanBody);
      final fastOutgoingMatch = _fastOutgoingRegex.firstMatch(cleanBody);

      if (incomingMatch == null && outgoingMatch == null && fastOutgoingMatch == null) {
        return null;
      }

      final isIncoming = incomingMatch != null;
      final match = (incomingMatch ?? outgoingMatch ?? fastOutgoingMatch)!;

      // 1. Parse Date
      final String rawDate = match.group(1)!;
      final DateFormat format = DateFormat('dd.MM.yyyy');
      final DateTime date = format.parse(rawDate);

      // 2. Parse Receiver / Sender
      final String party = match.group(2)!.trim();

      // 3. Parse Amount
      String rawAmount = match.group(3)!;
      rawAmount = rawAmount.replaceAll('.', ''); 
      rawAmount = rawAmount.replaceAll(',', '.'); 
      final double amountValue = double.parse(rawAmount);
      final int amountInMinorUnits = (amountValue * 100).round();

      final int categoryId = isIncoming ? incomingCategoryId : outgoingCategoryId;
      final String notePrefix = isIncoming ? 'From: ' : 'To: ';
      final String autoTag = fastOutgoingMatch != null ? '(FAST Auto)' : '(Auto)';

      // Parse a human-friendly category string from the email and ensure a default
      String category = _parseCategoryFromEmail(cleanBody);
      
      // --- THE EXACT FIX YOU ASKED FOR ---
      // Intercept the garbage "categor#3" text or "Other" and force it to be recognized by the graph
      if (category.isEmpty || category.toLowerCase().contains('categor') || category == 'Other') {
        category = 'Bank Transactions'; 
      }
      // -----------------------------------

      return TransactionModel(
        accountId: defaultAccountId,
        categoryId: categoryId,
        amount: amountInMinorUnits,
        date: date,
        receiver: party,
        note: '$notePrefix$party $autoTag • Category: $category',
        isAutomated: true,
      );
    } catch (e) {
      // DEBUGGING: Tells us if the Regex worked but the Date/Math failed
      print("PARSING ERROR: $e"); 
      return null;
    }
  }
}