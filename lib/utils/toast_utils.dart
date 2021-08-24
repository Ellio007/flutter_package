library flutter_package;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
// static _instance，_instance会在编译期被初始化，保证了只被创建一次
  static final ToastUtils _instance = ToastUtils._internal();

  //提供了一个工厂方法来获取该类的实例
  factory ToastUtils() {
    return _instance;
  }

  // 通过私有方法_internal()隐藏了构造方法，防止被误创建
  ToastUtils._internal() {
    // 初始化
    init();
  }

  void init() {
    debugPrint("ToastUtils这里初始化");
  }

  /// 显示默认Toast
  void showToast(String toastString) {
    Fluttertoast.showToast(
        msg: toastString,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color(0xcc212121),
        textColor: Colors.white,
        fontSize: 13.0);
  }
}
