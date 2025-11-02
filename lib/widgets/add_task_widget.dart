import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controller/add_task_controller.dart';

class AddTaskModal extends StatefulWidget {
  final VoidCallback? onTaskAdded;
  final Map<String, dynamic>? taskToEdit;

  const AddTaskModal({
    super.key, 
    this.onTaskAdded,
    this.taskToEdit,
  });

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  late AddTaskController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AddTaskController(
      context: context, 
      onTaskAdded: widget.onTaskAdded,
      taskToEdit: widget.taskToEdit,
    );
  }

  @override
  void dispose() {
    _controller.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.taskToEdit != null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SafeArea(
          child: AnimatedPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      isEditMode ? ('update_task').tr() : ('add_task').tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // General error message
                    if (_controller.generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _controller.generalError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    /// Date Picker
                    TextField(
                      controller: _controller.dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: ('date').tr(),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _controller.dateError != null
                                ? Colors.red
                                : const Color.fromARGB(255, 179, 240, 182),
                          ),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: _controller.dateError != null
                              ? Colors.red
                              : (theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                        errorText: _controller.dateError,
                      ),
                      onTap: () async {
                        _controller.clearErrors();
                        final now = DateTime.now();
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          _controller.dateController.text =
                              '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Time Picker
                    TextField(
                      controller: _controller.timeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: '${tr('time')} (e.g., 10 AM)',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _controller.timeError != null
                                ? Colors.red
                                : const Color.fromARGB(255, 179, 240, 182),
                          ),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: _controller.timeError != null
                              ? Colors.red
                              : (theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        suffixIcon: const Icon(Icons.access_time),
                        errorText: _controller.timeError,
                      ),
                      onTap: () async {
                        _controller.clearErrors();
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                brightness: Theme.of(context).brightness,
                                colorScheme: ColorScheme.light(
                                  primary: const Color.fromARGB(255, 179, 240, 182),
                                  onPrimary: Colors.black,
                                  surface: Theme.of(context).scaffoldBackgroundColor,
                                  onSurface: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color.fromARGB(255, 179, 240, 182),
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (pickedTime != null) {
                          _controller.timeController.text = pickedTime.format(context);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Title
                    TextField(
                      controller: _controller.titleController,
                      decoration: InputDecoration(
                        labelText: ('task_title').tr(),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _controller.titleError != null
                                ? Colors.red
                                : const Color.fromARGB(255, 179, 240, 182),
                          ),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: _controller.titleError != null
                              ? Colors.red
                              : (theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        errorText: _controller.titleError,
                      ),
                      onChanged: (_) {
                        if (_controller.titleError != null) {
                          _controller.clearErrors();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Farm Selection Dropdown
                        if (_controller.isLoadingFarms)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_controller.farms.isNotEmpty) ...[
                          DropdownButtonFormField<int?>(
                            value: _controller.selectedFarmId,
                            decoration: InputDecoration(
                              labelText: 'Field (Optional)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.agriculture),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 179, 240, 182),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              floatingLabelStyle: TextStyle(
                                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: const Text('No field selected'),
                              ),
                              ..._controller.farms.map((farm) => DropdownMenuItem<int?>(
                                    value: farm.id,
                                    child: Text(farm.name),
                                  )),
                            ],
                            onChanged: (value) => _controller.setSelectedFarm(value),
                          ),
                          const SizedBox(height: 16),
                        ]
                        else
                          const Center(child: Text('No field available')),

                    Text(
                      ('priority').tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 10,
                      children: [
                        _buildPriorityChip(('urgent').tr(), Colors.redAccent),
                        _buildPriorityChip(('medium').tr(), Colors.orangeAccent),
                        _buildPriorityChip(('normal').tr(), Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _controller.isLoading
                            ? null
                            : _controller.saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 179, 240, 182),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _controller.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Text(
                                isEditMode ? ('update_task').tr() : ('add_task').tr(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w200,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityChip(String label, Color color) {
    final isSelected = _controller.selectedPriority == label;

    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w400,
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.grey[200],
      onSelected: (_) => _controller.setPriority(label),
    );
  }
}