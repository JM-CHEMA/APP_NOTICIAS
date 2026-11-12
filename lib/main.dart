import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'helpers/providers/app_provider.dart';
import 'helpers/providers/auth_provider.dart';
import 'helpers/providers/bookmark_provider.dart';
import 'helpers/providers/comment_provider.dart';
import 'helpers/providers/news_provider.dart';
import 'helpers/providers/notification_provider.dart';
import 'services/auth_service.dart';
import 'services/bookmark_service.dart';
import 'services/cache_service.dart';
import 'services/comment_service.dart';
import 'services/news_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: app),
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
