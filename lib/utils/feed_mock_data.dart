class FeedStoryItem {
  final String id;
  final String imageUrl;
  final String? caption;
  final String? time;
  bool isLiked;
  final List<String> reactions;

  FeedStoryItem({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.time,
    this.isLiked = false,
    List<String>? reactions,
  }) : reactions = reactions ?? [];
}

class FeedStory {
  final String id;
  final String username;
  final String imageUrl;
  final bool isLive;
  final String timeAgo;
  final bool isAddStory;
  bool isViewed;
  final List<FeedStoryItem> items;

  FeedStory({
    required this.id,
    required this.username,
    required this.imageUrl,
    this.isLive = false,
    required this.timeAgo,
    this.isAddStory = false,
    this.isViewed = false,
    List<FeedStoryItem>? items,
  }) : items = items ?? [
          FeedStoryItem(id: '${id}_1', imageUrl: imageUrl, time: timeAgo),
        ];
}

class FeedPost {
  final String id;
  final String username;
  final String location;
  final String avatarUrl;
  final String imageUrl;
  final int commentsCount;
  final int sharesCount;
  final int likesCount;
  final String captionTitle;
  final String captionBody;
  final String musicTitle;
  final String musicArtist;
  final String musicCoverUrl;
  final List<String> likedByAvatars;
  final String likedByText;
  final bool isVideo;
  final String? videoUrl;

  FeedPost({
    required this.id,
    required this.username,
    required this.location,
    required this.avatarUrl,
    required this.imageUrl,
    required this.commentsCount,
    required this.sharesCount,
    required this.likesCount,
    required this.captionTitle,
    required this.captionBody,
    required this.musicTitle,
    required this.musicArtist,
    required this.musicCoverUrl,
    required this.likedByAvatars,
    required this.likedByText,
    this.isVideo = false,
    this.videoUrl,
  });
}

class PickedPost {
  final String id;
  final String imageUrl;
  final String avatarUrl;
  final String tag;
  final String postsCount;

  PickedPost({
    required this.id,
    required this.imageUrl,
    required this.avatarUrl,
    required this.tag,
    required this.postsCount,
  });
}

class FeedMockData {
  static List<FeedStory> getStories() {
    return [
      FeedStory(
        id: 'add',
        username: 'Share\na moment',
        imageUrl: '',
        timeAgo: '',
        isAddStory: true,
      ),
      FeedStory(
        id: '1',
        username: 'sierra.skye',
        imageUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=600&auto=format&fit=crop',
        isLive: true,
        timeAgo: 'Live now',
        items: [
          FeedStoryItem(
            id: 's1_1',
            imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=600&auto=format&fit=crop',
            caption: 'Live streaming sunset photoshoot 🌅',
            time: 'Just now',
          ),
          FeedStoryItem(
            id: 's1_2',
            imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=600&auto=format&fit=crop',
            caption: 'Behind the lens setup 📸',
            time: '5m ago',
          ),
          FeedStoryItem(
            id: 's1_3',
            imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
            caption: 'Final edit looks insane ✨',
            time: '12m ago',
          ),
        ],
      ),
      FeedStory(
        id: '2',
        username: 'rohan.xo',
        imageUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=600&auto=format&fit=crop',
        timeAgo: '2m ago',
        items: [
          FeedStoryItem(
            id: 's2_1',
            imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=600&auto=format&fit=crop',
            caption: 'Early morning flight route ✈️',
            time: '2m ago',
          ),
          FeedStoryItem(
            id: 's2_2',
            imageUrl: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=600&auto=format&fit=crop',
            caption: 'Above the clouds ☁️',
            time: '15m ago',
          ),
        ],
      ),
      FeedStory(
        id: '3',
        username: 'anaya.live',
        imageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
        timeAgo: '12m ago',
        items: [
          FeedStoryItem(
            id: 's3_1',
            imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
            caption: 'Studio lighting vibes 💡',
            time: '12m ago',
          ),
          FeedStoryItem(
            id: 's3_2',
            imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600&auto=format&fit=crop',
            caption: 'Collab with tech team 💻',
            time: '25m ago',
          ),
        ],
      ),
      FeedStory(
        id: '4',
        username: 'jaden.wrld',
        imageUrl:
            'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=600&auto=format&fit=crop',
        timeAgo: '45m ago',
        items: [
          FeedStoryItem(
            id: 's4_1',
            imageUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=600&auto=format&fit=crop',
            caption: 'Mountain hike adventure 🏔️',
            time: '45m ago',
          ),
          FeedStoryItem(
            id: 's4_2',
            imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=600&auto=format&fit=crop',
            caption: 'Reaching the summit! 🚀',
            time: '1h ago',
          ),
          FeedStoryItem(
            id: 's4_3',
            imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=600&auto=format&fit=crop',
            caption: 'Camping under the stars ⭐',
            time: '2h ago',
          ),
        ],
      ),
      FeedStory(
        id: '5',
        username: 'ella.bloom',
        imageUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=600&auto=format&fit=crop',
        timeAgo: '1h ago',
        items: [
          FeedStoryItem(
            id: 's5_1',
            imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=600&auto=format&fit=crop',
            caption: 'City walks in rain 🌧️',
            time: '1h ago',
          ),
          FeedStoryItem(
            id: 's5_2',
            imageUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?q=80&w=600&auto=format&fit=crop',
            caption: 'Coffee break & coding ☕',
            time: '3h ago',
          ),
        ],
      ),
    ];
  }

  static List<FeedPost> getPosts() {
    return [
      FeedPost(
        id: 'post1',
        username: 'dev.shots',
        location: 'Kyoto, Japan',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
        imageUrl:
            'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=1200&auto=format&fit=crop',
        commentsCount: 128,
        sharesCount: 342,
        likesCount: 12800,
        captionTitle: 'Kyoto nights hit different ✨ ⛩️',
        captionBody: 'always finding peace in random places.',
        musicTitle: 'Night Drive',
        musicArtist: 'Kavinsky',
        musicCoverUrl:
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=150&auto=format&fit=crop',
        likedByAvatars: [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=100&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=100&auto=format&fit=crop',
        ],
        likedByText: 'Liked by anaya.live and 12.8K others',
      ),
      FeedPost(
        id: 'post2',
        username: 'sunsetvibes',
        location: 'Santa Monica, CA',
        avatarUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=150&auto=format&fit=crop',
        imageUrl:
            'https://images.unsplash.com/photo-1505159940484-eb2b9f2588e2?q=80&w=1200&auto=format&fit=crop',
        commentsCount: 84,
        sharesCount: 120,
        likesCount: 9400,
        captionTitle: 'Golden hour at the pier 🌅',
        captionBody: 'catching the last rays of the day.',
        musicTitle: 'Sunset Lover',
        musicArtist: 'Petit Biscuit',
        musicCoverUrl:
            'https://images.unsplash.com/photo-1557672172-298e090bd0f1?q=80&w=150&auto=format&fit=crop',
        likedByAvatars: [
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=100&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=100&auto=format&fit=crop',
        ],
        likedByText: 'Liked by rohan.xo and 9.4K others',
        isVideo: true,
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      ),
    ];
  }

  static List<PickedPost> getPickedPosts() {
    return [
      PickedPost(
        id: 'pick1',
        imageUrl:
            'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?q=80&w=400&auto=format&fit=crop',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=100&auto=format&fit=crop',
        tag: '#sunsetbae',
        postsCount: '12.4K posts',
      ),
      PickedPost(
        id: 'pick2',
        imageUrl:
            'https://images.unsplash.com/photo-1511300636408-a63a89df3482?q=80&w=400&auto=format&fit=crop',
        avatarUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=100&auto=format&fit=crop',
        tag: '#citylights',
        postsCount: '8.1K posts',
      ),
      PickedPost(
        id: 'pick3',
        imageUrl:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=400&auto=format&fit=crop',
        avatarUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=100&auto=format&fit=crop',
        tag: '#coffeelove',
        postsCount: '5.1K posts',
      ),
      PickedPost(
        id: 'pick4',
        imageUrl:
            'https://images.unsplash.com/photo-1498307833015-e7b400441eb8?q=80&w=400&auto=format&fit=crop',
        avatarUrl:
            'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=100&auto=format&fit=crop',
        tag: '#moodygeo',
        postsCount: '6.8K posts',
      ),
    ];
  }
}
