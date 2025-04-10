import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  bool isLoading = false;
  String? message;

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.length < 8) {
      setState(() {
        message = "Password must be at least 8 characters.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw 'Something went wrong while updating the password.';
      }
    } catch (e) {
      setState(() {
        message = "Failed to update password: $e";
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Set your new password",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: Icon(Icons.lock),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),
            if (message != null)
              Text(
                message!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _updatePassword,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Update Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
