import 'package:camera/camera.dart';

class MyCameraController {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;

  CameraController? get controller => _cameraController;
  
  CameraDescription? get selectedCamera =>
    _cameras != null && _cameras!.isNotEmpty
        ? _cameras![_currentCameraIndex]
        : null;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _currentCameraIndex = 0; 
      _cameraController = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.ultraHigh,
      );
      await _cameraController!.initialize();
    }
  }

  Future<XFile?> capturePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (!_cameraController!.value.isTakingPicture) {
        return await _cameraController!.takePicture();
      }
    }
    return null;
  }

  Future<void> flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return; 

    
    await _cameraController?.dispose();

    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;

    _cameraController = CameraController(
      _cameras![_currentCameraIndex],
      ResolutionPreset.ultraHigh,
    );

    await _cameraController!.initialize();
  }

  void dispose() {
    _cameraController?.dispose();
  }
}