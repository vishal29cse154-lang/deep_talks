import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_card_model.dart';
import '../services/firestore_service.dart';
import '../widgets/game_card_widget.dart';
import '../theme/app_theme.dart';

class CoupleGamesPage extends StatefulWidget {
  final String coupleId;
  const CoupleGamesPage({super.key, required this.coupleId});

  @override
  State<CoupleGamesPage> createState() => _CoupleGamesPageState();
}

class _CoupleGamesPageState extends State<CoupleGamesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final PageController _cardPageController = PageController();
  GameCategory _selectedCategory = GameCategory.warmUp;
  int _currentIndex = 0;

  // ─── Card Data ───────────────────────────────────────────────
  static const List<GameCardModel> _allCards = [
    // Warm Up
    GameCardModel(
      id: 'w1',
      category: GameCategory.warmUp,
      type: CardType.truth,
      text: 'What was your very first impression of me?',
    ),
    GameCardModel(
      id: 'w2',
      category: GameCategory.warmUp,
      type: CardType.dare,
      text:
          'Send your partner the most embarrassing selfie you can take right now.',
    ),
    GameCardModel(
      id: 'w3',
      category: GameCategory.warmUp,
      type: CardType.truth,
      text: 'What\'s one thing I do that always makes you smile?',
    ),
    GameCardModel(
      id: 'w4',
      category: GameCategory.warmUp,
      type: CardType.dare,
      text: 'Do your best impression of your partner for 30 seconds.',
    ),
    GameCardModel(
      id: 'w5',
      category: GameCategory.warmUp,
      type: CardType.truth,
      text: 'What\'s the funniest date we\'ve ever been on?',
    ),
    GameCardModel(
      id: 'w6',
      category: GameCategory.warmUp,
      type: CardType.dare,
      text: 'Write a love poem for your partner in 60 seconds.',
    ),

    // Deep Secrets
    GameCardModel(
      id: 'd1',
      category: GameCategory.deepSecrets,
      type: CardType.truth,
      text: 'What is one insecurity you\'ve never told me about?',
    ),
    GameCardModel(
      id: 'd2',
      category: GameCategory.deepSecrets,
      type: CardType.truth,
      text: 'What\'s the biggest sacrifice you\'ve made for our relationship?',
    ),
    GameCardModel(
      id: 'd3',
      category: GameCategory.deepSecrets,
      type: CardType.dare,
      text: 'Share the password to your phone for 5 minutes.',
    ),
    GameCardModel(
      id: 'd4',
      category: GameCategory.deepSecrets,
      type: CardType.truth,
      text: 'What\'s a dream you\'ve given up on that I don\'t know about?',
    ),
    GameCardModel(
      id: 'd5',
      category: GameCategory.deepSecrets,
      type: CardType.dare,
      text: 'Read out your last 5 search history items.',
    ),
    GameCardModel(
      id: 'd6',
      category: GameCategory.deepSecrets,
      type: CardType.truth,
      text: 'Is there anything about our relationship that scares you?',
    ),

    // 18+ Intimate
    GameCardModel(
      id: 'i1',
      category: GameCategory.intimate,
      type: CardType.truth,
      text: 'What\'s your biggest fantasy that we haven\'t tried yet?',
    ),
    GameCardModel(
      id: 'i2',
      category: GameCategory.intimate,
      type: CardType.dare,
      text: 'Give your partner a 2-minute massage wherever they choose.',
    ),
    GameCardModel(
      id: 'i3',
      category: GameCategory.intimate,
      type: CardType.truth,
      text:
          'What\'s the most attractive thing your partner does without realizing?',
    ),
    GameCardModel(
      id: 'i4',
      category: GameCategory.intimate,
      type: CardType.dare,
      text: 'Whisper something seductive in your partner\'s ear.',
    ),
    GameCardModel(
      id: 'i5',
      category: GameCategory.intimate,
      type: CardType.truth,
      text: 'What part of my body do you find most irresistible?',
    ),
    GameCardModel(
      id: 'i6',
      category: GameCategory.intimate,
      type: CardType.dare,
      text:
          'Slowly undress one piece of clothing while maintaining eye contact.',
    ),
  ];

  List<GameCardModel> get _filteredCards =>
      _allCards.where((c) => c.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedCategory = GameCategory.values[_tabController.index];
        _currentIndex = 0;
        _cardPageController.jumpToPage(0);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  void _nextCard() {
    final cards = _filteredCards;
    if (_currentIndex < cards.length - 1) {
      _cardPageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _syncGameState(GameCardModel card) {
    _firestoreService.updateGameSession(widget.coupleId, {
      'currentCardId': card.id,
      'category': card.category.name,
      'type': card.type.name,
      'text': card.text,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intimate Games 🎲'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🔥 Warm Up'),
            Tab(text: '🤫 Deep Secrets'),
            Tab(text: '💋 18+'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // ─── Card Counter ──────────────────────────────────────
          Text(
            '${_currentIndex + 1} / ${_filteredCards.length}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),

          const SizedBox(height: 16),

          // ─── Swipeable Card Stack ──────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _cardPageController,
              itemCount: _filteredCards.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _syncGameState(_filteredCards[index]);
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: GameCardWidget(card: _filteredCards[index])
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ─── Next Card Button ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  icon: Icons.skip_next_rounded,
                  label: 'Next Card',
                  color: AppTheme.accent,
                  onTap: _nextCard,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Real-Time Sync Indicator ──────────────────────────
          StreamBuilder<Map<String, dynamic>?>(
            stream: _firestoreService.gameSessionStream(widget.coupleId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final session = snapshot.data!;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live synced • ${session['type']?.toString().toUpperCase() ?? ''}: "${(session['text'] ?? '').toString().length > 40 ? '${(session['text'] ?? '').toString().substring(0, 40)}...' : session['text'] ?? ''}"',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
