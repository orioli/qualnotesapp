// Copyright 2023 Jose Berengueres

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/home/account_info.dart';
import 'package:qualnotes/src/home/home_page.dart';
import 'package:qualnotes/src/home/policy_screen.dart';
import 'package:qualnotes/src/interview/interview.dart';
import 'package:qualnotes/src/interview/interview_player.dart';
import 'package:qualnotes/src/interview/recording_sate.dart';
import 'package:qualnotes/src/interview/walking_interview.dart';
import 'package:qualnotes/src/interview/widgets/image_view.dart';
import 'package:qualnotes/src/invites_universities/academic_email_required.dart';
import 'package:qualnotes/src/map_controller_service.dart';
import 'package:qualnotes/src/mapping/play_map.dart';
import 'package:qualnotes/src/pobs/make_obs.dart';
import 'package:qualnotes/src/project/project_tabs.dart';
import 'package:qualnotes/src/project/team/accept_invite.dart';
import 'package:qualnotes/src/project/team/invite_widgets.dart';
import 'package:qualnotes/src/project/setup/consent/consent_screen.dart';
import 'package:qualnotes/src/schedule/schedule.dart';
import 'package:qualnotes/src/schedule/schedule_select.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:qualnotes/src/verify_email.dart';
import 'firebase_options.dart';
import 'src/app_state.dart';

void main() async {
  debugPrint("is kIsweb ? " + kIsWeb.toString());
  debugPrint("DefaultFirebaseOptions.currentPlatform? " +
      DefaultFirebaseOptions.currentPlatform.toString());

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // name: 'qnweb-5f924',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ApplicationState()),
        ChangeNotifierProvider(create: (context) => MapLocationService()),
        ChangeNotifierProvider(
            create: (context) => RecordingState()), // added this line
      ],
      child: const App(),
    ),
  );
}

ThemeData themeData(BuildContext context) {
  return ThemeData(
    buttonTheme: Theme.of(context).buttonTheme.copyWith(
          highlightColor: Colors.blue,
        ),
    primarySwatch: Colors.blueGrey,
    secondaryHeaderColor: Colors.blue,
    textTheme: GoogleFonts.robotoTextTheme(
      Theme.of(context).textTheme,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Strings.yourProjects,
      theme: themeData(context),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      name: 'root',
      path: '/',
      builder: (context, state) {
        var appState = Provider.of<ApplicationState>(context);
        if (appState.userId != null) {
          debugPrint("1 appState.userId != null");
          if (appState.loggedIn && !appState.emailVerified) {
            // TODO: here we coudl use the firebase_ui_auth package VerifySscreen I just doen know how to make it work with goRouter and also i cant find the ActionCodeSettings in the codebase
            debugPrint("appState.loggedIn && !appState.emailVerified");
            return VerifyEmailPlease();
          }
          debugPrint(
              " 2 else ... appState.loggedIn && !appState.emailVerified " +
                  appState.loggedIn.toString() +
                  " " +
                  appState.emailVerified.toString());

          return HomePage();
        }
        debugPrint("3  going to sign in screen");
        debugPrint(" 4 else ... appState.loggedIn && !appState.emailVerified " +
            appState.loggedIn.toString() +
            " " +
            appState.emailVerified.toString());
        return SignInScreen(
          actions: mySigninActions,
          headerBuilder: headerImage('assets/images/icon.jpg'),
          sideBuilder: sideImage('assets/images/icon.jpg'),
        );
      },
      routes: [
        GoRoute(
          name: 'home',
          path: 'home',
          builder: (context, state) {
            return HomePage();
          },
        ),
        GoRoute(
          name: 'veryemail',
          path: 'veryemail',
          builder: (context, state) {
            return VerifyEmailPlease();
          },
        ),
        GoRoute(
          name: 'sign-in',
          path: 'sign-in',
          builder: (context, state) {
            return SignInScreen(
              actions: mySigninActions,
              headerBuilder: headerImage('assets/images/icon.jpg'),
              sideBuilder: sideImage('assets/images/icon.jpg'),
            );
          },
          routes: [
            GoRoute(
              name: 'forgot-password',
              path: 'forgot-password',
              builder: (context, state) {
                final arguments = state.queryParams;
                return ForgotPasswordScreen(
                  email: arguments['email'],
                  headerMaxExtent: 200,
                );
              },
            ),
            GoRoute(
              name: 'ac-email-req',
              path: 'ac-email-req',
              builder: (context, state) =>
                  NotWhitelistedScreen(email: state.queryParams['email'] ?? ''),
            ),
          ],
        ),
        GoRoute(
          name: 'playMap',
          path: 'playMap',
          builder: (context, state) => PlayMap(
            map_id: state.queryParams['map_id'] ?? '',
            title: state.queryParams['title'] ?? '',
            prj_id: state.queryParams['prj_id'] ?? '',
          ),
        ),
        GoRoute(
          name: 'makeMap',
          path: 'makeMap',
          builder: (context, state) => MakeObs(
            title: state.queryParams['title'] ?? '',
            prj_id: state.queryParams['prj_id'] ?? '',
            obs_id: state.queryParams['map_id'] ??
                '', // Assuming you use 'map_id' as 'obs_id' in MakeObs
            editExistingPoints: state.queryParams['editExistingPoints'] ?? '',
            showMap: true, // Set showMap to true
          ),
        ),
        GoRoute(
          name: 'makeWalkingMap',
          path: 'makeWalkingMap',
          builder: (context, state) => WalkingInterview(
            prj_id: state.queryParams['prj_id'] ?? '',
            sch_id: state.queryParams['sch_id'] ?? '',
          ),
        ),
        GoRoute(
          name: 'makeObservation',
          path: 'makeObservation',
          builder: (context, state) => MakeObs(
              prj_id: state.queryParams['prj_id'] ?? "",
              obs_id: state.queryParams['obs_id'] ?? "",
              title: state.queryParams['title'] ?? "",
              editExistingPoints:
                  state.queryParams['editExistingPoints'] ?? ''),

          //dataModel: state.extra as List?,
        ),
        GoRoute(
          name: 'makeSchedule',
          path: 'makeSchedule',
          builder: (context, state) => Schedule(
            prj_id: state.queryParams['prj_id'] ?? "",
            sch_id: state.queryParams['schedule_id'] ?? "",
            title: state.queryParams['schedule_title'] ?? "",

            //dataModel: state.extra as List?,
          ),
        ),
        GoRoute(
          name: 'select-schedule',
          path: 'select-schedule',
          builder: (context, state) => ScheduleSelect(
            prj_id: state.queryParams['prj_id'] ?? '',
            type: state.queryParams['type'] ?? '',
          ),
        ),
        GoRoute(
          name: 'interview',
          path: 'interview',
          builder: (context, state) => Interview(
            prj_id: state.queryParams['prj_id'] ?? '',
            sch_id: state.queryParams['sch_id'] ?? '',
          ),
        ),
        GoRoute(
          name: 'interview_play',
          path: 'interview_play',
          builder: (context, state) => InterviewPlayer(
            prj_id: state.queryParams['prj_id'] ?? '',
            interview_id: state.queryParams['interview_id'] ?? '',
            interview_title: state.queryParams['interview_title'] ?? '',
            recording: state.queryParams['recording'] ?? '',
            questionsJson: state.queryParams['questions'] ?? '',
          ),
        ),
        GoRoute(
          name: 'consent',
          path: 'consent',
          builder: (context, state) =>
              ConsentScreen(prj_id: state.extra as String),
        ),
        GoRoute(
          name: 'project',
          path: 'project',
          builder: (context, state) => ProjectTabs(
            prj_id: state.queryParams['prj_id'] ?? '',
            prj_title: state.queryParams['prj_title'] ?? '',
            active_tab: state.queryParams['active_tab'] ?? '',
          ),
        ),
        GoRoute(
          name: 'imageViewer',
          path: 'imageViewer',
          builder: (context, state) => ImageViewer(
            image: state.queryParams['image'] ?? '',
          ),
        ),
        GoRoute(
          name: 'profile',
          path: 'profile',
          builder: (context, state) {
            return Consumer<ApplicationState>(
              builder: (context, appState, _) => ProfileScreen(
                key: ValueKey(appState.emailVerified),
                providers: const [],
                actions: [
                  SignedOutAction(
                    ((context) {
                      context.replace('/');
                    }),
                  ),
                ],
                children: [
                  Visibility(
                      visible: !appState.emailVerified,
                      child: OutlinedButton(
                        child: const Text(Strings.recheckVerificationState),
                        onPressed: () {
                          appState.refreshLoggedInUser();
                        },
                      ))
                ],
              ),
            );
          },
        ),
        GoRoute(
          name: 'scanner',
          path: 'scanner',
          builder: (context, state) {
            return QRInviteScanner();
          },
        ),
        // this to accept invite from url link (Whatasp...)
        GoRoute(
          name: 'accept-invitation',
          path: 'accept-invitation/:token',
          builder: (context, state) {
            String token = state.params['token']!;
            return AcceptInvitationScreen(token: token);
          },
        ),
        // this to accept invite from scanned qr code...
        GoRoute(
          name: 'accept-invitation-in-app',
          path: 'accept-invitation-in-app', //TODO: Why not /:token here?
          builder: (context, state) {
            // state.queryParams or state.params as above...
            final token = state.queryParams['token'];
            if (token != null) {
              return AcceptInvitationScreen(token: token);
            } else {
              debugPrint("scanned token was null");
              return HomePage();
            }
          },
        ),
        GoRoute(
          name: 'account',
          path: 'account',
          builder: (context, state) {
            return AccountScreen();
          },
        ),
        GoRoute(
          name: 'privacy-policy',
          path: 'privacy-policy',
          pageBuilder: (context, state) {
            return MaterialPage(child: PrivacyPolicyScreen());
          },
        ),
      ],
    ),
  ],
);

List<FirebaseUIAction> get mySigninActions {
  return [
    ForgotPasswordAction(((context, email) {
      final uri = Uri(
        path: '/sign-in/forgot-password',
        queryParameters: <String, String?>{
          'email': email,
        },
      );
      context.push(uri.toString());
    })),
    AuthStateChangeAction(((context, state) async {
      if (state is SignedIn || state is UserCreated) {
        var user = (state is SignedIn)
            ? state.user
            : (state as UserCreated).credential.user;
        //debugPrint("user in sign in action... = " + user.toString());

        if (user == null) {
          //  debugPrint("user == null " + user.toString());

          return;
        } else if (state is UserCreated) {
          debugPrint("state is UserCreated ");
          //debugPrint("user in sign in action... = " + user.toString());
        }

        if (!user.emailVerified) {
          debugPrint("sending verif ");

          user.sendEmailVerification();
          context.replace('/veryemail');
        }
        context.replace('/');
      }
    })),
  ];
}

HeaderBuilder headerImage(String assetName) {
  //debugPrint("headerImage was called");
  return (context, constraints, _) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Image.asset(assetName),
    );
  };
}

SideBuilder sideImage(String assetName) {
  return (context, constraints) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(constraints.maxWidth / 4),
        child: Image.asset(assetName),
      ),
    );
  };
}
