//
// Generated file. Do not edit.
//

// ignore: unused_import
import 'dart:ui';

import 'package:catcher/core/catcher_web.dart';
import 'package:fluttertoast/fluttertoast_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(PluginRegistry registry) {
  CatcherWeb.registerWith(registry.registrarFor(CatcherWeb));
  FluttertoastWebPlugin.registerWith(registry.registrarFor(FluttertoastWebPlugin));
  registry.registerMessageHandler();
}
