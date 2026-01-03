import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Deine Imports
import '../providers/review_provider.dart';
import 'package:gsplit/models/models.dart';
import '../widgets/guinness_glass_rating.dart';
import '../widgets/brutal_button.dart';

class ReviewScreen extends StatefulWidget {
  final String pubId;
  final String pubName;
  final String pubAddress;
  final String userId;

  const ReviewScreen({
    Key? key,
    required this.pubId,
    required this.pubName,
    required this.pubAddress,
    required this.userId,
  }) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // WICHTIG: Hier definieren wir die Controller
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    // Automatisch Kamera starten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        _autoOpenCamera();
      }
    });
  }

  void _autoOpenCamera() async {
    await Future.delayed(Duration(milliseconds: 1200));
    if (!mounted) return;

    // Ruft Kamera im Provider auf
    context.read<ReviewProvider>().takePhoto();
    // Setzt Start-Rating auf 9.0 (fast perfekt)
    context.read<ReviewProvider>().updateRating(9.0);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animationController.dispose();
    _notesController.dispose(); // Aufräumen
    _priceController.dispose(); // Aufräumen
    super.dispose();
  }

  // ---------------- UI BUILDING ----------------

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        // HIER ÄNDERN: GestureDetector außenrum packen
        return GestureDetector(
          onTap: () =>
              FocusScope.of(context).unfocus(), // Das schließt die Tastatur
          child: Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            appBar: _buildAppBar(provider),
            body: _buildBody(provider),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(ReviewProvider provider) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Color(0xFFF5E6D3)),
        onPressed: () => _showDiscardDialog(provider),
      ),
      title: Text(
        'REVIEW',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Color(0xFFF5E6D3),
        ),
      ),
      centerTitle: true,
      actions: [
        if (provider.state == ReviewState.RATING)
          TextButton(
            // KORREKTUR: Wir rufen _submitReview mit dem Provider auf
            onPressed: provider.isValid && !provider.isSubmitting
                ? () => _submitReview(provider)
                : null,
            child: Text(
              'POST',
              style: TextStyle(
                color: provider.isValid && !provider.isSubmitting
                    ? Color(0xFFD4AF37)
                    : Color(0xFF746855),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(ReviewProvider provider) {
    // Hier wird entschieden, welcher Screen-Teil gezeigt wird
    switch (provider.state) {
      case ReviewState.CAMERA:
        return _buildCameraPlaceholder();
      case ReviewState.PREVIEW:
        return _buildPhotoPreview(provider);
      case ReviewState.AI_ANALYZING:
        return _buildAIAnalyzing(provider);
      case ReviewState.RATING:
        return _buildRatingForm(provider);
      case ReviewState.SUBMITTING:
        return _buildSubmitting();
      case ReviewState.SUCCESS:
        return _buildSuccess();
      case ReviewState.ERROR:
        return _buildError(provider);
    }
  }

  Widget _buildCameraPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 64, color: Color(0xFF746855)),
          SizedBox(height: 16),
          Text('Opening camera...', style: TextStyle(color: Color(0xFF746855))),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(ReviewProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Photo Preview
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: provider.photo != null
                  ? (kIsWeb
                        ? Image.network(provider.photo!.path, fit: BoxFit.cover)
                        : Image.file(
                            io.File(provider.photo!.path),
                            fit: BoxFit.cover,
                          ))
                  : Container(),
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: BrutalButton(
                    label: 'RE-TAKE',
                    variant: ButtonVariant.outline,
                    onPressed: () => provider.retakePhoto(),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: BrutalButton(
                    label: 'USE PHOTO',
                    onPressed: () => provider.confirmPhoto(),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // AI Info
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFD4AF37).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI will analyze your pour for color, foam, and quality',
                    style: TextStyle(color: Color(0xFFF5E6D3), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalyzing(ReviewProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Guinness Glass
          Container(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _GuinnessPourPainter(
                animation: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 32),

          Text(
            'ANALYZING POUR...',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),

          SizedBox(height: 16),

          Text(
            'Checking color, foam height, and quality',
            style: TextStyle(color: Color(0xFF746855)),
          ),

          SizedBox(height: 32),

          // Cancel button after 5 seconds
          FutureBuilder(
            future: Future.delayed(Duration(seconds: 5)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return TextButton(
                  onPressed: () {
                    // Skip AI analysis
                    provider.updateRating(5.0);
                  },
                  child: Text(
                    'SKIP ANALYSIS',
                    style: TextStyle(
                      color: Color(0xFF746855),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingForm(ReviewProvider provider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. PUB INFO HEADER (Der Name im Hintergrund) ---
          Container(
            width: double.infinity, // Volle Breite
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pubName.toUpperCase(), // Mach es BRUTAL (Uppercase)
                  style: TextStyle(
                    color: Color(0xFFF5E6D3),
                    fontSize: 28, // Größer
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Color(0xFFD4AF37)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.pubAddress,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // --- 2. AI RESULT BOX (Jetzt klickbar & mit Hot Icon) ---
          if (provider.aiScore != null)
            GestureDetector(
              onTap: () => _showAiDetails(context, provider), // Klick-Funktion!
              child: Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  // Farbe je nach Score (Grün, Gold oder Dunkel)
                  color: provider.isPerfectPour
                      ? Colors.green.withOpacity(0.15)
                      : (provider.aiScore! > 7.0
                            ? Color(0xFFD4AF37).withOpacity(0.15)
                            : Colors.red.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: provider.isPerfectPour
                        ? Colors.green
                        : (provider.aiScore! > 7.0
                              ? Color(0xFFD4AF37)
                              : Colors.red),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row mit Icon
                    Row(
                      children: [
                        // --- HIER IST DIE LOGIK FÜR DAS ICON ---
                        Icon(
                          provider.isPerfectPour
                              ? Icons
                                    .star // Perfekt
                              : (provider.aiScore! > 7.5
                                    ? Icons
                                          .whatshot // 🔥 HOT ICON IS BACK
                                    : Icons.info_outline), // Mäh
                          color: provider.isPerfectPour
                              ? Colors.green
                              : (provider.aiScore! > 7.5
                                    ? Color(0xFFD4AF37)
                                    : Colors.red),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.isPerfectPour
                                    ? 'PERFECT POUR'
                                    : (provider.aiScore! > 7.5
                                          ? 'SOLID PINT'
                                          : 'POOR POUR'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'AI Score: ${provider.aiScore!.toStringAsFixed(1)}/10  (Tap for details)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white30),
                      ],
                    ),

                    // Keywords (wie vorher)
                    if (provider.aiKeywords.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Divider(color: Colors.white12),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: provider.aiKeywords.map((keyword) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              keyword.toUpperCase(),
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // --- 3. DAS INTERAKTIVE GLAS ---
          Text(
            'RATE THE PINT',
            style: TextStyle(
              color: Color(0xFFF5E6D3),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: GuinnessGlassRating(
              size: Size(250, 350),
              rating: provider.overallRating,
              onRatingChanged: provider.updateRating,
            ),
          ),

          SizedBox(height: 40),

          // --- 4. NOTES FIELD ---
          Text(
            'NOTES (OPTIONAL)',
            style: TextStyle(
              color: Color(0xFFF5E6D3),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              textInputAction: TextInputAction.done,
              controller: _notesController,
              onChanged: provider.updateNotes,
              maxLines: 4,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: TextStyle(color: Color(0xFFF5E6D3)),
              decoration: InputDecoration(
                hintText: 'Creamy head, perfect temperature...',
                hintStyle: TextStyle(color: Color(0xFF746855)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          SizedBox(height: 48),

          // --- 5. TYPE & PRICE ---
          Text(
            'TYPE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildTypeChip(GuinnessType.DRAUGHT, 'Draught', provider),
              _buildTypeChip(GuinnessType.EXTRA_STOUT, 'Extra Stout', provider),
              _buildTypeChip(null, "Other", provider),
            ],
          ),

          SizedBox(height: 32),

          Text(
            'PRICE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onChanged: provider.updatePrice,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.euro,
                  color: Color(0xFFD4AF37),
                  size: 18,
                ),
                hintText: 'e.g. 6.50',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          SizedBox(height: 48),

          // --- 6. SUBMIT ---
          BrutalButton(
            label: 'SUBMIT REVIEW',
            isLoading: provider.isSubmitting,
            isEnabled: provider.isValid && !provider.isSubmitting,
            onPressed: () => _submitReview(provider),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAiDetails(BuildContext context, ReviewProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text(
              "AI Analysis",
              style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Here is what Gemini saw:",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              provider.aiExplanation ?? "No detailed explanation available.",
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 20),
            if (provider.aiKeywords.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.aiKeywords
                    .map(
                      (k) => Chip(
                        label: Text(k),
                        backgroundColor: Colors.black,
                        labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                        side: BorderSide(color: Colors.white24),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "COOL",
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitting() {
    return Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Color(0xFF50C878)),
          SizedBox(height: 24),
          Text(
            'REVIEW POSTED!',
            style: TextStyle(
              color: Color(0xFF50C878),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ReviewProvider provider) {
    return Center(
      child: Text(
        provider.errorMessage ?? "Error",
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  void _showDiscardDialog(ReviewProvider provider) {
    provider.reset();
    Navigator.pop(context);
  }

  // ---------------- LOGIC ----------------

  // KORREKTUR: Diese Methode nimmt jetzt den Provider entgegen
  void _submitReview(ReviewProvider provider) async {
    // Wir speichern den Text aus dem Controller sicherheitshalber noch mal im Provider
    provider.updateNotes(_notesController.text);

    try {
      // Aufruf der echten Provider-Methode
      await provider.submitReview(widget.pubId, widget.userId);

      // Wenn erfolgreich -> Schließen
      if (provider.state == ReviewState.SUCCESS && mounted) {
        _autoCloseTimer = Timer(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
            provider.reset();
          }
        });
      }
    } catch (e) {
      // Fehler wird im UI angezeigt (_buildError)
    }
  }

  Widget _buildTypeChip(
    GuinnessType? type,
    String label,
    ReviewProvider provider,
  ) {
    final isSelected = provider.guinnessType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setGuinnessType(type),
      selectedColor: Color(0xFFD4AF37),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
    );
  }
}

// Helper Class für die AI Animation (falls du sie brauchst)
class _GuinnessPourPainter extends CustomPainter {
  final Animation<double> animation;
  _GuinnessPourPainter({required this.animation});
  @override
  void paint(Canvas canvas, Size size) {
    /* ... dein Painter Code ... */
  }
  @override
  bool shouldRepaint(_GuinnessPourPainter oldDelegate) => true;
}
