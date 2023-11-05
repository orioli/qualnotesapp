import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:qualnotes/src/widgets/add_title_dialouge.dart'
    show myTitleDialog;
import '../app_state.dart';
import 'home_project_list.dart';
import 'home_drawer_menu.dart';
import 'invited_project_list.dart';
import '../widgets/widgets.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      appBar: AppBar(
        title: const Text('🏠 Your projects'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: <Widget>[
          Consumer<ApplicationState>(
            builder: (context, appState, _) {
              if (appState.loggedIn) {
                return IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    GoRouter.of(context).go('/scanner');
                  },
                );
              } else {
                return SizedBox
                    .shrink(); // returns an empty box which takes as little space as possible
              }
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          _onAddProjectButtonPressed(context);
        },
        backgroundColor: Colors.blue,
        label: const Text('Project'),
        icon: const Icon(Icons.add),
      ),
      /*
      floatingActionButton: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          if (appState.loggedIn) {
            final accountAge = (appState.lastSignInTime!)
                .difference(appState.creationTime!)
                .inDays;
            final trialExpired = accountAge > 14;
//            debugPrint("planType... " + appState.planType.toString());
            return FloatingActionButton(
                onPressed: () async {
                  if (true || trialExpired || (appState.planType == "pro")) {
                    _onAddProjectButtonPressed(context);
                  } else {
                    showUpgradeDialog(context).then((_) {
                      _onAddProjectButtonPressed(context);
                    });
                  }
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add));
          } else {
            return SizedBox.shrink();
          }
        },
      ),*/
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          debugPrint(
              "HomePage builder. User is... " + appState.loggedIn.toString());
          if (!appState.loggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/sign-in');
            });
          } else if (appState.emailVerified == true) {
            return HomePageBody();
          } else if (appState.emailVerified == false) {
            return Text("emailnot verified");
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }

  Future<void> _onAddProjectButtonPressed(BuildContext context) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Consumer<ApplicationState>(
        builder: (context, appState, _) => myTitleDialog(
          onPress: (val) async {
            await appState.addProject(val).then((doc_prj) async {
              //Navigator.of(context, rootNavigator: true).pop();

              context.pushNamed('project', queryParams: {
                'prj_id': doc_prj.id,
                //'prj_title': (await doc_prj.get()).get('title')
                'prj_title': (await doc_prj.get()).get('title')
              });
            });
          },
          title: Strings.projectTitle,
          hint: Strings.projectTitleHint,
        ),
      ),
    );
  }
}

String formatEmail(String email) {
  String domain =
      email.split('@').last; // Extract the domain part after the @ symbol
  String formattedDomain =
      domain.replaceAll('.', '.'); // Replace dots with spaces
  return formattedDomain;
}

class VerifyEmailSVP extends StatelessWidget {
  const VerifyEmailSVP({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(builder: (context, appState, _) {
      return SingleChildScrollView(
        child: Column(
          children: [
            Paragraph(
                "Your are logged in but you need to verify your email first. We have sent you a link by email wiht a link to verify your email. Check your spam folder?"),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // This makes the button red
              ),
              child: Text('click here once verified'),
              onPressed: () async {
                // Sign out the user and make him log in agian
                // TODO user verify-email --- but its not working well issues with permission to retrieve plan in auth token not verfied in time ?
                appState.signOut();
                GoRouter.of(context).go('/sign-in');
              },
            ),
          ],
        ),
      );
    });
  }
}

class HomePageBody extends StatelessWidget {
  const HomePageBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProjectList(),
          InvitedProjectList(),
        ],
      ),
    );
  }
}
