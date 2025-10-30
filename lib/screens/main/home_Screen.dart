import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controller/day_tasks_controller.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/weather.dart';
import '../../widgets/day_tasks_widget.dart';
import '../../widgets/add_task_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskController _taskController;

  final CameraPosition _mauritius = const CameraPosition(
    target: LatLng(-20.24, 57.5522),
    zoom: 8.8,
  );

  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _taskController = TaskController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskController.loadTasks();
    });

    _markers.add(
      const Marker(
        markerId: MarkerId('port_louis'),
        position: LatLng(-20.1609, 57.5012),
        infoWindow: InfoWindow(title: 'Port Louis'),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addMarker(LatLng position) {
    setState(() {
      final markerId = 'marker_${_markers.length + 1}';
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          infoWindow: InfoWindow(title: 'Marker ${_markers.length + 1}'),
        ),
      );
    });
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
        animation: _taskController,
        builder: (context, _) {
          if (_taskController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = _taskController.tasks;

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
                        onPressed: () {
                          // You can later open an Add Field modal here, just like Add Task
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add Field button pressed')),
                          );
                        },
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
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: GoogleMap(
                        initialCameraPosition: _mauritius,
                        markers: _markers,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        onMapCreated: (controller) => _mapController = controller,
                        onTap: _addMarker,
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