import 'package:flutter/material.dart';
import 'package:mt_dashboard/authentication/login_view.dart';
import 'package:mt_dashboard/firebase_options.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/publiccatalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart'; // Import DashboardView
import 'package:mt_dashboard/app/app.bottomsheets.dart';
import 'package:mt_dashboard/app/app.dialogs.dart';
import 'package:mt_dashboard/app/app.locator.dart';
import 'package:mt_dashboard/app/app.router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await setupLocator(stackedRouter: stackedRouter);
  setupDialogUi();
  setupBottomSheetUi();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AuthGate()); // Run AuthGate instead of MainApp directly
}

// A new widget to manage the authentication state and reconfigure GoRouter
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes
      builder: (context, snapshot) {
        // This is crucial: every time the user's auth state changes (login/logout),
        // a new GoRouter instance is created, forcing a re-evaluation of its routes and redirects.
        final GoRouter router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const LoginView(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardView(),
            ),
            GoRoute(
              path: '/:storename',
              name: 'public_catalogue_route',
              builder: (context, state) {
                final String? storename = state.pathParameters['storename'];
                if (storename != null && storename.isNotEmpty) {
                  return PublicCatalougeView(storename: storename);
                }
                return const StoreNotFoundView();
              },
            ),
            GoRoute(
              path: '/store_not_found',
              builder: (context, state) => const StoreNotFoundView(),
            ),
          ],
          redirect: (context, state) async {
            final User? user = FirebaseAuth.instance.currentUser;
            final bool loggedIn = user != null;

            final bool goingToLogin = state.fullPath == '/';

            // Allow public catalogue access even if not logged in
            final bool goingToPublicCatalogue = state.fullPath!.startsWith('/store_not_found') || state.fullPath!.contains('/:storename');

            if (!loggedIn && !goingToLogin && !goingToPublicCatalogue) {
              return '/'; // Redirect to login if not logged in and trying to access a protected route
            }

            if (loggedIn && goingToLogin) {
              return '/dashboard'; // Redirect to dashboard if logged in and trying to access login
            }

            // Existing store name check for public catalogue route
            final String? storename = state.pathParameters['storename'];
            if (storename != null && storename.isNotEmpty && !loggedIn) { // Only check if not logged in, logged in users might access via dashboard
              try {
                // Modified: Query 'storeUrl' instead of 'companyName'
                final QuerySnapshot result = await FirebaseFirestore.instance
                    .collection('users')
                    .where('storeUrl', isEqualTo: storename) // Use 'storeUrl' field
                    .limit(1)
                    .get();

                if (result.docs.isEmpty) {
                  return '/store_not_found';
                }
                return null;
              } catch (e) {
                print('Error checking storeUrl in Firestore: $e');
                return '/store_not_found';
              }
            }
            return null; // No redirect needed
          },
        );

        return MaterialApp.router(
          routerConfig: router, // Use the dynamically created router
          title: 'BizKit',
        );
      },
    );
  }
}

// A simple widget to display when a store is not found
class StoreNotFoundView extends StatelessWidget {
  const StoreNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Not Found')),
      body: const Center(
        child: Text('The store you are looking for does not exist or an error occurred.'),
      ),
    );
  }
}
