import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sp_utils.dart';
import 'toast_utils.dart';

class NativeUtils {
  static const String NATIVE_CHANNEL_NAME =
      "com.sinocare.flutter"; //给native发消息，此处应和客户端名称保持一致
  //channel_name每一个通信通道的唯一标识，在整个项目内唯一！！！
  static const _channel = const MethodChannel(NATIVE_CHANNEL_NAME);

  /// @Params:
  /// @Desc: 获取native的数据
  ///
  static getNativeData(key, [dynamic arguments]) async {
    try {
      String resultValue = await _channel.invokeMethod(key, arguments);
      return resultValue;
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  static registerMethod() {
    //接收处理原生消息
    _channel.setMethodCallHandler((handler) async {
      switch (handler.method) {
        case "toast":
          ToastUtils().showToast("This is Center Short Toast");
          break;
        case "refreshToken":
          // 刷新token保存
          SpUtils.savePreference(SpUtils.TOKEN_KEY, handler.arguments);
          break;
        default:
          break;
      }
    });
  }
}
