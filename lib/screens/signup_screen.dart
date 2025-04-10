import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  // ✅ Function to validate input fields
  bool _validateInputs() {
    if (_nameController.text.trim().isEmpty ||
        _selectedGender == null ||
        _panController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = "All fields are required!");
      return false;
    }

    if (!RegExp(r"^[6-9]\d{9}$").hasMatch(_phoneController.text.trim())) {
      setState(() => errorMessage = "Invalid phone number!");
      return false;
    }

    if (!RegExp(r"^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$")
        .hasMatch(_passwordController.text.trim())) {
      setState(() => errorMessage =
          "Password must be at least 8 characters, include an uppercase letter, a number, and a special character!");
      return false;
    }

    setState(() => errorMessage = null);
    return true;
  }

  Future<void> signUpUser() async {
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final email = _emailController.text.trim();
      final pan = _panController.text.trim();
      final phone = _phoneController.text.trim();

      // ✅ Check if PAN or Phone already exists
      final existingUser = await supabase
          .from('users')
          .select('id')
          .eq('pan_number', pan)
          .maybeSingle();

      if (existingUser != null) {
        setState(() {
          errorMessage = "PAN number already exists!";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => isLoading = false);
        return;
      }

      // ✅ Attempt Signup
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user != null) {
        try {
          // ✅ Insert user data into `users` table
          await supabase.from('users').insert({
            'id': user.id,
            'name': _nameController.text.trim(),
            'gender': _selectedGender,
            'pan_number': pan,
            'date_of_birth': _dobController.text.trim(),
            'phone_number': phone,
            'created_at': DateTime.now().toIso8601String(),
          });

          // ✅ Automatically log in the user
          await supabase.auth.signInWithPassword(
            email: email,
            password: _passwordController.text.trim(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup successful!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacementNamed(context, '/home'); // Navigate to home
        } catch (error) {
          // ❌ Delete user from auth.users if inserting into `users` table fails
          await supabase.auth.admin.deleteUser(user.id);

          setState(() {
            errorMessage = "Signup failed: $error";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        errorMessage = "Signup failed: $error";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (errorMessage != null)
              Text(errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14)),

            TextField(
              controller: _nameController,
              decoration: _inputDecoration("Full Name", Icons.person),
            ),
            const SizedBox(height: 15),

            // Gender Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              items: ["Male", "Female", "Other"]
                  .map((gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
              decoration: _inputDecoration("Gender", Icons.wc),
            ),
            const SizedBox(height: 15),

            // PAN Number
            TextField(
              controller: _panController,
              decoration: _inputDecoration("PAN Number", Icons.credit_card),
            ),
            const SizedBox(height: 15),

            // Date of Birth
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration:
                  _inputDecoration("Date of Birth", Icons.calendar_today),
            ),
            const SizedBox(height: 15),

            // Phone Number
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration("Phone Number", Icons.phone),
            ),
            const SizedBox(height: 15),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration("Email", Icons.email),
            ),
            const SizedBox(height: 15),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _inputDecoration("Password", Icons.lock),
            ),
            const SizedBox(height: 20),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : signUpUser,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
