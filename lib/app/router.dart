import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/pocket_motion.dart';
import '../core/widgets/floating_dock.dart';
import '../features/beans/add_bean_screen.dart';
import '../features/beans/bean_detail_screen.dart';
import '../features/beans/bean_library_screen.dart';
import '../features/brew_log/brew_log_detail_screen.dart';
import '../features/brew_log/brew_log_screen.dart';
import '../features/evaluation/evaluation_screen.dart';
import '../features/evaluation/sca_wheel_screen.dart';
import '../features/gear/add_custom_gear_screen.dart';
import '../features/gear/gear_screen.dart';
import '../features/home/home_screen.dart';
import '../features/learn/learn_beans_detail_screen.dart';
import '../features/learn/learn_hub_screen.dart';
import '../features/learn/learn_pour_detail_screen.dart';
import '../features/methods/methods_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/quick_brew/pour_stage_editor_screen.dart';
import '../features/quick_brew/quick_brew_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/timer/live_timer_screen.dart';

GoRouter createPocketRouter({String initialLocation = '/home'}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return _PocketShellScaffold(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return _AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beans',
                builder: (_, _) => const BeanLibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/brew',
                builder: (_, _) => const QuickBrewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                builder: (_, _) => const BrewLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gear',
                builder: (_, _) => const GearScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        pageBuilder: (_, state) => pocketModalPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/methods',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: const MethodsScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/brew/stages',
        pageBuilder: (_, state) => pocketModalPage(
          key: state.pageKey,
          child: PourStageEditorScreen(
            recipeId: state.uri.queryParameters['recipeId'],
            createNew: state.uri.queryParameters['new'] == '1',
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/timer',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: const LiveTimerScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/evaluation',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: const EvaluationScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/evaluation/wheel',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: ScaWheelScreen(
            initialTags: state.extra is List<String>
                ? state.extra as List<String>
                : null,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/log/:id',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: BrewLogDetailScreen(logId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/beans/add',
        pageBuilder: (_, state) => pocketModalPage(
          key: state.pageKey,
          child: const AddBeanScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/beans/edit/:id',
        pageBuilder: (_, state) => pocketModalPage(
          key: state.pageKey,
          child: AddBeanScreen(editBeanId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/beans/:id',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: BeanDetailScreen(beanId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/gear/add-custom',
        pageBuilder: (_, state) {
          final typeParam = state.uri.queryParameters['type'];
          final editId = state.uri.queryParameters['editId'];
          final initialType = switch (typeParam) {
            'dripper' => 1,
            'filter' => 2,
            _ => 0,
          };
          return pocketModalPage(
            key: state.pageKey,
            child: AddCustomGearScreen(
              initialType: initialType,
              editId: editId,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/learn',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: const LearnHubScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/learn/pour',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: const LearnPourDetailScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/learn/:topic',
        pageBuilder: (_, state) => pocketSlidePage(
          key: state.pageKey,
          child: LearnTopicDetailScreen(
            topic: state.pathParameters['topic'] ?? 'beans',
          ),
        ),
      ),
    ],
  );
}

final pocketRouter = createPocketRouter();

/// Silky directional micro-slide + crossfade branch switcher with per-tab RepaintBoundary,
/// preserving scroll state across all 5 tabs at 60fps on mobile web.
class _AnimatedBranchContainer extends StatefulWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer> {
  int _lastIndex = 0;

  @override
  void didUpdateWidget(covariant _AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _lastIndex = oldWidget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movingRight = widget.currentIndex >= _lastIndex;
    return Stack(
      children: List.generate(widget.children.length, (i) {
        final active = i == widget.currentIndex;
        final inactiveOffset = movingRight
            ? (i < widget.currentIndex
                ? const Offset(-0.03, 0)
                : const Offset(0.03, 0))
            : (i > widget.currentIndex
                ? const Offset(0.03, 0)
                : const Offset(-0.03, 0));
        return ExcludeSemantics(
          excluding: !active,
          child: IgnorePointer(
            ignoring: !active,
            child: RepaintBoundary(
              child: AnimatedSlide(
                offset: active ? Offset.zero : inactiveOffset,
                duration: const Duration(milliseconds: 240),
                curve: PocketCurves.smoothOut,
                child: AnimatedOpacity(
                  opacity: active ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 210),
                  curve: PocketCurves.smoothOut,
                  child: TickerMode(
                    enabled: active,
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PocketShellScaffold extends StatelessWidget {
  const _PocketShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PocketFloatingDock(
              currentIndex: navigationShell.currentIndex,
              onSelect: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
