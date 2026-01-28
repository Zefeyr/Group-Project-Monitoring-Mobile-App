import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final Color primaryBlue = const Color(0xFF1A3B5D);
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const SizedBox();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'My Tasks',
            style: GoogleFonts.outfit(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: TabBar(
            labelColor: primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryBlue,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: "All Tasks"), Tab(text: "By Project")],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          // Fetch all projects where the user is a member
          stream: FirebaseFirestore.instance
              .collection('projects')
              .where('members', arrayContains: currentUser!.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _emptyState("No projects found", Icons.folder_off);
            }

            final projects = snapshot.data!.docs;

            return TabBarView(
              children: [
                AllTasksTab(projects: projects, userEmail: currentUser!.email),
                ByProjectTab(projects: projects, userEmail: currentUser!.email),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: ALL TASKS (Merged Stream)
// ---------------------------------------------------------------------------

class AllTasksTab extends StatefulWidget {
  final List<QueryDocumentSnapshot> projects;
  final String? userEmail;

  const AllTasksTab({super.key, required this.projects, this.userEmail});

  @override
  State<AllTasksTab> createState() => _AllTasksTabState();
}

class _AllTasksTabState extends State<AllTasksTab> {
  final Map<String, List<DocumentSnapshot>> _projectTasks = {};
  final List<StreamSubscription> _subscriptions = [];
  final StreamController<List<DocumentSnapshot>> _tasksController =
      StreamController<List<DocumentSnapshot>>();

  @override
  void initState() {
    super.initState();
    _subscribeToProjects();
  }

  @override
  void didUpdateWidget(covariant AllTasksTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects.length != oldWidget.projects.length ||
        !_areProjectIdsSame(widget.projects, oldWidget.projects)) {
      _subscribeToProjects();
    }
  }

  bool _areProjectIdsSame(
    List<QueryDocumentSnapshot> a,
    List<QueryDocumentSnapshot> b,
  ) {
    final idsA = a.map((e) => e.id).toSet();
    final idsB = b.map((e) => e.id).toSet();
    return idsA.length == idsB.length && idsA.containsAll(idsB);
  }

  void _subscribeToProjects() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _projectTasks.clear();

    // Filter out completed projects
    final activeProjects = widget.projects.where((p) {
      final data = p.data() as Map<String, dynamic>;
      return (data['status'] ?? 'Active') != 'Completed';
    }).toList();

    if (activeProjects.isEmpty) {
      _tasksController.add([]);
      return;
    }

    for (var project in activeProjects) {
      final sub = project.reference
          .collection('tasks')
          .snapshots()
          .listen((snapshot) {
            _projectTasks[project.id] = snapshot.docs;
            _emitCombined();
          }, onError: (e) {
            print("Error listening to project ${project.id}: $e");
          });
      _subscriptions.add(sub);
    }
  }

  void _emitCombined() {
    try {
      final allTasks =
          _projectTasks.values.expand((element) => element).toList();

      // Filter: Only MY Tasks
      if (widget.userEmail != null) {
        allTasks.removeWhere((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['assignedTo'] != widget.userEmail;
        });
      }

      // Sort by deadline (nearest first)
      allTasks.sort((a, b) {
        final da = a.data() as Map<String, dynamic>?;
        final db = b.data() as Map<String, dynamic>?;

        if (da == null || db == null) return 0;

        final ta = da['deadline'];
        final tb = db['deadline'];

        final DateTime? dateA = (ta is Timestamp) ? ta.toDate() : null;
        final DateTime? dateB = (tb is Timestamp) ? tb.toDate() : null;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateA.compareTo(dateB);
      });

      _tasksController.add(allTasks);
    } catch (e) {
      print("Error processing tasks: $e");
    }
  }

  @override
  void dispose() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    _tasksController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _tasksController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        
        // Split tasks into Active and Completed
        final activeTasks = <DocumentSnapshot>[];
        final completedTasks = <DocumentSnapshot>[];

        for (var t in tasks) {
           final data = t.data() as Map<String, dynamic>;
           if ((data['status'] ?? 'Active') == 'Completed') {
             completedTasks.add(t);
           } else {
             activeTasks.add(t);
           }
        }

        if (activeTasks.isEmpty && completedTasks.isEmpty) {
          return Center(
            child: Text(
              "No tasks found",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ACTIVE TASKS
            ...activeTasks.map((taskDoc) => _buildTaskItem(taskDoc)),

            // COMPLETED TASKS SECTION
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 30),
               Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text(
                  "Completed Tasks",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ...completedTasks.map((taskDoc) => _buildTaskItem(taskDoc, isDone: true)),
            ],
            
            const SizedBox(height: 50),
          ],
        );
      },
    );
  }

  Widget _buildTaskItem(DocumentSnapshot taskDoc, {bool isDone = false}) {
     final data = taskDoc.data() as Map<String, dynamic>;
     // Resolve Project Name safely
      final projectId = taskDoc.reference.parent.parent!.id;
      String projectName = 'Unknown Project';
      try {
        final project = widget.projects.firstWhere((p) => p.id == projectId);
        final pData = project.data() as Map<String, dynamic>;
        projectName = pData['name'] ?? 'Untitled';
      } catch (e) {
        if (widget.projects.isNotEmpty) {
           final pData = widget.projects.first.data() as Map<String, dynamic>;
           projectName = pData['name'] ?? 'Untitled';
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TaskCard(
          task: data,
          taskRef: taskDoc.reference,
          projectName: projectName,
          primaryBlue: const Color(0xFF1A3B5D),
          isDoneSection: isDone,
        ),
      );
  }
}

// ---------------------------------------------------------------------------
// TAB 2: BY PROJECT (Filtered: My Tasks Only)
// ---------------------------------------------------------------------------

class ByProjectTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> projects;
  final String? userEmail;

  const ByProjectTab({super.key, required this.projects, this.userEmail});

  @override
  Widget build(BuildContext context) {
    // Filter out completed projects
    final activeProjects = projects.where((p) {
       final data = p.data() as Map<String, dynamic>;
       return (data['status'] ?? 'Active') != 'Completed';
    }).toList();

    if (activeProjects.isEmpty) {
       return Center(
           child: Text(
             "No active projects",
             style: GoogleFonts.inter(color: Colors.grey.shade500),
           )
       );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeProjects.length,
      itemBuilder: (context, index) {
        final project = activeProjects[index];
        final pData = project.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            shape: const Border(),
            title: Text(
              pData['name'] ?? 'Untitled',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1A3B5D),
              ),
            ),
            subtitle: Text(
              pData['subject'] ?? 'General',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: project.reference
                    .collection('tasks')
                    .where('assignedTo', isEqualTo: userEmail)
                    .orderBy('deadline', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Error loading tasks: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  // Filter out completed tasks here manually or via query if index existed.
                  // Since we are inside StreamBuilder, we can just filter the list.
                  final tasks = snapshot.data!.docs.where((doc) {
                     final tData = doc.data() as Map<String, dynamic>;
                     return (tData['status'] ?? 'Active') != 'Completed';
                  }).toList();

                  if (tasks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "No pending tasks",
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final tDoc = tasks[idx];
                      final tData = tDoc.data() as Map<String, dynamic>;
                      return TaskCard(
                        task: tData,
                        taskRef: tDoc.reference,
                        projectName: null,
                        primaryBlue: const Color(0xFF1A3B5D),
                        compact: true,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED UI: TASK DOCUMENT CARD
// ---------------------------------------------------------------------------

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final DocumentReference? taskRef;
  final String? projectName;
  final Color primaryBlue;
  final bool compact;
  final bool isDoneSection;

  const TaskCard({
    super.key,
    required this.task,
    this.taskRef,
    this.projectName,
    required this.primaryBlue,
    this.compact = false,
    this.isDoneSection = false,
  });

  @override
  Widget build(BuildContext context) {
    // Format Date safely
    String dateStr = "No Date";
    Color dateColor = Colors.grey;

    if (task['deadline'] != null && task['deadline'] is Timestamp) {
      final dt = (task['deadline'] as Timestamp).toDate();
      
      // If done, show "Completed on" (optional, but lets just show deadline)
      // Or we can just keep deadline.
      dateStr = DateFormat('MMM d, y').format(dt);
      
      if (!isDoneSection && dt.isBefore(DateTime.now())) {
        dateColor = Colors.redAccent;
        dateStr += " (Overdue)";
      } else if (isDoneSection) {
        dateColor = Colors.green;
        dateStr += " (Done)";
      } else {
        dateColor = primaryBlue;
      }
    }

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDoneSection ? Colors.grey.shade50 : (compact ? const Color(0xFFF8F9FA) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: compact ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isDoneSection ? Colors.green : (compact ? primaryBlue : dateColor),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (projectName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      projectName!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                Text(
                  task['taskName'] ?? 'Unnamed Task',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDoneSection ? Colors.grey : Colors.black87,
                    decoration: isDoneSection ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: dateColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isDoneSection && taskRef != null)
            IconButton(
              onPressed: () => _showCompleteDialog(context),
              icon: Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.grey.shade400,
                size: 28,
              ),
              tooltip: "Mark as Done",
            ),
          if (isDoneSection)
             Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Complete Task?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text("This will move the task to 'Completed Tasks'."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () async {
              Navigator.pop(context);
              if (taskRef != null) {
                try {
                  await taskRef!.update({'status': 'Completed'});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Task completed!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error completing task: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to complete task. please check permissions."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
