import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ksebea/login_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginManager _loginManager = LoginManager();
  String _contactInfo = 'No contact information available.';
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _loginManager.initialize(
      onUserChanged: (GoogleSignInAccount? account) {
        setState(() {
          _isAuthorized = account != null;
        });
      },
    );
  }

  /// Fetches and displays the user's contacts.
  Future<void> _fetchContacts() async {
    final String contactInfo = await _loginManager.fetchContacts();
    setState(() {
      _contactInfo = contactInfo;
    });
  }

  /// Builds the UI for signed-in users.
  Widget _buildSignedInUI(GoogleSignInAccount user) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          radius: 40,
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome, ${user.displayName ?? user.email}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_isAuthorized)
          Column(
            children: [
              Text(_contactInfo),
              ElevatedButton(
                onPressed: _fetchContacts,
                child: const Text('Fetch Contacts'),
              ),
            ],
          ),
        if (!_isAuthorized)
          ElevatedButton(
            onPressed: () async {
              final bool granted = await _loginManager.requestScopes();
              if (granted) {
                _fetchContacts();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permissions denied.'),
                  ),
                );
              }
            },
            child: const Text('Request Permissions'),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loginManager.signOut,
          child: const Text('Sign Out'),
        ),
      ],
    );
  }

  /// Builds the UI for users not signed in.
  Widget _buildSignInUI() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
              'assets/images/launcher.png'), // Replace with your background image path
          fit: BoxFit.cover, // Ensures the image covers the entire background
        ),
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: _loginManager.signIn,
          child: const Text('Sign In with Google'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _loginManager.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Google Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null ? _buildSignInUI() : _buildSignedInUI(user),
      ),
    );
  }
}
