// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controller/day_tasks_controller.dart';
import '../../controller/field_controller.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/weather.dart';
import '../../widgets/day_tasks_widget.dart';
import '../../widgets/add_task_widget.dart';
import '../farm/field_screen.dart';
import '../farm/field_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskController _taskController;
  late FarmController _farmController;

  final CameraPosition _mauritius = const CameraPosition(
    target: LatLng(-20.24, 57.5522),
    zoom: 8.8,
  );

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _taskController = TaskController();
    _farmController = FarmController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskController.loadTasks();
      _farmController.loadfields();
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _farmController.dispose();
    super.dispose();
  }

Set<Marker> _buildMarkers() {
  return _farmController.fields.map((farm) {
    return Marker(
      markerId: MarkerId('farm_${farm.id}'),
      position: LatLng(farm.latitude, farm.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: farm.name,
        onTap: () => _navigateToFarmDetails(farm), 
      ),
     
    );
  }).toSet();
}



  void _navigateToFarmDetails(farm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmDetailsScreen(farm: farm),
      ),
    ).then((result) {
      if (result == true) {
        _farmController.loadfields();
      }
    });
  }

  void _navigateToAddFarm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddFarmScreen(),
      ),
    );
    
    if (result == true) {
      await _farmController.loadfields();
    }
  }

  void _openAddTaskModal({Map<String, dynamic>? taskToEdit}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => AddTaskModal(
        taskToEdit: taskToEdit,
        onTaskAdded: () async {
          await _taskController.loadTasks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: AnimatedBuilder(
        animation: Listenable.merge([_taskController, _farmController]),
        builder: (context, _) {
          if (_taskController.isLoading && _farmController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = _taskController.tasks;
          final farms = _farmController.fields;
          final markers = _buildMarkers();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WeatherBox(),
                const SizedBox(height: 16),

                // ---- My Fields Section ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Fields',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _navigateToAddFarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 179, 240, 182),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Add Field',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Field count indicator
                if (farms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '${farms.length} field${farms.length != 1 ? 's' : ''} registered',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: _mauritius,
                          markers: markers,
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          onMapCreated: (controller) => _mapController = controller,
                        ),
                        if (_farmController.isLoading)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        if (farms.isEmpty && !_farmController.isLoading)
                          Container(
                            color: Colors.black26,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_location_alt,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No fields yet',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "Add Field" to register your first field',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Day Tasks Section ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'tasks'.tr(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openAddTaskModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 179, 240, 182),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'add_task'.tr(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                tasks.isEmpty
                    ? const Center(child: Text('No tasks found.'))
                    : DayTasksList(
                        tasks: tasks,
                        onTaskChecked: (taskId, isChecked) {
                          _taskController.updateTaskStatus(taskId, isChecked);
                        },
                        onTaskDeleted: (taskId) => {
                          _taskController.deleteTask(taskId),
                        },
                        onTaskEdit: (task) => {
                          _openAddTaskModal(taskToEdit: task),
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}