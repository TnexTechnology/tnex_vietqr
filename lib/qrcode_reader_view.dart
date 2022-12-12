import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/scr/qr_scanner_overlay_shape.dart';
import 'package:lottie/lottie.dart';
import 'flutter_qr_reader.dart';

/// 使用前需已经获取相关权限
/// Relevant privileges must be obtained before use
class QrcodeReaderView extends StatefulWidget {
  final Future Function(String) onScan;
  final double qrScanSize;
  final Color boxLineColor;
  final double cutOutBottomOffset;

  QrcodeReaderView({
                     Key key,
                     @required this.onScan,
                     this.boxLineColor = Colors.white,
                     this.qrScanSize = 200,
                      this.cutOutBottomOffset = 0
                   }) : super(key: key);

  @override
  QrcodeReaderViewState createState() => new QrcodeReaderViewState();
}

/// 扫码后的后续操作
/// ```dart
/// GlobalKey<QrcodeReaderViewState> qrViewKey = GlobalKey();
/// qrViewKey.currentState.startScan();
/// ```
class QrcodeReaderViewState extends State<QrcodeReaderView>
        with TickerProviderStateMixin {
  QrReaderViewController _controller;
  bool openFlashlight;
  @override
  void initState() {
    super.initState();
    openFlashlight = false;

    // _initAnimation();
  }

  myMethod(){
    print("called from parent");
  }

  void _onCreateController(QrReaderViewController controller) async {
    _controller = controller;
    _controller.startCamera(_onQrBack);
  }

  bool isScan = false;
  bool isAnimation = true;
  Future _onQrBack(data, _) async {
    if (isScan == true) return;
    isScan = true;
    stopScan();
    await widget.onScan(data);
  }

  void startScan() {
    isScan = false;
    _controller.startCamera(_onQrBack);
    // _initAnimation();
    setState(() {
      isAnimation = true;
    });
  }

  void stopScan() {
    // _clearAnimation();
    _controller.stopCamera();
    setState(() {
      isAnimation = false;
    });
  }

  Future<bool> setFlashlight() async {
    openFlashlight = await _controller.setFlashlight();
    setState(() {});
    return openFlashlight;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: LayoutBuilder(builder: (context, constraints) {
        final qrScanSize = widget.qrScanSize;
        final sizeAnimation = qrScanSize*327/277;
        return Stack(
          children: <Widget>[
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: QrReaderView(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                callback: _onCreateController,
              ),
            ),
            Padding(
              padding: EdgeInsets.zero,
              child: Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                      borderColor: Color.fromRGBO(0, 0, 0, 100),
                      borderRadius: 5,
                      borderLength: 0,
                      borderWidth: 10,
                      cutOutBottomOffset: widget.cutOutBottomOffset,
                      cutOutSize: widget.qrScanSize),
                ),
              ),
            ),
            Positioned(
              left: (constraints.maxWidth - sizeAnimation) / 2,
              top: (constraints.maxHeight - sizeAnimation) / 2 - widget.cutOutBottomOffset,
              child: Center(
                child: Container(
                  width: sizeAnimation,
                  height: sizeAnimation,
                  child: Lottie.asset('assets/ScanQR.json',
                      package: "flutter_qr_reader",
                      repeat: true,
                      animate: isAnimation),
                ),
              ),
            ),

          ],
        );
      }),
    );
  }

  @override
  void dispose() {
    // _clearAnimation();
    super.dispose();
  }
}

class QrScanBoxPainter extends CustomPainter {
  final double animationValue;
  final bool isForward;
  final Color boxLineColor;

  QrScanBoxPainter(
          {@required this.animationValue,
            @required this.isForward,
            this.boxLineColor})
          : assert(animationValue != null),
            assert(isForward != null);

  @override
  void paint(Canvas canvas, Size size) {
    final borderRadius = BorderRadius.all(Radius.circular(12)).toRRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRRect(
      borderRadius,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final borderPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final path = new Path();
    // leftTop
    path.moveTo(0, 50);
    path.lineTo(0, 12);
    path.quadraticBezierTo(0, 0, 12, 0);
    path.lineTo(50, 0);
    // rightTop
    path.moveTo(size.width - 50, 0);
    path.lineTo(size.width - 12, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 12);
    path.lineTo(size.width, 50);
    // rightBottom
    path.moveTo(size.width, size.height - 50);
    path.lineTo(size.width, size.height - 12);
    path.quadraticBezierTo(
            size.width, size.height, size.width - 12, size.height);
    path.lineTo(size.width - 50, size.height);
    // leftBottom
    path.moveTo(50, size.height);
    path.lineTo(12, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 12);
    path.lineTo(0, size.height - 50);

    canvas.drawPath(path, borderPaint);

    canvas.clipRRect(
            BorderRadius.all(Radius.circular(12)).toRRect(Offset.zero & size));

    // 绘制横向网格
    final linePaint = Paint();
    final lineSize = size.height * 1.45;
    final leftPress = (size.height + lineSize) * animationValue - lineSize;
    linePaint.style = PaintingStyle.stroke;
    linePaint.shader = LinearGradient(
      colors: [Colors.transparent, boxLineColor],
      begin: isForward ? Alignment.topCenter : Alignment(0.0, 2.0),
      end: isForward ? Alignment(0.0, 0.5) : Alignment.topCenter,
    ).createShader(Rect.fromLTWH(0, leftPress, size.width, lineSize));
    for (int i = 0; i < size.height / 5; i++) {
      canvas.drawLine(
        Offset(
          i * 5.0,
          leftPress,
        ),
        Offset(i * 5.0, leftPress + lineSize),
        linePaint,
      );
    }
    for (int i = 0; i < lineSize / 5; i++) {
      canvas.drawLine(
        Offset(0, leftPress + i * 5.0),
        Offset(
          size.width,
          leftPress + i * 5.0,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(QrScanBoxPainter oldDelegate) =>
          animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(QrScanBoxPainter oldDelegate) =>
          animationValue != oldDelegate.animationValue;
}
