// lib/screens/pub_selection_screen.dart - VOLLSTÄNDIG MIT IMPORTS

import 'package:flutter/material.dart';
import '../models/models.dart';
import 'review_screen.dart'; // ← FEHLT!

class PubSelectionScreen extends StatelessWidget {
  final List<Pub> nearbyPubs;

  const PubSelectionScreen({Key? key, required this.nearbyPubs})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(
          'SELECT PUB',
          style: TextStyle(
            letterSpacing: 2,
            color: Color(0xFFF5E6D3), // ← FARBE HINZUFÜGEN
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: nearbyPubs.length,
        itemBuilder: (context, index) {
          final pub = nearbyPubs[index];
          return _PubTile(
            pub: pub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewScreen(
                    // ✅ ALLE 4 PARAMETER HINZUFÜGEN:
                    pubId: pub.id,
                    pubName: pub.name,
                    pubAddress: pub.address,
                    userId: 'demo_user_id', // ← Temporär
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PubTile extends StatelessWidget {
  final Pub pub;
  final VoidCallback onTap;

  const _PubTile({required this.pub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF746855).withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xFF0D0D0D),
          ),
          child: Icon(Icons.local_bar, color: Color(0xFFD4AF37)),
        ),
        title: Text(
          pub.name,
          style: TextStyle(
            color: Color(0xFFF5E6D3),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          pub.address,
          style: TextStyle(color: Color(0xFF746855)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right, color: Color(0xFF746855)),
        onTap: onTap,
      ),
    );
  }
}
