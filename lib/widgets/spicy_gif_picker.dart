import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class SpicyGifPickerSheet extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;
  final Function(String gifUrl) onGifSelected;

  const SpicyGifPickerSheet({
    super.key,
    required this.onEmojiSelected,
    required this.onGifSelected,
  });

  @override
  State<SpicyGifPickerSheet> createState() => _SpicyGifPickerSheetState();
}

class _SpicyGifPickerSheetState extends State<SpicyGifPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<String> _gifUrls = [];
  bool _isLoadingGifs = false;
  String _activeCategory = 'Romantic';

  final List<String> _categories = [
    'Romantic',
    'Kisses',
    'Spicy',
    'Cuddles',
    'Passionate',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGifs(_activeCategory);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Pre-scraped static URLs from Tenor since free v1 api is deprecated/rate-limited
  static const Map<String, List<String>> _staticGifs = {
    'Romantic': [
      "https://media.tenor.com/hxtGy76rRZUAAAAM/hold-me-hug.gif",
      "https://media.tenor.com/EtZptGgORdIAAAAM/intim-love.gif",
      "https://media.tenor.com/yX_vrzgzE70AAAAM/love.gif",
      "https://media.tenor.com/Q3fU2QsPnYEAAAAM/vyojasmine-kitaboy.gif",
      "https://media.tenor.com/IT6VY_NzVAkAAAAM/kissing-benedict-bridgerton.gif",
      "https://media.tenor.com/Um9znIPoP0cAAAAM/good-morning-my-love-good-morning-baby.gif",
      "https://media.tenor.com/Wkcpm8fO8lUAAAAM/love-kiss.gif",
      "https://media.tenor.com/jnZl9zhTMzQAAAAM/kisses-couple-kissing-couple.gif",
      "https://media.tenor.com/9IuynGgYlccAAAAM/love-hug.gif",
      "https://media.tenor.com/JNYhj8y31CkAAAAM/head-kiss-forehead-kiss.gif",
      "https://media.tenor.com/FD0y-HTcKa4AAAAM/candost-reqsdost.gif",
      "https://media.tenor.com/oroeHC-tvDAAAAAM/a%C5%9Fk.gif",
      "https://media.tenor.com/-qb6O5tQSS4AAAAM/hugss.gif",
      "https://media.tenor.com/L0f_xQBgj9gAAAAM/couple-couples.gif",
      "https://media.tenor.com/x6Y3rt6eOn4AAAAM/love-you-couple.gif",
      "https://media.tenor.com/CpLl3Cez6bkAAAAM/harshad-chopda-shivangi-joshi.gif",
      "https://media.tenor.com/fQIMP4wDPsIAAAAM/ravi-teja-sree-leela.gif",
      "https://media.tenor.com/TdphKzvAregAAAAM/kissing-sara-ali-khan.gif",
      "https://media.tenor.com/i0PCD5zjF8sAAAAM/romantic-moment-prajapati-pandey.gif",
      "https://media.tenor.com/bFTCMxSkmxAAAAAM/good-morning-love.gif"
    ],
    'Kisses': [
      "https://media.tenor.com/lXoRYgg3B8QAAAAM/kallis.gif",
      "https://media.tenor.com/yo8aSVqTZh0AAAAM/couple-kiss.gif",
      "https://media.tenor.com/4D-ZfRTF6cUAAAAM/zhanna-catman.gif",
      "https://media.tenor.com/bQ7YldB6AmkAAAAM/chris-mcnally-lucas-bouchard.gif",
      "https://media.tenor.com/Q3fU2QsPnYEAAAAM/vyojasmine-kitaboy.gif",
      "https://media.tenor.com/Um9znIPoP0cAAAAM/good-morning-my-love-good-morning-baby.gif",
      "https://media.tenor.com/Wkcpm8fO8lUAAAAM/love-kiss.gif",
      "https://media.tenor.com/eMv23M6njMgAAAAM/clav-clavicular.gif",
      "https://media.tenor.com/qvOpQG0youYAAAAM/kiss.gif",
      "https://media.tenor.com/ET7PewXFm1YAAAAM/forehead-kiss-kiss.gif",
      "https://media.tenor.com/RxbVuoVVFb8AAAAM/love-love-you.gif",
      "https://media.tenor.com/SbNedYlBJj4AAAAM/the-flash-barry-and-iris.gif",
      "https://media.tenor.com/HjaKhAwjjZgAAAAM/passionate-kiss-kiss.gif",
      "https://media.tenor.com/VlQhxus6BSkAAAAM/couple-kiss.gif",
      "https://media.tenor.com/f2Ln32GqGJYAAAAM/passionate-kiss-kiss.gif",
      "https://media.tenor.com/36US_0jvFeAAAAAM/sweet-kiss-couple.gif",
      "https://media.tenor.com/0ZCz6mWZaGMAAAAM/couple-kissing.gif",
      "https://media.tenor.com/P9nPwMoG2x4AAAAM/ladla-ladli-love-kissing.gif",
      "https://media.tenor.com/urRUmP220LAAAAAM/davydoff-love.gif",
      "https://media.tenor.com/TAjLQk5o3OQAAAAM/love-you.gif"
    ],
    'Spicy': [
      "https://media.tenor.com/R2q2dYam-8sAAAAM/i-love-you-so-much-heart.gif",
      "https://media.tenor.com/IbGXSb041Z4AAAAM/love.gif",
      "https://media.tenor.com/6xGa80rt280AAAAM/kiss-love.gif",
      "https://media.tenor.com/dGODTFWDsRoAAAAM/rikara-couple.gif",
      "https://media.tenor.com/eRrgl6MgfjcAAAAM/couple-hug-couple-embrace.gif",
      "https://media.tenor.com/Fk7d1fpfKXkAAAAM/couples-kisses.gif",
      "https://media.tenor.com/1b_NGHnM0bAAAAAM/happy-couple-romance.gif",
      "https://media.tenor.com/p1upWPJWZbgAAAAM/yash-kiara-advani.gif",
      "https://media.tenor.com/qFdOdMpkZjUAAAAM/cuddle-cuddling.gif",
      "https://media.tenor.com/_o0DPnx0GfYAAAAM/gifs-couples.gif",
      "https://media.tenor.com/-TWPCE3LJe4AAAAM/rrahul-rrahul-sudhir.gif",
      "https://media.tenor.com/rM1H7xaySKYAAAAM/sleeping-couple.gif",
      "https://media.tenor.com/eRtAyC915kIAAAAM/hold-me-in-your-arms-hug.gif",
      "https://media.tenor.com/JdllZUDrubAAAAAM/anupre-kasautii.gif",
      "https://media.tenor.com/OTO2a7oR8G0AAAAM/lingorm-lingling.gif",
      "https://media.tenor.com/bFTCMxSkmxAAAAAM/good-morning-love.gif",
      "https://media.tenor.com/GPTq8IWCo6EAAAAM/beyhadh2-beyhadh.gif",
      "https://media.tenor.com/EKw-pl5mi9MAAAAM/hug-sweet.gif",
      "https://media.tenor.com/JuQ3KFuOck4AAAAM/ranveeroberoi-viviandsena.gif",
      "https://media.tenor.com/aPmPywxuXpsAAAAM/foreheads-touching-jasmine.gif"
    ],
    'Cuddles': [
      "https://media.tenor.com/lIWzIIxdYpIAAAAM/couple-hug-couple.gif",
      "https://media.tenor.com/EtZptGgORdIAAAAM/intim-love.gif",
      "https://media.tenor.com/DpoJtAHH4HIAAAAM/couple-cuddle.gif",
      "https://media.tenor.com/hWK5LNy1IbsAAAAM/hugs-big-hugs.gif",
      "https://media.tenor.com/-JH5UH_9Yj4AAAAM/cute.gif",
      "https://media.tenor.com/Um9znIPoP0cAAAAM/good-morning-my-love-good-morning-baby.gif",
      "https://media.tenor.com/sbnd1sWhI54AAAAM/loving-couple-hugging.gif",
      "https://media.tenor.com/HpgBvVtLmSYAAAAM/love-you-too-i-love-you-too.gif",
      "https://media.tenor.com/qFdOdMpkZjUAAAAM/cuddle-cuddling.gif",
      "https://media.tenor.com/S-SRDW1QP1gAAAAM/foreheadkisses-love.gif",
      "https://media.tenor.com/_xlWkf6NAcQAAAAM/good-night-my-love.gif",
      "https://media.tenor.com/0PPpG_KDQ60AAAAM/couple-cuddle-cuddle.gif",
      "https://media.tenor.com/U3zZFsQ7bekAAAAM/bed-time.gif",
      "https://media.tenor.com/_kZHKRhYNgwAAAAM/giandara-gianmarco-onestini.gif",
      "https://media.tenor.com/bjDbWQw7MScAAAAM/ladla-ladli-hug-love-sleep.gif",
      "https://media.tenor.com/SmjpM_H5nnMAAAAM/cuddle-cute.gif",
      "https://media.tenor.com/Mgnyj0xFngEAAAAM/cuddle-anime.gif",
      "https://media.tenor.com/5lwdZ7QqLfoAAAAM/cuddle-cuddle-me.gif",
      "https://media.tenor.com/YK_Q83qSl7MAAAAM/couple-kiss-csfav.gif",
      "https://media.tenor.com/SFVft441040AAAAM/couple-couple-cuddle.gif"
    ],
    'Passionate': [
      "https://media.tenor.com/7ToFIh_2WhcAAAAM/davydoff-love.gif",
      "https://media.tenor.com/xVuP2EIszjAAAAAM/sweet-kiss-sensual-kiss.gif",
      "https://media.tenor.com/yo8aSVqTZh0AAAAM/couple-kiss.gif",
      "https://media.tenor.com/LDnSFEMTi2AAAAAM/davydoff-love.gif",
      "https://media.tenor.com/6pfM_2tiFcoAAAAM/heavy-breathing-romantic.gif",
      "https://media.tenor.com/aSZmZSKsSTUAAAAM/kiss-in-love.gif",
      "https://media.tenor.com/-HpgSB1IFUwAAAAM/black-couple.gif",
      "https://media.tenor.com/ZQtJSyY6yQgAAAAM/romantic.gif",
      "https://media.tenor.com/fkzCQDzzoDgAAAAM/romance-romantic.gif",
      "https://media.tenor.com/ZONCiRPXjUoAAAAM/dool-days-of-our-lives.gif",
      "https://media.tenor.com/uNVztCpYp1sAAAAM/love-couple.gif",
      "https://media.tenor.com/SqqyDbJwpO0AAAAM/hug-kiss-cheek.gif",
      "https://media.tenor.com/jbiT6nlNjf4AAAAM/couple-kiss.gif",
      "https://media.tenor.com/kp2vZWXcX48AAAAM/love-couple.gif",
      "https://media.tenor.com/JdmYc0SK8-4AAAAM/sweet-couple.gif",
      "https://media.tenor.com/5NydNk3aBuAAAAAM/love-you-love-you-images.gif",
      "https://media.tenor.com/QT3WZwojfNgAAAAM/the-vampire-diaries-tvd.gif",
      "https://media.tenor.com/i6MG22hhmQYAAAAM/hug-big.gif",
      "https://media.tenor.com/BEwIIP7oQ_0AAAAM/cute-hug.gif",
      "https://media.tenor.com/kjvNHt1WDx0AAAAM/love-couple.gif"
    ]
  };

  Future<void> _fetchGifs(String query) async {
    setState(() {
      _isLoadingGifs = true;
    });

    // Simulate small network delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        // Find matching category or fallback to search
        List<String> urls = _staticGifs[query] ?? [];

        if (urls.isEmpty) {
          // Flatten all urls and filter by matching keyword in url
          final allUrls = _staticGifs.values.expand((x) => x).toList();
          urls = allUrls
              .where((url) => url.toLowerCase().contains(query.toLowerCase()))
              .toList();
          // If still empty just return random ones
          if (urls.isEmpty) {
            urls = allUrls.take(15).toList();
          }
        }

        _gifUrls = urls;
        _isLoadingGifs = false;
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      _fetchGifs(query);
      setState(() {
        _activeCategory = '';
      });
    }
  }

  Widget _buildGifTab() {
    return Column(
      children: [
        // Top Search & Categories
        Container(
          color: AppTheme.surfaceDark,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search spicy GIFs...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: _onSearchSubmitted,
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isActive = _activeCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeCategory = category;
                          _searchController.clear();
                        });
                        _fetchGifs(category);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.accent : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.accent
                                : AppTheme.dividerColor,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Grid View
        Expanded(
          child: _isLoadingGifs
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent))
              : _gifUrls.isEmpty
                  ? const Center(
                      child: Text(
                        'No GIFs found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _gifUrls.length,
                      itemBuilder: (context, index) {
                        final url = _gifUrls[index];
                        return GestureDetector(
                          onTap: () {
                            widget.onGifSelected(url);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.cardDark,
                                child: const Center(
                                  child: Icon(Icons.favorite,
                                      color: AppTheme.dividerColor, size: 24),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.cardDark,
                                child: const Icon(Icons.broken_image,
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: "Emojis 😀"),
              Tab(text: "Spicy & Love GIFs 🔥"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Emoji Picker
                EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    widget.onEmojiSelected(emoji.emoji);
                  },
                ),
                // Tab 2: GIFs
                _buildGifTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
