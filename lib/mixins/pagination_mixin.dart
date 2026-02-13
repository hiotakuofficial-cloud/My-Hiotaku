import 'package:flutter/material.dart';
import '../models/api_models.dart';

mixin PaginationMixin<T extends StatefulWidget> on State<T> {
  List<AnimeItem> animeList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(onScroll);
  }

  void onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore) {
        loadMoreData();
      }
    }
  }

  Future<void> loadInitialData() async {
    try {
      setState(() => isLoading = true);
      final data = await getPageData(1);
      setState(() {
        animeList = data.data;
        currentPage = 1;
        hasMore = data.data.length >= 20;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadMoreData() async {
    if (isLoadingMore || !hasMore) return;
    
    try {
      setState(() => isLoadingMore = true);
      final data = await getPageData(currentPage + 1);
      setState(() {
        animeList.addAll(data.data);
        currentPage++;
        hasMore = data.data.length >= 20;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
    }
  }

  Widget buildPaginatedGrid({
    required Widget Function(AnimeItem, int) itemBuilder,
    required String loadingText,
  }) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: animeList.length + (isLoadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= animeList.length) {
                return buildLoadingCard();
              }
              return itemBuilder(animeList[index], index);
            },
          ),
        ),
        if (isLoadingMore)
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  loadingText,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // Abstract method to be implemented by each page
  Future<HomeResponse> getPageData(int page);
}
