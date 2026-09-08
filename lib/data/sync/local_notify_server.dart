import 'dart:async';
import 'dart:io';

/// 本地同步通知服务：桌面端监听本机端口，供浏览器插件等本机写入方
/// 在收藏后立即触发一次同步（实现秒级实时，零服务器）。
///
/// 协议：GET/POST /ping（带简单日志），其余 404。CORS 头兼容浏览器扩展。
class LocalNotifyServer {
  LocalNotifyServer({this.port = 9797});

  final int port;
  HttpServer? _server;
  final _onNotify = StreamController<void>.broadcast();

  /// 收到「有新收藏」通知。
  Stream<void> get onNotify => _onNotify.stream;

  /// 启动监听（端口被占用/失败静默，不影响主流程）。
  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _server!.listen((req) => _handle(req));
    } catch (_) {
      // 端口冲突等：静默降级（周期同步兜底）
    }
  }

  void _handle(HttpRequest req) async {
    try {
      if (req.method == 'OPTIONS') {
        req.response.headers
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        req.response.statusCode = HttpStatus.noContent;
        await req.response.close();
        return;
      }
      if (req.method == 'GET' || req.method == 'POST') {
        req.response.headers
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Content-Type', 'text/plain; charset=utf-8');
        req.response.write('ok');
        await req.response.close();
        if (req.uri.path == '/ping') {
          _onNotify.add(null);
        }
        return;
      }
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
    } catch (_) {
      // 单请求失败不影响监听
    }
  }

  void dispose() {
    _server?.close(force: true);
    _server = null;
  }
}