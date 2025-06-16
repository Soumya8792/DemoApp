import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textapp/provider/chat_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Prompt History',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
          Expanded(
            child: provider.history.isEmpty
                ? const Center(child: Text('No history yet'))
                : ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: provider.history.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: const Divider(),
                    ),
                    itemBuilder: (context, index) {
                      final prompt = provider.history[index];
                      return ListTile(
                        title: Text(
                          prompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // final controller = TextEditingController(
                          //   text: prompt,
                          // );
                          // provider.addUserMessage(prompt);
                          // provider.generateImage(prompt);
                        },
                      );
                    },
                  ),
          ),
          TextButton.icon(
            onPressed: provider.clearHistory,
            icon: const Icon(Icons.delete_forever),
            label: const Text("Clear History"),
          ),
        ],
      ),
    );
  }
}
