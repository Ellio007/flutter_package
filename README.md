1. 开发环境
可参考开始使用Flutter 根据自己的需求，选择对应的开发环境
若选用Android Studio开发可安装GetX插件配合GetX库使用可快速构建样板代码（可选）
2. 添加依赖
在pubspec.yaml文件dependencies下添加如下语句：
注意语句前面空格不能增减
  flutter_package:
    git:
      url: git://github.com/Ellio007/flutter_package.git
添加后在git：有一个警告，需要我们添加如下语句。
# 下面这行代码防止包被意外发布到
# pub.dev使用pub publish。这是私有包的首选。
publish_to: 'none' #如果你想发布到pub.dev，请删除这一行
3. 基本使用
路由页面
 新增Routes类里定义路由名称  
class Routes {
  static const Initial = '/';
  static const Login = '/login';
}
 新增AppPages类里注册路由表  
/// 注册路由表
abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.Initial,
      page: () => MyHomePage(),
    ),
    GetPage(
      name: Routes.Login,
      page: () => LoginPage(),
      binding: LoginBinding(),
    ),
  ];
}
 在需要跳转的地方调用  
Get.toNamed(Routes.Login);
更多关于路由的使用方法请参考：Flutter状态管理终极方案GetX第一篇——路由
网络请求
 全局配置并初始化，可全局配置如下属性，后三项超时时间默认为60秒：  
HttpConfig dioConfig = HttpConfig(
    baseUrl: baseUrl,
    proxy: "192.168.2.249:8888",
    cookiesPath: cookiesPath,
    interceptors: interceptors,// 拦截器默认没实现，需自己实现
    connectTimeout: 3000,
    receiveTimeout: 3000,
    sendTimeout: 3000);
Get.lazyPut(() => HttpClient(dioConfig: dioConfig));
涉及到Token的在调用网络请求之前需调用SpUtils里的savePreference方法将token保存进Sp里面。如果没有token限制，则可忽略该步骤（可选）
SpUtils.savePreference(SpUtils.TOKEN_KEY, token);
请求时，以登陆为例：  
void login(String username, String password) async {
    SpUtils.savePreference(SpUtils.USERNAME_KEY, username);
    HttpClient client = Get.find<HttpClient>();
    Options requestOptions = Options();
    requestOptions.headers = new Map();
    requestOptions.headers!["Authorization"] =
        "Basic ${base64Encode(utf8.encode(GlobalKeys.sinoBasic))}";
    Map<String, Object> body = Map();
    body["phone"] = username;
    body["code"] = password;
    HttpResponse appResponse = await client.post("login",
        data: body, options: requestOptions);
    if (appResponse.ok) {
      debugPrint("====" + appResponse.data.toString());
    } else {
      debugPrint("====" + appResponse.error.toString());
    }
}
原生交互: Android
 获取原生数据，以传递Token到Flutter模块为例  
void getTokenAndShow() async {
  String token = await NativeUtils.getNativeData("token");
  SpUtils.savePreference(SpUtils.TOKEN_KEY, token);
}
 原生调用（通知）Flutter模块，以原生更新Token同步Flutter模块为例  
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
// 需要在进入Flutter模块后注册上面的监听
NativeUtils.registerMethod();
 原生中的代码Android端与Flutter端很相似，代码如下：  
class CustomFlutterActivity : FlutterActivity() {

    companion object {
        var methodChannelInvoker: (MethodCall, Result) -> Unit = { _, _ -> }

        fun withCachedEngine(cachedEngineId: String): CachedEngineIntentBuilder {
            return CachedEngineIntentBuilder(CompassFlutterActivity::class.java, cachedEngineId)
        }

        fun withNewEngine(): NewEngineIntentBuilder {
            return NewEngineIntentBuilder(CompassFlutterActivity::class.java)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "APP_CHANNEL")
                .setMethodCallHandler { call, result ->
                	// 也可以直接写在这里
                	// if (call.method == "getGreetings") {
              		//   val greetings = "Hello there!"
             		//   result.success(coordinates)
           			// }
                    methodChannelInvoker(call, result)
                }
    }
}

// 原生开启CustomFlutterActivity的地方调用
CustomFlutterActivity.methodChannelInvoker = { call, result ->
            if (call.method == "getGreetings") {
                val greetings = "Hello there!"
                result.success(coordinates)
            }
        }
        startActivity(CustomFlutterActivity
                .withNewEngine()
                .initialRoute("/custom_route")
                .build(this))
原生交互: iOS
  1.1消息通道交互（messageChannel）iOS代码
let messageChannel = FlutterBasicMessageChannel(name: "message-channel", binaryMessenger: flutterVC as! FlutterBinaryMessenger)

messageChannel.setMessageHandler { message, callBack in
                                
   if let messageDict = message as? [String : Any],let method =                        messageDict["text"] as? String{
       callBack(["text3":"IOS接收到Flutter返回的消息: 单次函数回调"])
                //FlutterReply
   }
}

DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            messageChannel.sendMessage(["text1":"ios向flutter发送消息"])
 }
  1.2消息通道交互（messageChannel）flutter代码
// 注册消息通道
final BasicMessageChannel _msgChannel =
      BasicMessageChannel('message-channel', StandardMessageCodec());

_msgChannel.setMessageHandler((message) async {
      print('收到 native1 信息: $message');
      return null;
    });
 2.1方法通道交互（methodChannel）iOS代码 (以创建flutter控制器为例)
// 创建信息通道，name 需与 flutter 中保持一致
let methodChannel = FlutterMethodChannel(name: "method-channel", binaryMessenger: flutterVC as! FlutterBinaryMessenger)
 // 通知 flutter 将要展示的页面
methodChannel.invokeMethod(pageName, arguments: nil)
let flutterEngine = (UIApplication.shared.delegate as? AppDelegate)?.flutterEngine
self.flutterVC = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)
self.navigationController?.pushViewController(flutterVC, animated: true)
// 监听 flutter 页面内的消息
weak var weakSelf : ViewController!  = self
methodChannel.setMethodCallHandler { (call, result) in
    let action = call.method
    switch action {
    case "back":
               
          weakSelf.navigationController?.popViewController(animated: true)
    case "changeBackgroundColor":
          let colors: [UIColor] = [.black, .gray, .yellow, .orange, .brown]
          let idx = arc4random()%4
          weakSelf.view.backgroundColor = colors[Int(idx)]
          let flutterEngine = (UIApplication.shared.delegate as? AppDelegate)?.flutterEngine
          self.flutterVC = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)
    default:
           break
    }
            
}
  2.2方法通道交互（methodChannel）flutter代码
// 注册消息通道
final MethodChannel _methodChannel = MethodChannel('method-channel');    
//页面初始化时设置pageIndex 来决定跳转的是那个页面
__methodChannel.setMethodCallHandler((MethodCall call) async {
      setState(() {
          //进入那个页面
        pageIndex = call.method;
      });
      return null;
    });
//返回按钮

ElevatedButton(
    onPressed: () {
    // 点击事件, 返回上个页面
    MethodChannel('method-channel').invokeMapMethod('back');
    },
    child: Text('Back'),
),
基础Toast
调用如下语句即可完成Toast，若需要其他基础实现可在ToastUtils类实现相应方法
ToastUtils().showToast("This is Bottom Short Toast");
键值对存储
 保存  
SpUtils.savePreference(SpUtils.USERNAME_KEY, username);
 取值，需要注意的是：取值的时候第二个参数必填，并且需要与存的时候的类型保持一致。  
void getUsername() async {
  usernameController.text = await SpUtils.getPreference(SpUtils.USERNAME_KEY, "") as String;
}
使用GetX插件
GetX插件能够快速构建标准化控件，减少创建文件以及编写样板代码的工序。
 在AndroidStudio上install Getx插件 

 在想要创建Widget的地方如下图操作:

 根据自己的习惯选择相应内容并输入Module Name点击OK即可完成添加 

国际化
翻译
翻译被保存为一个简单的键值字典映射。要添加自定义翻译，请创建一个类并扩展Translations.
import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'hello': 'Hello World',
        },
        'de_DE': {
          'hello': 'Hallo Welt',
        }
      };
}
使用翻译
只需附加.tr到指定的键，它将使用Get.localeand的当前值进行翻译Get.fallbackLocale
Text('title'.tr);
使用单复数翻译
var products = [];
Text('singularKey'.trPlural('pluralKey', products.length, Args));
使用带有参数的翻译
import 'package:get/get.dart';


Map<String, Map<String, String>> get keys => {
    'en_US': {
        'logged_in': 'logged in as @name with email @email',
    },
    'es_ES': {
       'logged_in': 'iniciado sesión como @name con e-mail @email',
    }
};

Text('logged_in'.trParams({
  'name': 'Jhon',
  'email': 'jhon@example.com'
  }));
语言环境
传递参数以GetMaterialApp定义语言环境和翻译。
return GetMaterialApp(
    translations: Messages(), // your translations
    locale: Locale('en', 'US'), // translations will be displayed in that locale
    fallbackLocale: Locale('en', 'UK'), // specify the fallback locale in case an invalid locale is selected.
);
更改语言环境
调用Get.updateLocale(locale)以更新区域设置。然后翻译会自动使用新的语言环境。
var locale = Locale('en', 'US');
Get.updateLocale(locale);
系统区域
要读取系统区域设置，您可以使用Get.deviceLocale.
return GetMaterialApp(
    locale: Get.deviceLocale,
);
4. 使用到的第三方库
注意：以下库可以不用重复导入，若导入不同版本可能会出现不可预料的问题
第三方库查找平台：pub.dev
框架使用到的第三方库：
公共Toast组件：fluttertoast^8.0.8
屏幕分辨率适配工具：flutter_screenutil^5.0.0+2
网络请求：dio^4.0.0、cookie_jar3.0.1、dio_cookie_manager^2.0.0
dio库也需要二次封装
存储键值对数据：shared_preferences^2.0.6
该库实际上是通过插件直接调用的原生的键值对API做到的
路由、状态管理、依赖注入：get^4.3.8
GetX 是 Flutter 上的一个轻量且强大的解决方案：高性能的状态管理、智能的依赖注入和便捷的路由管理。
GetX的优点：
轻量。模块单独编译，没用到的功能不会编译进我们的代码。
语法简洁。个人非常喜欢，显而易见且实用，比如路由摆脱了 context 的依赖，Get.to(SomePage())就能导航到新路由。
性能。Provider、BLoC 等只能在父子组件保存状态，同层级模块状态管理需要全局处理，存活在整个应用生命周期。而  GetX 可以随时添加控制器和删除控制器，并且会自动释放使用完的控制器。
依赖注入。提供依赖注入功能，代码层级可以完全分离，甚至依赖注入的代码也是分离的。
丰富的api。许多复杂的操作，使用 GetX 就会有简单的实现。
推荐学习文章：
Flutter状态管理终极方案GetX第一篇——路由
Flutter状态管理终极方案GetX第二篇——状态管理
Flutter状态管理终极方案GetX第三篇——依赖注入
推荐使用的第三方库：
常用工具类：common_utils: ^2.0.2
Dart常用工具类库。包含日期，正则，倒计时，时间轴等工具类。包括：
TimelineUtil : 时间轴.
TimerUtil : 倒计时，定时任务.
MoneyUtil : 精确转换，元转分，分转元，支持格式输出.
LogUtil : 简单封装打印日志.
DateUtil : 日期转换格式化输出.
RegexUtil : 正则验证手机号，身份证，邮箱等等.
NumUtil : 保留x位小数, 精确加、减、乘、除, 防止精度丢失.
ObjectUtil : 判断对象是否为空(String List Map),判断两个List是否相等.
EncryptUtil : 异或对称加/解密，md5加密，Base64加/解密.
TextUtil : 银行卡号每隔4位加空格，每隔3三位加逗号，隐藏手机号等等.
JsonUtil : 简单封装json字符串转对象.
