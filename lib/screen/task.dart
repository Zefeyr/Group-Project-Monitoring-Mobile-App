import 'package:flutter/material.dart';

class TaskBoardPage extends StatelessWidget {
  const TaskBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            tabs: [
              Tab(text: "Active Tasks"),
              Tab(text: "Completed"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTaskList(false), // Pending tasks
                _buildTaskList(true), // Completed tasks
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(bool isDone) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) => CheckboxListTile(
        value: isDone,
        title: Text('Research Phase - Part ${index + 1}'),
        subtitle: const Text('Assigned to: Ali'),
        onChanged: (val) {}, // Toggle task status
      ),
    );
  }
}
