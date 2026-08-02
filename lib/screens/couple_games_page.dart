import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/game_card_model.dart';
import '../services/firestore_service.dart';
import '../widgets/game_card_widget.dart';
import '../theme/app_theme.dart';
import 'intimate_stories_page.dart';

class CoupleGamesPage extends StatefulWidget {
  final String coupleId;
  const CoupleGamesPage({super.key, required this.coupleId});

  @override
  State<CoupleGamesPage> createState() => _CoupleGamesPageState();
}

class _CoupleGamesPageState extends State<CoupleGamesPage> {
  int _currentTabIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      TruthOrDareGame(coupleId: widget.coupleId),
      SpinWheelGame(coupleId: widget.coupleId),
      LoveCouponsGame(coupleId: widget.coupleId),
      SpicyVideosGame(coupleId: widget.coupleId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couples Playground ✨'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: _pages[_currentTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (i) => setState(() => _currentTabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.style_rounded), label: 'Cards'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded), label: 'Wheel'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_activity_rounded), label: 'Coupons'),
          BottomNavigationBarItem(
              icon: Icon(Icons.lock_person), label: 'Spicy'),
        ],
      ),
    );
  }
}

// ─── TRUTH OR DARE GAME ──────────────────────────────────────────────────────
class TruthOrDareGame extends StatefulWidget {
  final String coupleId;
  const TruthOrDareGame({super.key, required this.coupleId});

  @override
  State<TruthOrDareGame> createState() => _TruthOrDareGameState();
}

class _TruthOrDareGameState extends State<TruthOrDareGame>
    with SingleTickerProviderStateMixin {
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

  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final CardSwiperController _swiperController = CardSwiperController();
  GameCategory _selectedCategory = GameCategory.warmUp;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedCategory = GameCategory.values[_tabController.index];
        _currentIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  void _nextCard() {
    _swiperController.swipe(CardSwiperDirection.right);
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: '🔥 Warm Up'),
            Tab(text: '🤫 Secrets'),
            Tab(text: '💋 18+'),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Card Counter ──────────────────────────────────────
        Text(
          '${_currentIndex + 1} / ${_filteredCards.length}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),

        const SizedBox(height: 16),

        // ─── Swipeable Card Stack ──────────────────────────────
        Expanded(
          child: _filteredCards.isEmpty
              ? const Center(child: Text("No more cards!"))
              : CardSwiper(
                  controller: _swiperController,
                  cardsCount: _filteredCards.length,
                  onSwipe: (previousIndex, currentIndex, direction) {
                    setState(() => _currentIndex = currentIndex ?? 0);
                    if (currentIndex != null &&
                        currentIndex < _filteredCards.length) {
                      _syncGameState(_filteredCards[currentIndex]);
                    }
                    return true;
                  },
                  cardBuilder:
                      (context, index, percentThresholdX, percentThresholdY) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: GameCardWidget(card: _filteredCards[index]),
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

        const SizedBox(height: 16),
      ],
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

// ─── SPIN WHEEL GAME ─────────────────────────────────────────────────────────
class SpinWheelGame extends StatefulWidget {
  final String coupleId;
  const SpinWheelGame({super.key, required this.coupleId});

  @override
  State<SpinWheelGame> createState() => _SpinWheelGameState();
}

class _SpinWheelGameState extends State<SpinWheelGame> {
  final StreamController<int> _wheelController =
      StreamController<int>.broadcast();
  final List<String> _wheelItems = [
    '10 Min Massage',
    'Passionate Kiss',
    'Cook Dinner',
    'Wildcard',
    'Truth',
    'Dare',
  ];
  String _selectedAction = '';

  @override
  void dispose() {
    _wheelController.close();
    super.dispose();
  }

  void _spinWheel() {
    final randomIndex = Fortune.randomInt(0, _wheelItems.length);
    _wheelController.add(randomIndex);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _selectedAction = _wheelItems[randomIndex];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Spin the Wheel of Intimacy!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Take turns spinning the wheel. Your fate is in the hands of the spin!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: FortuneWheel(
              selected: _wheelController.stream,
              items: [
                for (var item in _wheelItems)
                  FortuneItem(
                    child: Text(item,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: FortuneItemStyle(
                      color: _wheelItems.indexOf(item) % 2 == 0
                          ? AppTheme.accent
                          : AppTheme.purple,
                      borderColor: AppTheme.cardDark,
                      borderWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          if (_selectedAction.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Result: $_selectedAction 🎉',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _spinWheel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  'Spin Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOVE COUPONS ────────────────────────────────────────────────────────────
class LoveCouponsGame extends StatelessWidget {
  final String coupleId;
  const LoveCouponsGame({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style, size: 64, color: AppTheme.accent),
          const SizedBox(height: 16),
          const Text(
            'Love Coupons vault is coming soon!',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'A private booklet for favors & romantic treats.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── SPICY VIDEOS ────────────────────────────────────────────────────────────
class SpicyVideosGame extends StatelessWidget {
  final String coupleId;
  const SpicyVideosGame({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, size: 64, color: AppTheme.accent),
          const SizedBox(height: 16),
          const Text(
            'Spicy Stories Vault',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Strictly between you two.\nScreen recording is blocked.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => IntimateStoriesPage(coupleId: coupleId)));
            },
            icon: const Icon(Icons.local_fire_department, color: Colors.white),
            label: const Text('Enter Vault',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
    );
  }
}
