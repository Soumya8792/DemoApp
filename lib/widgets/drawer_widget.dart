import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
            child: provider.messages.isEmpty
                ? const Center(child: Text('No history yet'))
                : Builder(
                    builder: (context) {
                      final reversedMessages = provider.messages.reversed
                          .toList();
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: reversedMessages.length,
                        separatorBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Divider(),
                        ),
                        itemBuilder: (context, index) {
                          final prompt = reversedMessages[index];

                          return Slidable(
                            key: ValueKey(prompt.sId ?? index),
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (_) async {
                                    log('🗑️ Deleting ID: ${prompt.sId!}');
                                    await provider.deleteMessage(prompt.sId!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Message deleted successfully',
                                        ),
                                      ),
                                    );
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                prompt.text ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
