import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imapServiceProvider = Provider((ref) => ImapService());

class ImapService {
  Future<List<String>> fetchUnreadZiraatEmails({
    required String email,
    required String appPassword,
    required String imapServer, // e.g., imap.gmail.com
    int port = 993,
  }) async {
    final client = ImapClient(isLogEnabled: false);
    final List<String> emailBodies = [];

    try {
      await client.connectToServer(imapServer, port, isSecure: true);
      await client.login(email, appPassword);
      await client.selectMailboxByPath('INBOX');

      // FIXED: Removed SUBJECT "PARA" so it catches FAST emails too
      final searchResult = await client.searchMessages(
        searchCriteria: 'UNSEEN FROM "ziraatbankasi@ileti.ziraatbank.com.tr"',
      );

      if (searchResult.matchingSequence != null && searchResult.matchingSequence!.isNotEmpty) {
        final fetchResult = await client.fetchMessages(
          searchResult.matchingSequence!, 
          'BODY[]', 
        );

        for (final msg in fetchResult.messages) {
          final text = msg.decodeTextPlainPart() ?? msg.decodeTextHtmlPart() ?? '';
          if (text.isNotEmpty) {
            emailBodies.add(text);
          }
        }
        
        // Optional: Once you confirm it works, you can mark them as read so you don't parse them twice:
        // await client.uidStore(searchResult.messages, 'FLAGS', '(\\Seen)');
      }
    } catch (e) {
      throw Exception('IMAP Connection Failed: $e');
    } finally {
      await client.disconnect();
    }

    return emailBodies;
  }
}