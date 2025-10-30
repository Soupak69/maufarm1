import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import '../../controller/camera_controller.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final MyCameraController _myCameraController = MyCameraController();
  bool _isInitialized = false;
  bool _isFlipping = false; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _myCameraController.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _takePicture() async {
    final XFile? image = await _myCameraController.capturePhoto();
    if (image != null) {
      print('Picture taken: ${image.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Picture saved at ${image.path}')),
        );
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_isFlipping) return; 
    _isFlipping = true;
    await _myCameraController.flipCamera();
    if (mounted) {
      setState(() {});
    }
    _isFlipping = false;
  }

  @override
  void dispose() {
    _myCameraController.dispose();
    super.dispose();
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isInitialized && _myCameraController.controller != null
        ? Stack(
            children: [
              
                SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                  width: _myCameraController.controller!.value.previewSize!.height,
                  height: _myCameraController.controller!.value.previewSize!.width,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: _myCameraController.selectedCamera?.lensDirection == CameraLensDirection.front
                      ? (Matrix4.identity()..rotateY(math.pi)) 
                      : Matrix4.identity(),
                    child: AspectRatio(aspectRatio: _myCameraController.controller!.value.aspectRatio,
                      child: CameraPreview(_myCameraController.controller!),
                    ),
                  ),
                  ),
                ),
              ),

             
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),  
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0, right: 20.0),
                  child: SizedBox(
                    width: 70,
                    height: 60,
                    child: IconButton(
                      onPressed: _flipCamera,
                      icon: const Icon(Icons.flip_camera_ios),
                      iconSize: 50,
                      color: Colors.grey,
                      splashRadius: 35,
                    ),
                  ),
                ),
              ),
            ],
          )
        : const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 179, 245, 181),
            ),
          ),
  );
}
}