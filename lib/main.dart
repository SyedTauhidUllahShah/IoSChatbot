import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(const ChatBotApp());

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI ChatBot',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const ChatBotScreen(),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech; // Speech-to-text instance
  bool _isListening = false; // Whether the app is listening
  String _voiceInput = ''; // The text from the user's voice input
  List<Map<String, String>> _chatDataset = []; // Predefined chatbot responses

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadDataset();
  }

  Future<void> _loadDataset() async {
    try {
      final String response =
          await rootBundle.loadString('assets/chat_data.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        _chatDataset = data
            .map((e) => {
                  'input': e['input'] as String,
                  'response': e['response'] as String
                })
            .toList();
      });
    } catch (e) {
      print('Error loading dataset: $e');
    }
  }

  String _generateBotResponse(String userMessage) {
    final String normalizedMessage = userMessage.toLowerCase().trim();
    for (var record in _chatDataset) {
      if (record['input'] == normalizedMessage) {
        return record['response']!;
      }
    }
    return _chatDataset.firstWhere((record) => record['input'] == 'default',
            orElse: () =>
                {'response': 'I didn\'t understand that.'})['response'] ??
        'I didn\'t understand that.';
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final String userMessage = _controller.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'message': userMessage});
      _messages
          .add({'sender': 'bot', 'message': _generateBotResponse(userMessage)});
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _voiceInput = val.recognizedWords;
            _controller.text =
                _voiceInput; // Set the recognized text to input field
          });
        },
      );
    } else {
      print('Speech recognition not available.');
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI ChatBot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blueGrey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['sender'] == 'user';

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.indigo.shade100
                            : Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(15),
                          topRight: const Radius.circular(15),
                          bottomLeft: isUser
                              ? const Radius.circular(15)
                              : const Radius.circular(0),
                          bottomRight: isUser
                              ? const Radius.circular(0)
                              : const Radius.circular(15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message['message']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
