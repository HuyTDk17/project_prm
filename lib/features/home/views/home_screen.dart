import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../auth/views/auth_prompt.dart';
import '../../library/viewmodels/library_viewmodel.dart';
import '../../library/views/library_page.dart';
import '../../notification/viewmodels/notification_viewmodel.dart';
import '../../studio/viewmodels/studio_viewmodel.dart';
import '../../notification/views/notifications_page.dart';
import '../../profile/views/profile_page.dart';
import '../../studio/views/studio_page.dart';
import 'feed_page.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Main shell: bottom bar on phones, navigation rail on wide windows.
/// Everybody sees the same tabs; guests are asked to log in on protected ones.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _home = _Destination('Home', Icons.home_outlined, Icons.home_rounded);
  static const _library =
      _Destination('Library', Icons.video_library_outlined, Icons.video_library_rounded);
  static const _alerts =
      _Destination('Alerts', Icons.notifications_none_rounded, Icons.notifications_rounded);
  static const _profile =
      _Destination('Profile', Icons.person_outline_rounded, Icons.person_rounded);
  static const _studio =
      _Destination('Studio', Icons.movie_creation_outlined, Icons.movie_creation_rounded);

  /// Icon of a destination; the Alerts tab shows the number of unread notifications.
  Widget _icon(_Destination d, bool selected, int unread) {
    final icon = Icon(selected ? d.selectedIcon : d.icon);
    if (d.label == 'Alerts' && unread > 0) return Badge(label: Text('$unread'), child: icon);
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    // Press "/" on the keyboard to open the search page.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () => context.push(RouteNames.search),
      },
      child: Focus(autofocus: true, child: _shell(context)),
    );
  }

  Widget _shell(BuildContext context) {
    final destinations = [_home, _library, _alerts, _profile, _studio];
    final unread = context.select<NotificationViewModel, int>((n) => n.unread);
    final index = _index.clamp(0, destinations.length - 1);

    // Guests see Home and can watch; the other tabs ask them to log in.
    final pages = <Widget>[
      const FeedPage(),
      const AuthGate(
        icon: Icons.video_library_outlined,
        title: 'Your library',
        message: 'Log in to see your history, liked videos and subscriptions.',
        child: LibraryPage(),
      ),
      const AuthGate(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        message: 'Log in to get notified about new videos and comments.',
        child: NotificationsPage(),
      ),
      const AuthGate(
        icon: Icons.person_outline_rounded,
        title: 'Your account',
        message: 'Log in to see your profile and your channels.',
        child: ProfilePage(),
      ),
      const AuthGate(
        icon: Icons.movie_creation_outlined,
        title: 'Upload and manage videos',
        message: 'Log in to upload videos and manage your channel.',
        child: StudioPage(),
      ),
    ];
    final body = IndexedStack(index: index, children: pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        void select(int i) {
          setState(() => _index = i);
          // Reload the data of the tab that was opened.
          if (i == 1) context.read<LibraryViewModel>().refresh();
          if (i == 2) context.read<NotificationViewModel>().refresh();
          if (i == 4) context.read<StudioViewModel>().refresh();
        }

        if (constraints.maxWidth >= Responsive.railMin) {
          final extended = constraints.maxWidth >= Responsive.railExtendedMin;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: select,
                  extended: extended,
                  labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: BrandLogo(size: 40, showWordmark: extended),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: _icon(d, false, unread),
                        selectedIcon: _icon(d, true, unread),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: select,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: _icon(d, false, unread),
                  selectedIcon: _icon(d, true, unread),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
