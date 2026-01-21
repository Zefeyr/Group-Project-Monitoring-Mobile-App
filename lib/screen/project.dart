import 'package:flutter/material.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final String projectName;
  const ProjectDetailsScreen({super.key, required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Project Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "This project focuses on building a group monitoring application using Flutter and Firebase.",
            ),
            const Divider(height: 32),

            const Text(
              "Team Members",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            _buildMemberTile("Ali (Project Leader)", "Online"),
            _buildMemberTile("Siti", "Away"),
            _buildMemberTile("Abu", "Offline"),

            const Divider(height: 32),
            const Text(
              "Project Progress",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(value: 0.6, minHeight: 10),
            const SizedBox(height: 5),
            const Text("60% Complete"),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(String name, String status) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name),
      subtitle: Text(status),
      trailing: const Icon(Icons.chat_bubble_outline, size: 20),
    );
  }
}
