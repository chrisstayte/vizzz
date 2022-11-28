import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatelessWidget {
  InfoScreen({super.key});

  String _version = 'not found';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vizz Info'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: FaIcon(FontAwesomeIcons.twitter),
            title: Text('@ChrisStayte'),
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.twitter.com/ChrisStayte',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
          ),
          ListTile(
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'mailto',
                path: 'vizzz@chrisstayte.com',
                query: 'subject=App Feedback ($_version)',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            leading: FaIcon(FontAwesomeIcons.solidEnvelope),
            title: Text('vizzz@chrisstayte.com'),
          ),
          ListTile(
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.github.com/chrisstayte/vizzz',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
            leading: FaIcon(FontAwesomeIcons.github),
            title: Text('Github'),
          ),
          ListTile(
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.chrisstayte.app/vizzz/privacy',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
            leading: FaIcon(FontAwesomeIcons.lock),
            title: Text('Privacy Policy'),
          ),
          ListTile(
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.chrisstayte.app/vizzz/terms',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
            leading: FaIcon(FontAwesomeIcons.fileContract),
            title: Text('Terms of Service'),
          ),
          ListTile(
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.chrisstayte.app/vizzz',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
            leading: FaIcon(FontAwesomeIcons.globe),
            title: Text('Website'),
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.circleInfo),
            title: FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (context, AsyncSnapshot<PackageInfo> snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  _version =
                      '${snapshot.data!.version} (${snapshot.data!.buildNumber})';
                  return Text(
                    _version,
                  );
                } else {
                  return Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  );
                }
              },
            ),
          ),
          const ListTile(
            leading: Icon(Icons.flutter_dash),
            title: Text('Made with Flutter'),
          ),
          AboutListTile(
            icon: FaIcon(FontAwesomeIcons.fileCircleQuestion),
          ),
        ],
      ),
    );
  }
}
