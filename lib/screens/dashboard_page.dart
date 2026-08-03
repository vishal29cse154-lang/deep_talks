import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_alert_service.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo_viewer.dart';
import 'chat_page.dart';
import 'call_page.dart';
import 'couple_games_page.dart';
import 'memory_vault_page.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _cloudinaryService = CloudinaryService();

  UserModel? _currentUser;
  UserModel? _partner;
  CoupleModel? _couple;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final user = await _firestoreService.getUser(uid);
    if (user != null && user.partnerId.isNotEmpty) {
      final partner = await _firestoreService.getUser(user.partnerId);
      setState(() {
        _currentUser = user;
        _partner = partner;
      });
      NotificationAlertService().startListening(user.uid, user.coupleId);
    } else {
      setState(() => _currentUser = user);
    }
  }

  int _daysTogether() {
    if (_couple?.anniversaryDate == null) return 0;
    return DateTime.now().difference(_couple!.anniversaryDate!).inDays;
  }

  Future<void> _updateProfilePicture() async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = await _cloudinaryService.uploadMedia(pickedFile.path);
      if (url != null) {
        await _firestoreService.updateProfilePicture(uid, url);
        _loadData();
      }
    }
  }

  Future<void> _pickAnniversary() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _couple?.anniversaryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              surface: AppTheme.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && _currentUser?.coupleId != null) {
      await _firestoreService.updateAnniversaryDate(
        _currentUser!.coupleId,
        date,
      );
      _loadData();
    }
  }

  void _navigate(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentUser == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : CustomScrollView(
              slivers: [
                // ─── Gradient App Bar ────────────────────────────────
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: true,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: FlexibleSpaceBar(
                      title: const Text(
                        'DeepTalks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => _navigate(SettingsPage()),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ─── Couple Header Card ──────────────────────
                        _buildCoupleHeader()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.1),

                        const SizedBox(height: 20),

                        // ─── Days Together Card ─────────────────────
                        _buildDaysTogetherCard()
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 500.ms)
                            .slideY(begin: 0.1),

                        const SizedBox(height: 20),

                        // ─── Mood Tracker ───────────────────────────
                        _buildMoodTracker()
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 500.ms)
                            .slideY(begin: 0.1),

                        const SizedBox(height: 20),

                        // ─── Send Love Pulse ────────────────────────
                        _buildLovePulseButton()
                            .animate()
                            .fadeIn(delay: 250.ms, duration: 500.ms)
                            .scale(begin: const Offset(0.8, 0.8)),

                        const SizedBox(height: 24),

                        // ─── Quick Actions Grid ─────────────────────
                        _buildQuickActions().animate().fadeIn(
                              delay: 300.ms,
                              duration: 500.ms,
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCoupleHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // My avatar
              _buildAvatar(
                _currentUser?.photoUrl ?? '',
                _currentUser?.safeDisplayName ?? 'Me',
                isMe: true,
              ),
              const SizedBox(width: 16),
              // Heart icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Partner avatar
              _buildAvatar(
                _partner?.photoUrl ?? '',
                _partner?.safeDisplayName ?? 'Partner',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_currentUser?.safeDisplayName ?? "You"} & ${_partner?.safeDisplayName ?? "Partner"}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '💕 Your private space for love & memories',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String photoUrl, String name, {bool isMe = false}) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (photoUrl.isNotEmpty) {
              ProfilePhotoViewer.show(
                context: context,
                heroTag: 'dashboard_avatar_$name',
                photoUrl: photoUrl,
                displayName: name,
              );
            }
          },
          child: Hero(
            tag: 'dashboard_avatar_$name',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accent, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.surfaceDark,
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (isMe)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _updateProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDaysTogetherCard() {
    return StreamBuilder<CoupleModel?>(
      stream: _currentUser?.coupleId != null
          ? _firestoreService.coupleStream(_currentUser!.coupleId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        _couple = snapshot.data;
        final days = _daysTogether();
        final hasDate = _couple?.anniversaryDate != null;

        return GestureDetector(
          onTap: _pickAnniversary,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.12),
                  AppTheme.purple.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.accent,
                  size: 28,
                ),
                const SizedBox(height: 12),
                if (hasDate) ...[
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Days Together 💕',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Since ${DateFormat('MMM d, yyyy').format(_couple!.anniversaryDate!)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Set Your Anniversary',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to set your special date',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodTracker() {
    final moods = [
      {'icon': '😊', 'label': 'Happy'},
      {'icon': '🥰', 'label': 'Romantic'},
      {'icon': '🫂', 'label': 'Cuddly'},
      {'icon': '🔥', 'label': 'Spicy'},
      {'icon': '😴', 'label': 'Tired'},
      {'icon': '😡', 'label': 'Angry'},
    ];

    String currentMood = _currentUser?.mood ?? '';
    String currentMoodNote = _currentUser?.moodNote ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling?',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: moods.map((mood) {
              final isSelected = currentMood == mood['label'];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () async {
                    if (_currentUser != null) {
                      await _firestoreService.updateUserMood(
                          _currentUser!.uid, mood['label'] as String);
                      _loadData();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : AppTheme.cardDark,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(mood['icon'] as String,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Why are you feeling this way? Add a note...',
            hintStyle:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            filled: true,
            fillColor: AppTheme.cardDark,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          controller: TextEditingController(text: currentMoodNote),
          onSubmitted: (note) async {
            if (_currentUser != null) {
              await _firestoreService.updateUserMoodNote(
                  _currentUser!.uid, note.trim());
              _loadData();
            }
          },
        ),
        if (_partner?.mood != null && _partner!.mood!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: AppTheme.purple, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_partner!.safeDisplayName} is feeling ${_partner!.mood}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (_partner!.moodNote != null && _partner!.moodNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
              child: Text(
                '"${_partner!.moodNote}"',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ]
      ],
    );
  }

  Widget _buildLovePulseButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        // Send a haptic / visual hug
        if (_partner != null) {
          await _firestoreService.sendLovePulse(_partner!.uid);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Vibe check sent to ${_partner!.safeDisplayName}! 💕'),
                backgroundColor: AppTheme.accent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            );
          }
        }
      },
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Send Love Pulse',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.chat_bubble_rounded,
        label: 'Chat',
        color: const Color(0xFF25D366),
        onTap: () => _navigate(ChatPage(coupleId: _currentUser!.coupleId)),
      ),
      _QuickAction(
        icon: Icons.videocam_rounded,
        label: 'Video Call',
        color: const Color(0xFF4A90D9),
        onTap: () => _navigate(
          CallPage(coupleId: _currentUser!.coupleId, isVideo: true),
        ),
      ),
      _QuickAction(
        icon: Icons.phone_rounded,
        label: 'Voice Call',
        color: const Color(0xFFFFA726),
        onTap: () => _navigate(
          CallPage(coupleId: _currentUser!.coupleId, isVideo: false),
        ),
      ),
      _QuickAction(
        icon: Icons.casino_rounded,
        label: 'Games',
        color: AppTheme.accent,
        onTap: () =>
            _navigate(CoupleGamesPage(coupleId: _currentUser!.coupleId)),
      ),
      _QuickAction(
        icon: Icons.photo_library_rounded,
        label: 'Memory Vault',
        color: const Color(0xFFE040FB),
        onTap: () =>
            _navigate(MemoryVaultPage(coupleId: _currentUser!.coupleId)),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: actions.map((action) {
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: action.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, color: action.color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  action.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
