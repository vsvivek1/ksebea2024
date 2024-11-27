import 'dart:convert' show json;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// A utility class for managing Google Sign-In and API interactions.
class LoginManager {
  /// Required scopes for Google Sign-In.
  static const List<String> scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  /// Google Sign-In instance.
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: scopes);

  /// The currently signed-in Google user.
  GoogleSignInAccount? _currentUser;

  /// Get the currently signed-in user.
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Initializes the Google Sign-In manager.
  ///
  /// [onUserChanged] is a callback that is triggered whenever the signed-in user changes.
  void initialize({Function(GoogleSignInAccount?)? onUserChanged}) {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;

      // Notify the caller about the user change.
      if (onUserChanged != null) {
        onUserChanged(account);
      }
    });

    // Attempt silent sign-in to automatically restore the session.
    _googleSignIn.signInSilently();
  }

  /// Signs in the user interactively.
  ///
  /// Displays a Google Sign-In prompt to the user.
  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('Sign-in error: $error');
    }
  }

  /// Signs out the current user.
  ///
  /// Disconnects the user from the application.
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      _currentUser = null;
    } catch (error) {
      print('Sign-out error: $error');
    }
  }

  /// Requests additional permissions (scopes) from the user.
  ///
  /// Returns `true` if the user grants the required permissions, `false` otherwise.
  Future<bool> requestScopes() async {
    if (_currentUser != null) {
      return await _googleSignIn.requestScopes(scopes);
    }
    return false;
  }

  /// Fetches the user's contacts from the Google People API.
  ///
  /// Returns a string describing the first named contact or an error message.
  Future<String> fetchContacts() async {
    if (_currentUser == null) {
      return 'No user signed in.';
    }

    try {
      final http.Response response = await http.get(
        Uri.parse('https://people.googleapis.com/v1/people/me/connections'
            '?requestMask.includeField=person.names'),
        headers: await _currentUser!.authHeaders,
      );

      if (response.statusCode != 200) {
        print('People API error: ${response.statusCode}');
        return 'Failed to fetch contacts.';
      }

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      return _pickFirstNamedContact(data) ?? 'No contacts found.';
    } catch (error) {
      print('Fetch contacts error: $error');
      return 'Error fetching contacts.';
    }
  }

  /// Picks the first named contact from the People API response.
  ///
  /// Returns the contact's display name, or `null` if no contacts are available.
  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic name) =>
            (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      return name?['displayName'] as String?;
    }
    return null;
  }
}
