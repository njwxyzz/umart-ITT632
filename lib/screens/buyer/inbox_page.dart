import 'package:flutter/material.dart';
import 'chat_page.dart'; // 🚨 Wajib ada untuk link ke bilik sembang!

const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy untuk senarai mesej (Inbox)
    final List<Map<String, dynamic>> chatList = [
      {
        'name': 'Ahmad Faizal (Runner)',
        'message': 'Beres bos!',
        'time': '12:37 PM',
        'unread': 0,
        'image': 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100'
      },
      {
        'name': 'Mak Cik Siti',
        'message': 'Nasi lemak akak dah habis la dik. Tukar mi goreng nak?',
        'time': '10:15 AM',
        'unread': 2,
        'image': 'https://images.unsplash.com/photo-1607631568010-a87245c0daf7?w=100'
      },
      {
        'name': 'Bake & Brew',
        'message': 'Your order is ready for pickup.',
        'time': 'Yesterday',
        'unread': 0,
        'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=100'
      },
    ];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Messages', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: chatList.length,
        itemBuilder: (context, index) {
          final chat = chatList[index];
          final hasUnread = chat['unread'] > 0;

          return GestureDetector(
            onTap: () {
              // BILA TEKAN NAMA, DIA BUKA CHAT PAGE KAU!
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(runnerName: chat['name']), // Hantar nama ke ChatPage
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  // Gambar Profil
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: NetworkImage(chat['image']), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Nama & Mesej Terakhir
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['name'],
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 15,
                            color: const Color(0xFF1A1A2E)
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat['message'],
                          style: TextStyle(
                            color: hasUnread ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Masa & Badge Unread
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat['time'],
                        style: TextStyle(
                          color: hasUnread ? kAccent : Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                          child: Text(
                            chat['unread'].toString(),
                            style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const SizedBox(height: 20), // Placeholder supaya layout tak lari
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}