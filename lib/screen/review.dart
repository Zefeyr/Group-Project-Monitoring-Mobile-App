import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Pending Reviews"),
                Tab(text: "My Accountability"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [_buildPendingReviews(), _buildMyAccountabilityStats()],
        ),
      ),
    );
  }

  // 1. List of work submitted by teammates that NEEDS a rating
  Widget _buildPendingReviews() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2, // Mock data: Imagine Ali and Sarah submitted work
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      index == 0 ? "Ali Abu" : "Sarah Tan",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Task: Final Report",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Submisson: 'draft_v2_final.pdf'"),
                const SizedBox(height: 10),
                const Text("Rate quality and effort:"),
                Row(
                  children: List.generate(
                    5,
                    (i) => const Icon(Icons.star_border, color: Colors.orange),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("Submit Review"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. The Visualization of your own Score (Unique Value Prop)
  Widget _buildMyAccountabilityStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Your Global Accountability Score",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          // A big circular progress indicator to show the score
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(value: 0.85, strokeWidth: 10),
              ),
              const Text(
                "85%",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const ListTile(
            leading: Icon(Icons.timer, color: Colors.green),
            title: Text("Timely Completions"),
            trailing: Text("12/13"),
          ),
          const ListTile(
            leading: Icon(Icons.people, color: Colors.blue),
            title: Text("Average Peer Rating"),
            trailing: Text("4.8/5.0"),
          ),
        ],
      ),
    );
  }
}
