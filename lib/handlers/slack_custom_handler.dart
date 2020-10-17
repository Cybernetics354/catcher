import 'package:catcher/model/report_handler.dart';
import 'package:catcher/model/platform_type.dart';
import 'package:catcher/model/report.dart';
import 'package:catcher/utils/catcher_utils.dart';
import 'package:dio/dio.dart';
import 'package:indonesia/indonesia.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

class SlackCustomHandler extends ReportHandler {
  final Dio _dio = Dio();
  final Logger _logger = Logger("SlackHandler");

  final String webhookUrl;
  final String channel;
  final String username;
  final String iconEmoji;

  final bool printLogs;
  final bool enableDeviceParameters;
  final bool enableApplicationParameters;
  final bool enableStackTrace;
  final bool enableCustomParameters;

  SlackCustomHandler(this.webhookUrl, this.channel,
      {this.username = "Catcher",
      this.iconEmoji = ":bangbang:",
      this.printLogs = false,
      this.enableDeviceParameters = false,
      this.enableApplicationParameters = false,
      this.enableStackTrace = false,
      this.enableCustomParameters = false})
      : assert(webhookUrl != null, "webhookUrl can't be null"),
        assert(channel != null, "channel can't be null"),
        assert(username != null, "username can't be null"),
        assert(enableDeviceParameters != null,
            "enableDeviceParameters can't be null"),
        assert(enableApplicationParameters != null,
            "enableApplicationParameters can't be null"),
        assert(enableStackTrace != null, "enableStackTrace can't be null"),
        assert(enableCustomParameters != null,
            "enableCustomParameters can't be null"),
        assert(printLogs != null, "printLogs can't be null");

  @override
  Future<bool> handle(Report report) async {
    try {
      if (!(await CatcherUtils.isInternetConnectionAvailable())) {
        _printLog("No internet connection available");
        return false;
      }

      // String message = _buildMessage(report);
      Map message = _buildNewMessage(report);
      message["channel"] = channel;
      message["username"] = username;
      message["icon_emoji"] = iconEmoji;

      // var data = {
      //   "channel": channel,
      //   "username": username,
      //   "icon_emoji": iconEmoji,
      //   "attachments": message
      // };
      
      _printLog("Sending request to Slack server...");
      Response response = await _dio.post(webhookUrl, data: jsonEncode(message));
      // var response = await http.post(webhookUrl, body: jsonEncode(message));
      _printLog(
          "Server responded with code: ${response.statusCode} and message: ${response.statusMessage}");
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (exception) {
      _printLog("Failed to send slack message: $exception");
      return false;
    }
  }

  // String _buildMessage(Report report) {
  //   StringBuffer stringBuffer = new StringBuffer();
  //   stringBuffer.write("*Error:* ```${report.error}```\n");

  //   if (enableStackTrace) {
  //     stringBuffer.write("*Stack trace:* ```${report.stackTrace}```\n");
  //   }

  //   if (enableDeviceParameters && report.deviceParameters.length > 0) {
  //     stringBuffer.write("*Device parameters:* ```");
  //     for (var entry in report.deviceParameters.entries) {
  //       stringBuffer.write("${entry.key}: ${entry.value}\n");
  //     }
  //     stringBuffer.write("```\n");
  //   }

  //   if (enableApplicationParameters &&
  //       report.applicationParameters.length > 0) {
  //     stringBuffer.write("*Application parameters:* ```");
  //     for (var entry in report.applicationParameters.entries) {
  //       stringBuffer.write("${entry.key}: ${entry.value}\n");
  //     }
  //     stringBuffer.write("```\n");
  //   }

  //   if (enableCustomParameters && report.customParameters.length > 0) {
  //     stringBuffer.write("*Custom parameters:* ```");
  //     for (var entry in report.customParameters.entries) {
  //       stringBuffer.write("${entry.key}: ${entry.value}\n");
  //     }
  //     stringBuffer.write("```\n");
  //   }
  //   return stringBuffer.toString();
  // }

  Map _buildNewMessage(Report report) {
    var map = Map();
    String deviceParameter;
    String applicationParameter;
    List<Map<String, dynamic>> stackTrace = [];
    StringBuffer stringBuffer = new StringBuffer();

    for(var entry in report.applicationParameters.entries) {
      stringBuffer.write("- *${entry.key}:* ${entry.value}\n");
    }

    applicationParameter = stringBuffer.toString();
    stringBuffer.clear();

    for(var entry in report.deviceParameters.entries) {
      stringBuffer.write("- *${entry.key}:* ${entry.value}\n");
    }

    deviceParameter = stringBuffer.toString();
    stringBuffer.clear();

    stringBuffer.write(report.stackTrace);

    List<String> stackList = stringBuffer.toString().split("\n");
    StringBuffer stackTraceData = new StringBuffer();
    int counter = 0;

    for(int i = 0; i < stackList.length; i++) {
      if(stackTrace.length >= 3) {
        break;
      }

      final _cindex = stackList[i];

      if(_cindex == "") continue;

      if(counter + _cindex.length > 2500) {
        stackTrace.add({
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": stackTraceData.toString().substring(0, stackTraceData.length - 1)
          }
        });

        stackTraceData.clear();
        counter = 0;
      }

      stackTraceData.write("$_cindex\n");
      counter+=_cindex.length;
    }

    if(counter > 0 && stackTrace.length < 3) {
      stackTrace.add({
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": stackTraceData.toString()
        }
      });
    }

    map["blocks"] = [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "Something when wrong at *${tanggal(DateTime.now())}* | *${DateTime.now().toString()}*"
        }
      },
    ];

    map["attachments"] = [
      {
        "color": "#ff2121",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "```${report.error.toString()}```"
            }
          }
        ]
      },
      {
        "color": "#ffba26",
        "blocks": stackTrace
      },
      {
        "color": "#2684ff",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Application parameters:*\n${applicationParameter.toString()}"
            }
          },
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Device parameters:*\n${deviceParameter.toString()}"
            }
          },
        ]
      },
    ];

    return map;
  }

  void _printLog(String log) {
    if (printLogs) {
      _logger.info(log);
    }
  }

  @override
  List<PlatformType> getSupportedPlatforms() =>
      [PlatformType.Android, PlatformType.iOS];
}
