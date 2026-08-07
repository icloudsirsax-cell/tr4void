import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});

  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  Map<String, dynamic>? animeData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  // Define color scheme
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color lightRedColor = const Color(0xFFCD5C5C);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color greyColor = const Color(0xFF808080);

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
    _loadWatchHistory();
  }

  // Callback function to refresh history when updated from other pages
  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson
            .map((item) => Map<String, dynamic>.from(json.decode(item)))
            .toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> fetchAnimeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/home'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeData = jsonData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data anime');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> searchAnime(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/search/$query'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          searchResults = jsonData['search_results'] ?? [];
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() {
        searchResults = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: whiteColor),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Search anime...",
                hintStyle: TextStyle(color: greyColor),
                prefixIcon: Icon(Icons.search, color: greyColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: whiteColor),
                      onPressed: () {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          _searchFocusNode.unfocus();
                          searchAnime(query);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: greyColor),
                      onPressed: _clearSearch,
                    ),
                  ],
                )
                    : null,
                filled: true,
                fillColor: blackColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: darkRedColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: darkRedColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: lightRedColor),
                ),
              ),
              onSubmitted: (value) {
                final query = value.trim();
                if (query.isNotEmpty) {
                  _searchFocusNode.unfocus();
                  searchAnime(query);
                }
              },
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                ? _buildSearchResults()
                : animeData == null
                ? _buildErrorWidget()
                : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          fetchAnimeData(),
          _loadWatchHistory(),
        ]);
      },
      color: darkRedColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch History Section
            _buildSectionHeader(Icons.history, "Watch History"),
            const SizedBox(height: 12),

            // Show loading shimmer for history
            if (_isHistoryLoading)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: blackColor,
                        highlightColor: darkRedColor.withOpacity(0.3),
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: blackColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_watchHistory.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  "No watch history yet. Start watching an anime!",
                  style: TextStyle(
                    color: greyColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    final anime = _watchHistory[index];
                    return _buildHistoryCard(anime);
                  },
                ),
              ),

            // Quick Access Section
            _buildSectionHeader(Icons.dashboard, "Quick Access"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    "Genre",
                    Icons.category,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimeGenreListPage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    "Schedule",
                    Icons.schedule,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimeSchedulePage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ongoing Anime Section
            _buildSectionHeader(Icons.live_tv, "Currently Airing"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['ongoing_anime']),
            const SizedBox(height: 24),

            // Complete Anime Section
            _buildSectionHeader(Icons.check_circle, "Completed Series"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['complete_anime']),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: darkRedColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> anime) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (anime['last_watched_episode_slug'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeEpisodePage(
                  episodeSlug: anime['last_watched_episode_slug'],
                  animeSlug: anime['slug'],
                  animeTitle: anime['title'],
                  animePoster: anime['poster'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: anime['slug'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    anime['poster'],
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 120,
                      color: blackColor,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: greyColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: blackColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: whiteColor,
                      size: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          blackColor,
                        ],
                      ),
                    ),
                    child: Text(
                      anime['last_watched_episode'] ?? '',
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              anime['title'],
              style: TextStyle(
                color: whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "No results found",
              style: TextStyle(
                color: greyColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try with different keywords",
              style: TextStyle(
                color: greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final anime = searchResults[index];
        return _buildSearchResultCard(anime);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String? rating = anime['rating'];
    final String? type = anime['type'];
    final String? status = anime['status'];
    final String? episodeCount = anime['episode_count'];
    final List<dynamic> genres = anime['genres'] ?? [];
    final String slug = _extractSlugFromUrl(anime['slug']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: blackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkRedColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(
                slug: slug,
                onHistoryUpdate: refreshHistory,
              ),
            ),
          ).then((_) => refreshHistory());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  poster,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 120,
                    color: blackColor,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported,
                      color: greyColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating and Type
                    Row(
                      children: [
                        if (rating != null && rating.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: lightRedColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (type != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: darkRedColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Status and Episode
                    Row(
                      children: [
                        if (status != null) ...[
                          Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (episodeCount != null) ...[
                          Text(
                            "$episodeCount Episodes",
                            style: TextStyle(
                              color: greyColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Genres
                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: darkRedColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre['name'],
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return lightRedColor;
      case 'completed':
        return darkRedColor;
      default:
        return greyColor;
    }
  }

  String _extractSlugFromUrl(String url) {
    try {
      final animeIndex = url.indexOf('/anime/');
      if (animeIndex != -1) {
        String slugPart = url.substring(animeIndex + 7);

        if (slugPart.endsWith('/')) {
          slugPart = slugPart.substring(0, slugPart.length - 1);
        }

        return slugPart;
      }

      return url;
    } catch (e) {
      debugPrint('Error extracting slug: $e');
      return url;
    }
  }

  Widget _buildAnimeGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final anime = list[index];
        final String title = anime['title'];
        final String poster = anime['poster'];
        final String? episode = anime['current_episode'] ?? anime['episode_count'];
        final String? date = anime['newest_release_date'] ?? anime['last_release_date'];
        final String slug = anime['slug'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: slug,
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          },
          child: Container(
            decoration: BoxDecoration(
              color: blackColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: darkRedColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    poster,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 170,
                      color: blackColor,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: greyColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: whiteColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    episode ?? "-",
                    style: TextStyle(
                      fontSize: 12,
                      color: greyColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "Updated: $date",
                    style: TextStyle(
                      fontSize: 11,
                      color: greyColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: blackColor,
        highlightColor: darkRedColor.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            color: blackColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: greyColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load data",
            style: TextStyle(
              color: greyColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Future.wait([
                fetchAnimeData(),
                _loadWatchHistory(),
              ]);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkRedColor,
              foregroundColor: whiteColor,
            ),
            child: Text("Try Again"),
          ),
        ],
      ),
    );
  }
}

class AnimeDetailPage extends StatefulWidget {
  final String slug;
  final Function()? onHistoryUpdate;

  const AnimeDetailPage({super.key, required this.slug, this.onHistoryUpdate});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  // Define color scheme
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color lightRedColor = const Color(0xFFCD5C5C);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color greyColor = const Color(0xFF808080);

  Map<String, dynamic>? animeDetail;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetail();
  }

  Future<void> fetchAnimeDetail() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/anime/${widget.slug}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeDetail = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: blackColor,
        iconTheme: IconThemeData(color: whiteColor),
        title: Text(
          "Anime Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || animeDetail == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load anime details",
              style: TextStyle(
                color: greyColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchAnimeDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRedColor,
                foregroundColor: whiteColor,
              ),
              child: Text("Try Again"),
            ),
          ],
        ),
      )
          : _buildAnimeDetail(),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: blackColor,
            highlightColor: darkRedColor.withOpacity(0.3),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: blackColor,
            highlightColor: darkRedColor.withOpacity(0.3),
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: blackColor,
            highlightColor: darkRedColor.withOpacity(0.3),
            child: Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeDetail() {
    final anime = animeDetail!;
    final List<dynamic> episodes = anime['episode_lists'] ?? [];
    final List<dynamic> recommendations = anime['recommendations'] ?? [];
    final List<dynamic> genres = anime['genres'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster dan Info Dasar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  anime['poster'],
                  height: 200,
                  width: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: 140,
                    color: blackColor,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported,
                      color: greyColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime['japanese_title'] ?? '-',
                      style: TextStyle(
                        fontSize: 14,
                        color: greyColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: lightRedColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          anime['rating'] ?? '-',
                          style: TextStyle(color: whiteColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('Type', anime['type']),
                    _buildInfoItem('Status', anime['status']),
                    _buildInfoItem('Episodes', anime['episode_count']),
                    _buildInfoItem('Duration', anime['duration']),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Genres
          if (genres.isNotEmpty) ...[
            Text(
              "Genres",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map<Widget>((genre) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeGenrePage(
                          genreSlug: genre['slug'],
                          genreName: genre['name'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: darkRedColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      genre['name'],
                      style: TextStyle(color: whiteColor, fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Sinopsis
          if (anime['synopsis'] != null) ...[
            Text(
              "Synopsis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: darkRedColor.withOpacity(0.3)),
              ),
              child: Text(
                anime['synopsis'],
                style: TextStyle(
                  color: whiteColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Daftar Episode
          if (episodes.isNotEmpty) ...[
            Text(
              "Episodes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: blackColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: darkRedColor.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: darkRedColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          episode['episode_number'].toString(),
                          style: TextStyle(color: whiteColor, fontSize: 12),
                        ),
                      ),
                    ),
                    title: Text(
                      episode['episode'],
                      style: TextStyle(color: whiteColor, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeEpisodePage(
                            episodeSlug: episode['slug'],
                            animeSlug: widget.slug,
                            animeTitle: anime['title'],
                            animePoster: anime['poster'],
                            episodes: episodes,
                            recommendations: recommendations,
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) {
                        if (widget.onHistoryUpdate != null) {
                          widget.onHistoryUpdate!();
                        }
                      });
                    },
                    trailing: Icon(Icons.play_arrow, color: whiteColor),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Batch Download (jika ada)
          if (anime['batch'] != null) ...[
            Container(
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: darkRedColor.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.download,
                  color: whiteColor,
                ),
                title: Text(
                  "Download Batch",
                  style: TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Upload: ${anime['batch']['uploaded_at']}",
                  style: TextStyle(
                    color: greyColor,
                  ),
                ),
                onTap: () => _launchURL(anime['batch']['otakudesu_url']),
                trailing: Icon(Icons.arrow_forward_ios, color: whiteColor, size: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Rekomendasi
          if (recommendations.isNotEmpty) ...[
            Text(
              "Recommendations",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation = recommendations[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailPage(
                            slug: recommendation['slug'],
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) {
                        if (widget.onHistoryUpdate != null) {
                          widget.onHistoryUpdate!();
                        }
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              recommendation['poster'],
                              height: 160,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                width: 120,
                                color: blackColor,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: greyColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation['title'],
                            style: TextStyle(
                              color: whiteColor,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: greyColor,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value ?? '-',
              style: TextStyle(
                color: whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimeGenrePage extends StatefulWidget {
  final String genreSlug;
  final String genreName;

  const AnimeGenrePage({
    super.key,
    required this.genreSlug,
    required this.genreName,
  });

  @override
  State<AnimeGenrePage> createState() => _AnimeGenrePageState();
}

class _AnimeGenrePageState extends State<AnimeGenrePage> {
  // Define color scheme
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color lightRedColor = const Color(0xFFCD5C5C);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color greyColor = const Color(0xFF808080);

  List<dynamic> animeList = [];
  Map<String, dynamic>? pagination;
  bool isLoading = true;
  bool isError = false;
  int currentPage = 1;

  Future<void> fetchGenreAnime({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/genre/${widget.genreSlug}?page=$page'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeList = jsonData['data']['anime'];
          pagination = jsonData['data']['pagination'];
          isLoading = false;
          currentPage = page;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: blackColor,
        iconTheme: IconThemeData(color: whiteColor),
        title: Text(
          "Genre: ${widget.genreName}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load genre data",
              style: TextStyle(
                color: greyColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => fetchGenreAnime(),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRedColor,
                foregroundColor: whiteColor,
              ),
              child: Text("Try Again"),
            ),
          ],
        ),
      )
          : _buildGenreContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: blackColor,
          highlightColor: darkRedColor.withOpacity(0.3),
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: blackColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenreContent() {
    return Column(
      children: [
        // Pagination Info
        if (pagination != null) _buildPaginationInfo(),

        // Anime List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return _buildAnimeCard(anime);
            },
          ),
        ),

        // Pagination Controls
        if (pagination != null) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkRedColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Page $currentPage of ${pagination!['last_visible_page']}",
            style: TextStyle(
              color: greyColor,
              fontSize: 12,
            ),
          ),
          Text(
            "Total: ${animeList.length} anime",
            style: TextStyle(
              color: greyColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final hasNext = pagination!['has_next_page'] ?? false;
    final hasPrev = pagination!['has_previous_page'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          if (hasPrev)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage - 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRedColor,
                foregroundColor: whiteColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text("Previous"),
                ],
              ),
            ),

          const SizedBox(width: 16),

          // Next Button
          if (hasNext)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRedColor,
                foregroundColor: whiteColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next"),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String rating = anime['rating'] ?? '-';
    final String episodeCount = anime['episode_count']?.toString() ?? '?';
    final String season = anime['season'] ?? '-';
    final String studio = anime['studio'] ?? '-';
    final String synopsis = anime['synopsis'] ?? '';
    final String slug = anime['slug'];
    final List<dynamic> genres = anime['genres'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: blackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkRedColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(slug: slug),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  poster,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 140,
                    color: blackColor,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported,
                      color: greyColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Rating and Episode
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: lightRedColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "$episodeCount Episodes",
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Season and Studio
                    Text(
                      "$season • $studio",
                      style: TextStyle(
                        color: greyColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Genres
                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: darkRedColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre['name'],
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Synopsis (short)
                    if (synopsis.isNotEmpty) ...[
                      Text(
                        synopsis,
                        style: TextStyle(
                          color: greyColor,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimeSchedulePage extends StatefulWidget {
  const AnimeSchedulePage({super.key});

  @override
  State<AnimeSchedulePage> createState() => _AnimeSchedulePageState();
}

class _AnimeSchedulePageState extends State<AnimeSchedulePage> {
  // Define color scheme
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color lightRedColor = const Color(0xFFCD5C5C);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color greyColor = const Color(0xFF808080);

  List<dynamic> scheduleData = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/schedule'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          scheduleData = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: blackColor,
        iconTheme: IconThemeData(color: whiteColor),
        title: Text(
          "Release Schedule",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? _buildErrorWidget()
          : _buildScheduleContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: blackColor,
          highlightColor: darkRedColor.withOpacity(0.3),
          child: Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: blackColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: greyColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load release schedule",
            style: TextStyle(
              color: greyColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkRedColor,
              foregroundColor: whiteColor,
            ),
            child: Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: scheduleData.length,
      itemBuilder: (context, index) {
        final daySchedule = scheduleData[index];
        final String day = daySchedule['day'];
        final List<dynamic> animeList = daySchedule['anime_list'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: blackColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: darkRedColor.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: darkRedColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${animeList.length} Anime",
                      style: TextStyle(
                        color: greyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Anime List
                if (animeList.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: animeList.length,
                      itemBuilder: (context, animeIndex) {
                        final anime = animeList[animeIndex];
                        final String title = anime['anime_name'];
                        final String poster = anime['poster'];
                        final String slug = anime['slug'];

                        return Container(
                          width: 120,
                          margin: EdgeInsets.only(
                            right: animeIndex == animeList.length - 1 ? 0 : 12,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimeDetailPage(slug: slug),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Poster
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    poster,
                                    width: 120,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 160,
                                      color: blackColor,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: greyColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Title
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: whiteColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimeGenreListPage extends StatefulWidget {
  const AnimeGenreListPage({super.key});

  @override
  State<AnimeGenreListPage> createState() => _AnimeGenreListPageState();
}

class _AnimeGenreListPageState extends State<AnimeGenreListPage> {
  // Define color scheme
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color lightRedColor = const Color(0xFFCD5C5C);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color greyColor = const Color(0xFF808080);

  List<dynamic> genreList = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchGenreList() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/genre/'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          genreList = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching genre list: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: blackColor,
        iconTheme: IconThemeData(color: whiteColor),
        title: Text(
          "Anime Genres",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? _buildErrorWidget()
          : _buildGenreGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: blackColor,
          highlightColor: darkRedColor.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              color: blackColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: greyColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load genre list",
            style: TextStyle(
              color: greyColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchGenreList,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkRedColor,
              foregroundColor: whiteColor,
            ),
            child: Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: genreList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        final genre = genreList[index];
        final String name = genre['name'];
        final String slug = genre['slug'];

        return Container(
          decoration: BoxDecoration(
            color: blackColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: darkRedColor.withOpacity(0.3)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeGenrePage(
                    genreSlug: slug,
                    genreName: name,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimeEpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? animeSlug;
  final String? animeTitle;
  final String? animePoster;
  final List<dynamic>? episodes;
  final List<dynamic>? recommendations;
  final Function()? onHistoryUpdate;

  const AnimeEpisodePage({
    super.key,
    required this.episodeSlug,
    this.animeSlug,
    this.animeTitle,
    this.animePoster,
    this.episodes,
    this.recommendations,
    this.onHistoryUpdate,
  });

  @override
  State<AnimeEpisodePage> createState() => _AnimeEpisodePageState();
}

class _AnimeEpisodePageState extends State<AnimeEpisodePage> with WidgetsBindingObserver {
  // Define color scheme
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color lightRedColor = const Color(0xFFCD5C5C);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color greyColor = const Color(0xFF808080);

  Map<String, dynamic>? episodeData;
  bool isLoading = true;
  bool isError = false;
  int _currentTabIndex = 0;

  // WebView Controller
  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _isFullScreen = false;

  // Current episode index
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEpisodeData();
    _findCurrentEpisodeIndex();
  }

  void _findCurrentEpisodeIndex() {
    if (widget.episodes != null) {
      for (int i = 0; i < widget.episodes!.length; i++) {
        if (widget.episodes![i]['slug'] == widget.episodeSlug) {
          setState(() {
            _currentEpisodeIndex = i;
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Kembali ke portrait ketika halaman ditutup
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Mendeteksi perubahan ukuran layar (fullscreen)
    final physicalSize = WidgetsBinding.instance.window.physicalSize;
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final logicalSize = physicalSize / pixelRatio;

    // Jika lebar lebih besar dari tinggi, berarti landscape
    final isNowFullScreen = logicalSize.width > logicalSize.height;

    if (isNowFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = isNowFullScreen;
      });

      if (_isFullScreen) {
        // Lock ke landscape ketika fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // Kembali ke portrait ketika keluar fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  Future<void> fetchEpisodeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/episode/${widget.episodeSlug}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          episodeData = jsonData['data'];
        });

        // Initialize WebView dengan custom headers
        _initializeWebView();

        // Add to watch history
        _addToWatchHistory();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _addToWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      List<Map<String, dynamic>> watchHistory = historyJson
          .map((item) => Map<String, dynamic>.from(json.decode(item)))
          .toList();

      // Create history item
      final historyItem = {
        'slug': widget.animeSlug,
        'title': widget.animeTitle,
        'poster': widget.animePoster,
        'last_watched_episode': episodeData?['episode'],
        'last_watched_episode_slug': widget.episodeSlug,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Remove if already exists to avoid duplicates
      watchHistory.removeWhere((item) => item['slug'] == widget.animeSlug);

      // Add to beginning of list
      watchHistory.insert(0, historyItem);

      // Keep only last 20 items
      if (watchHistory.length > 20) {
        watchHistory = watchHistory.sublist(0, 20);
      }

      // Save to preferences
      final newHistoryJson = watchHistory.map((item) => json.encode(item)).toList();
      await prefs.setStringList('watch_history', newHistoryJson);

      // Trigger history update callback if provided
      if (widget.onHistoryUpdate != null) {
        widget.onHistoryUpdate!();
      }
    } catch (e) {
      debugPrint('Error saving to watch history: $e');
    }
  }

  void _initializeWebView() {
    if (episodeData == null) return;

    final streamUrl = episodeData!['stream_url'];

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(blackColor)
      ..addJavaScriptChannel(
        'FullScreen',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle fullscreen events dari JavaScript
          if (message.message == 'enter') {
            _enterFullScreen();
          } else if (message.message == 'exit') {
            _exitFullScreen();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isWebViewLoading = false;
              });

              // Inject JavaScript untuk mendeteksi fullscreen changes
              _injectFullScreenDetection();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isWebViewLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isWebViewLoading = false;
            });
            _injectFullScreenDetection();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isWebViewLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(streamUrl),
        headers: _getChromeHeaders(),
      );
  }

  void _injectFullScreenDetection() {
    _webViewController.runJavaScript('''
      // Deteksi perubahan fullscreen untuk video elements
      function handleFullScreenChange() {
        if (document.fullscreenElement || document.webkitFullscreenElement || 
            document.mozFullScreenElement || document.msFullscreenElement) {
          FullScreen.postMessage('enter');
        } else {
          FullScreen.postMessage('exit');
        }
      }

      // Tambahkan event listeners untuk fullscreen changes
      document.addEventListener('fullscreenchange', handleFullScreenChange);
      document.addEventListener('webkitfullscreenchange', handleFullScreenChange);
      document.addEventListener('mozfullscreenchange', handleFullScreenChange);
      document.addEventListener('MSFullscreenChange', handleFullScreenChange);

      // Juga monitor video elements untuk click events
      document.addEventListener('click', function(e) {
        if (e.target.tagName === 'VIDEO' || e.target.closest('video')) {
          // Jika video diklik, mungkin akan masuk fullscreen
          setTimeout(handleFullScreenChange, 100);
        }
      });

      // Monitor untuk touch events pada mobile
      document.addEventListener('touchend', function(e) {
        if (e.target.tagName === 'VIDEO' || e.target.closest('video')) {
          setTimeout(handleFullScreenChange, 100);
        }
      });

      // Monitor untuk key events (ESC untuk keluar fullscreen)
      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
          setTimeout(handleFullScreenChange, 100);
        }
      });

      console.log('Fullscreen detection injected');
    ''');
  }

  void _enterFullScreen() {
    if (!_isFullScreen) {
      setState(() {
        _isFullScreen = true;
      });

      // Lock orientation ke landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Sembunyikan system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitFullScreen() {
    if (_isFullScreen) {
      setState(() {
        _isFullScreen = false;
      });

      // Kembali ke portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Tampilkan system UI kembali
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Map<String, String> _getChromeHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
    };
  }

  void _refreshWebView() {
    setState(() {
      _isWebViewLoading = true;
    });
    _webViewController.reload();
  }

  void _openInExternalBrowser() {
    if (episodeData != null) {
      final streamUrl = episodeData!['stream_url'];
      _launchURL(streamUrl);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDownloadOptions() {
    if (episodeData == null || episodeData!['download_urls'] == null) return;

    final downloadUrls = episodeData!['download_urls'];
    showModalBottomSheet(
      context: context,
      backgroundColor: blackColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Download Episode",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: whiteColor,
                  ),
                ),
                const SizedBox(height: 16),

                if (downloadUrls['mp4'] != null) ...[
                  Text(
                    "MP4 Format",
                    style: TextStyle(
                      color: whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildDownloadOptionsList(downloadUrls['mp4']),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDownloadOptionsList(List<dynamic> formats) {
    List<Widget> widgets = [];

    for (final format in formats) {
      final resolution = format['resolution'];
      final urls = format['urls'] as List<dynamic>;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: darkRedColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            leading: Icon(Icons.hd, color: whiteColor),
            title: Text(
              resolution,
              style: TextStyle(
                color: whiteColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: urls.map<Widget>((urlData) {
              return ListTile(
                leading: _getProviderIcon(urlData['provider']),
                title: Text(
                  urlData['provider'],
                  style: TextStyle(color: whiteColor, fontSize: 12),
                ),
                subtitle: Text(
                  "Click to download",
                  style: TextStyle(color: greyColor, fontSize: 10),
                ),
                onTap: () => _launchURL(urlData['url']),
                trailing: Icon(Icons.download, color: whiteColor, size: 20),
              );
            }).toList(),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'odfiles':
        return Icon(Icons.storage, color: lightRedColor, size: 20);
      case 'pdrain':
        return Icon(Icons.cloud_download, color: lightRedColor, size: 20);
      case 'acefile':
        return Icon(Icons.folder, color: lightRedColor, size: 20);
      case 'gofile':
        return Icon(Icons.file_copy, color: lightRedColor, size: 20);
      case 'mega':
        return Icon(Icons.cloud, color: lightRedColor, size: 20);
      case 'kfiles':
        return Icon(Icons.archive, color: lightRedColor, size: 20);
      default:
        return Icon(Icons.download, color: whiteColor, size: 20);
    }
  }

  void _goToNextEpisode() {
    if (widget.episodes != null && _currentEpisodeIndex < widget.episodes!.length - 1) {
      final nextEpisode = widget.episodes![_currentEpisodeIndex + 1];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeEpisodePage(
            episodeSlug: nextEpisode['slug'],
            animeSlug: widget.animeSlug,
            animeTitle: widget.animeTitle,
            animePoster: widget.animePoster,
            episodes: widget.episodes,
            recommendations: widget.recommendations,
            onHistoryUpdate: widget.onHistoryUpdate,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      appBar: _isFullScreen ? null : AppBar(
        backgroundColor: blackColor,
        iconTheme: IconThemeData(color: whiteColor),
        title: Text(
          episodeData?['episode'] ?? "Streaming Anime",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: whiteColor,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (episodeData != null) ...[
            IconButton(
              icon: Icon(Icons.refresh, color: whiteColor),
              onPressed: _refreshWebView,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: Icon(Icons.open_in_browser, color: whiteColor),
              onPressed: _openInExternalBrowser,
              tooltip: 'Open in Browser',
            ),
            if (episodeData!['download_urls'] != null)
              IconButton(
                onPressed: _showDownloadOptions,
                icon: Icon(Icons.download, color: whiteColor),
                tooltip: 'Download',
              ),
          ],
        ],
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || episodeData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load episode",
              style: TextStyle(
                color: greyColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchEpisodeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRedColor,
                foregroundColor: whiteColor,
              ),
              child: Text("Try Again"),
            ),
          ],
        ),
      )
          : _buildStreamingContent(),
    );
  }

  Widget _buildStreamingContent() {
    final List<dynamic> episodes = widget.episodes ?? [];
    final List<dynamic> recommendations = widget.recommendations ?? [];
    final List<dynamic> genres = [];

    return Column(
      children: [
        // Video Player Section - Sesuaikan height berdasarkan fullscreen
        Container(
          height: _isFullScreen
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.height * 0.35,
          width: double.infinity,
          color: blackColor,
          child: Stack(
            children: [
              WebViewWidget(controller: _webViewController),

              if (_isWebViewLoading)
                Container(
                  color: blackColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: darkRedColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Loading video player...",
                          style: TextStyle(
                            color: whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tombol exit fullscreen manual (fallback)
              if (_isFullScreen)
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: blackColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.fullscreen_exit, color: whiteColor, size: 30),
                    ),
                    onPressed: _exitFullScreen,
                  ),
                ),
            ],
          ),
        ),

        // Sembunyikan tab bar ketika fullscreen
        if (!_isFullScreen) ...[
          // Tab Bar
          Container(
            height: 50,
            color: blackColor,
            child: Row(
              children: [
                _buildTabButton(0, Icons.playlist_play, 'Episodes'),
                _buildTabButton(1, Icons.recommend, 'Recommendations'),
                _buildTabButton(2, Icons.category, 'Genres'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                // Tab 1: Episode List
                _buildEpisodeList(episodes),

                // Tab 2: Recommendations
                _buildRecommendations(recommendations),

                // Tab 3: Genres
                _buildGenresList(genres),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: Material(
        color: isSelected ? darkRedColor : blackColor,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTabIndex = index;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? whiteColor : greyColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? whiteColor : greyColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeList(List<dynamic> episodes) {
    if (episodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "No episodes available",
              style: TextStyle(
                color: greyColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Next Episode Button
        if (_currentEpisodeIndex < episodes.length - 1)
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _goToNextEpisode,
              icon: Icon(Icons.skip_next),
              label: Text("Next Episode"),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRedColor,
                foregroundColor: whiteColor,
              ),
            ),
          ),

        // Episode List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              final isCurrentEpisode = episode['slug'] == widget.episodeSlug;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentEpisode
                      ? darkRedColor
                      : blackColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: darkRedColor.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrentEpisode
                          ? whiteColor.withOpacity(0.2)
                          : darkRedColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        episode['episode_number'].toString(),
                        style: TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    episode['episode'],
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (!isCurrentEpisode) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeEpisodePage(
                            episodeSlug: episode['slug'],
                            animeSlug: widget.animeSlug,
                            animeTitle: widget.animeTitle,
                            animePoster: widget.animePoster,
                            episodes: widget.episodes,
                            recommendations: widget.recommendations,
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      );
                    }
                  },
                  trailing: Icon(
                    isCurrentEpisode ? Icons.play_arrow : Icons.play_circle_outline,
                    color: whiteColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "No recommendations available",
              style: TextStyle(
                color: greyColor,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: recommendation['slug'],
                  onHistoryUpdate: widget.onHistoryUpdate,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: blackColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: darkRedColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    recommendation['poster'],
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: blackColor,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: greyColor,
                      ),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['title'],
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Rating jika ada
                      if (recommendation['rating'] != null && recommendation['rating'].toString().isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.star, color: lightRedColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              recommendation['rating'],
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenresList(List<dynamic> genres) {
    if (genres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category,
              color: greyColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "No genres available",
              style: TextStyle(
                color: greyColor,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Anime Genres",
            style: TextStyle(
              color: whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map<Widget>((genre) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnimeGenrePage(
                        genreSlug: genre['slug'],
                        genreName: genre['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: darkRedColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    genre['name'],
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Info tambahan tentang anime
          if (widget.animeTitle != null) ...[
            Text(
              "Anime Info",
              style: TextStyle(
                color: whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: blackColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: darkRedColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.animePoster ?? '',
                      height: 80,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        width: 60,
                        color: blackColor,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported,
                          color: greyColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.animeTitle ?? '',
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Shimmer.fromColors(
            baseColor: blackColor,
            highlightColor: darkRedColor.withOpacity(0.3),
            child: Container(
              color: blackColor,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
  final Color blackColor = const Color(0xFF000000);
  final Color darkRedColor = const Color(0xFF8B0000);
  final Color whiteColor = const Color(0xFFFFFFFF);

  return Container(
    decoration: BoxDecoration(
      color: blackColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: darkRedColor.withOpacity(0.3)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: darkRedColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: whiteColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}