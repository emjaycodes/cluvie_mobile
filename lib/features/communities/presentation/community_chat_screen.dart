import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/models/message.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:go_router/go_router.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key, required this.community});
   final Community community;
  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final List<Message> messages = []; // Replace with Riverpod or Bloc state
  final TextEditingController messageController = TextEditingController();

  bool isTyping = false;
  final Community community =  Community(
    id: '682abc123def456ghi789jkl',
    name: 'Action Movie Fans',
    description: 'Explosions, car chases, and muscle. That’s our vibe.',
    members: ['user4', 'user5'],
    admins: ['user4'],
    votes: [],
    movieSuggestions: ['movie3'],
    createdAt: DateTime.now().subtract(Duration(days: 2)),
  );
  
  @override
  void initState() {
    super.initState();
    // Load messages from your backend/provider here
    messages.addAll([
      Message(
        id: '1',
        senderId: '123',
        senderName: 'Justice',
        content: 'Hey everyone!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        isMe: true,
      ),
      Message(
        id: '2',
        senderId: '456',
        senderName: 'Cluvie User',
        content: 'Welcome to the community 🎉',
        timestamp: DateTime.now(),
        isMe: false,
      ),
    ]);
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.insert(
        0,
        Message(
          id: DateTime.now().toIso8601String(),
          senderId: '123', // current user
          senderName: 'You',
          content: text,
          timestamp: DateTime.now(),
          isMe: true,
        ),
      );
    });

    messageController.clear();
    setState(() {
      isTyping = false;
    });

    // Send message to backend
  }

  void showAttachmentOptions() {
    // Show modal bottom sheet for file, image, audio
  }

  void addReactionToMessage(String messageId, String emoji) {
    setState(() {
      final msgIndex = messages.indexWhere((m) => m.id == messageId);
      if (msgIndex != -1 && !messages[msgIndex].reactions.contains(emoji)) {
        messages[msgIndex].reactions.add(emoji);
      }
    });
  }

  void openThread(Message parentMessage) {
    final parentId = parentMessage.id;

    // Extract thread replies related to the parent message
    final threadMessages =
        messages.where((m) => m.parentId == parentId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ThreadBottomSheet(
            parentMessage: parentMessage,
            replies: threadMessages,
            onSendReply: (replyText) {
              final newReply = Message(
                id: DateTime.now().toIso8601String(),
                senderId: '123', // current user ID
                senderName: 'You',
                content: replyText,
                timestamp: DateTime.now(),
                isMe: true,
                parentId: parentId, // 👈 Required to associate with thread
              );

              setState(() {
                messages.add(newReply); // Or push to your backend
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // 🟩 App Bar Section
          SliverAppBarSection(community: community),

          // 🟦 Typing Indicator or pinned message
          if (isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Someone is typing...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),

          // 🟨 Chat Messages Section
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(
                  message: msg,
                  onReact: (emoji) => addReactionToMessage(msg.id, emoji),
                  onTap: () => openThread(msg),
                );
              },
            ),
          ),

          // 🟥 Input Section
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged:
                          (value) =>
                              setState(() => isTyping = value.isNotEmpty),
                      decoration: InputDecoration(
                        hintText: "Write a message...",
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🧩 Sliver App Bar Custom Widget
class SliverAppBarSection extends StatelessWidget {
  final Community community;

  const SliverAppBarSection({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // TODO change to custom widget later
      height: 90,
      child: AppBar(
        elevation: 1,
        // backgroundColor: AppColors.backgroundDark,
        title: Row(
          children: [
            // CircleAvatar(backgroundImage: AssetImage(community.)),
            const SizedBox(width: 10),
            Text(
              community.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context, isAdmin: true);
            },
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, {required bool isAdmin}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Community Info'),
                onTap: () {
                  // Navigator.pop(context);
                  // Navigate to Community Details

                  context.pushNamed(RouteNames.communityInfo, extra: community);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search Messages'),
                onTap: () {
                  Navigator.pop(context);
                  // Open search input
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Manage Members'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to members list
                  },
                ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Edit Community Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // Open community edit screen
                  },
                ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave Community'),
                onTap: () {
                  Navigator.pop(context);
                  // Show confirm dialog
                },
              ),
            ],
          ),
    );
  }
}

// 🧱 Chat Bubble Widget
class ChatBubble extends StatelessWidget {
  final Message message;
  final Function(String emoji)? onReact;
  final Function()? onTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onReact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final theme = Theme.of(context);

    final bgColor =
        isMe
            ? theme.colorScheme.primary.withOpacity(0.9)
            : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => ReactionPicker(onReact: onReact!),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  isMe ? const Radius.circular(16) : const Radius.circular(0),
              bottomRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(message.content, style: TextStyle(color: textColor)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.Hm().format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 4,
                      children:
                          message.reactions
                              .map(
                                (r) => Text(
                                  r,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReact;

  const ReactionPicker({super.key, required this.onReact});

  @override
  Widget build(BuildContext context) {
    final emojis = ['❤️', '😂', '🔥', '👍', '😮', '🎉'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            emojis.map((e) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReact(e);
                },
                child: Text(e, style: const TextStyle(fontSize: 28)),
              );
            }).toList(),
      ),
    );
  }
}

class ThreadBottomSheet extends StatefulWidget {
  final Message parentMessage;
  final List<Message> replies; // You may manage this with a provider or bloc
  final Function(String reply) onSendReply;

  const ThreadBottomSheet({
    super.key,
    required this.parentMessage,
    required this.replies,
    required this.onSendReply,
  });

  @override
  State<ThreadBottomSheet> createState() => _ThreadBottomSheetState();
}

class _ThreadBottomSheetState extends State<ThreadBottomSheet> {
  final TextEditingController _replyController = TextEditingController();
  bool _isTyping = false;

  void _handleSend() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    widget.onSendReply(text);
    _replyController.clear();
    setState(() => _isTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // 🧩 Parent Message
              _ParentMessageCard(message: widget.parentMessage),

              const Divider(height: 24),

              // 🟡 Threaded Replies
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: widget.replies.length,
                  itemBuilder: (context, index) {
                    final reply = widget.replies[index];
                    return _ReplyBubble(message: reply);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 🟩 Input for reply
              SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        onChanged:
                            (value) =>
                                setState(() => _isTyping = value.isNotEmpty),
                        decoration: InputDecoration(
                          hintText: "Write a reply...",
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _handleSend,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final Message message;

  const _ReplyBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color:
              isMe
                  ? theme.colorScheme.primary.withOpacity(0.85)
                  : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentMessageCard extends StatelessWidget {
  final Message message;

  const _ParentMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  message.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
