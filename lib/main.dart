import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'modules/app/provider/app_provider.dart';
import 'modules/app/provider/auth_provider.dart';
import 'modules/news/provider/bookmark_provider.dart';
import 'modules/news/provider/comment_provider.dart';
import 'modules/news/provider/news_provider.dart';
import 'modules/app/provider/notification_provider.dart';
import 'modules/app/service/auth_service.dart';
import 'modules/news/service/bookmark_service.dart';
import 'modules/news/service/cache_service.dart';
import 'modules/news/service/comment_service.dart';
import 'modules/news/service/news_service.dart';
import 'modules/app/service/notification_service.dart';
import 'modules/app/service/user_service.dart';
import 'modules/app/screens/main_navigation_screen.dart';
import 'modules/app/screens/onboarding_screen.dart';
import 'modules/app/screens/splash_screen.dart';

import 'package:audio_service/audio_service.dart' as bg;
import 'package:audio_session/audio_session.dart';

import 'modules/radio/provider/audio_provider.dart';
import 'modules/radio/service/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (error) {
    debugPrint('Firebase no disponible todavía: $error');
  }

  final app = AppProvider();
  final bookmarks = BookmarkProvider(BookmarkService());
  final news = NewsProvider(service: NewsService(), cache: CacheService());
  final searchNews = SearchNewsProvider(
    service: NewsService(),
    cache: CacheService(),
  );
  final notifications = NotificationProvider(NotificationService());

  await Future.wait([
    app.initialize(),
    bookmarks.initialize(),
    notifications.initialize(),
  ]);

  await bookmarks.startFirebaseSync(firebaseReady: firebaseReady);

  final audioHandler = await bg.AudioService.init<RadioAudioService>(
    builder: RadioAudioService.new,
    config: const bg.AudioServiceConfig(
      androidNotificationChannelId: 'com.radio_app.audio',
      androidNotificationChannelName: 'Radio en vivo',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: app),

        ChangeNotifierProvider<AudioProvider>(
          create: (_) => AudioProvider(audioHandler),
        ),

        ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarks),
        ChangeNotifierProvider<NewsProvider>.value(value: news),
        ChangeNotifierProvider<SearchNewsProvider>.value(value: searchNews),
        ChangeNotifierProvider<CommentProvider>(
          create: (_) => CommentProvider(CommentService()),
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notifications,
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            firebaseReady: firebaseReady,
            service: AuthService(),
            userService: UserService(),
          ),
        ),
      ],
      child: const AppNoticias(),
    ),
  );

  // Peticiones en segundo plano respecto a la UI
  news.initialize();
}

class AppNoticias extends StatelessWidget {
  const AppNoticias({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return MaterialApp(
      title: 'NEXO Noticias',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: app.themeMode,
      home: SplashScreen(
        nextScreen: context.watch<AuthProvider>().user == null
            ? const OnboardingScreen()
            : const MainNavigationScreen(),
      ),
    );
  }
}
