import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  bool isLoggingOut = false;
  bool isEditing = false;
  bool isSaving = false;

  // User data
  String name = '';
  String phone = '';
  String dob = '';
  String gender = '';
  String panNumber = '';

  // Controllers for text fields
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    dobController = TextEditingController();
    fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response =
            await supabase.from('users').select().eq('id', user.id).single();

        if (mounted) {
          // ✅ Check if widget is still mounted
          setState(() {
            isLoading = false;
          });
        }

        if (response != null) {
          setState(() {
            name = response['name'] ?? 'Not provided';
            phone = response['phone_number'] ?? 'Not provided';
            dob = response['date_of_birth'] ?? 'Not provided';
            gender = response['gender'] ?? 'Not provided';
            panNumber = response['pan_number'] ?? 'Not provided';

            // Initialize controllers with current values
            nameController.text = name;
            phoneController.text = phone;

            // Try to format the date if it's in a valid format
            if (response['date_of_birth'] != null) {
              try {
                final DateTime date =
                    DateFormat('yyyy-MM-dd').parse(response['date_of_birth']);
                selectedDate = date;
                dob = DateFormat('MMMM d, yyyy').format(date);
                dobController.text = dob;
              } catch (e) {
                dobController.text = dob;
                // Keep the original format if parsing fails
              }
            } else {
              dobController.text = dob;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load profile: ${e.toString()}';
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Format date to yyyy-MM-dd for database storage
        String formattedDate = selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : '';

        final response = await supabase.from('users').update({
          'name': nameController.text,
          'phone_number': phoneController.text,
          'date_of_birth': formattedDate,
        }).eq('id', user.id);

        // Refresh user data
        await fetchUserData();

        setState(() {
          isEditing = false;
          isSaving = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSaving = false;
        errorMessage = 'Failed to update profile: ${e.toString()}';
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> logout() async {
    if (!mounted) return; // ✅ Prevents calling setState on disposed widget

    setState(() {
      isLoggingOut = true;
    });

    try {
      await supabase.auth.signOut();

      if (mounted) {
        // ✅ Check before updating UI
        setState(() {
          isLoggingOut = false;
        });
      }

      // ✅ Ensure navigation happens outside setState
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to logout: ${e.toString()}';
          isLoggingOut = false;
        });

        // ✅ Show error message safely
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          isLoggingOut
              ? const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              supabase.auth.currentUser?.email ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Error message
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Profile info card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Personal Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (!isEditing)
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isEditing = true;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Name info
                              isEditing
                                  ? EditableProfileField(
                                      icon: Icons.person_outline,
                                      label: 'Full Name',
                                      controller: nameController,
                                      keyboardType: TextInputType.name,
                                    )
                                  : ProfileInfoItem(
                                      icon: Icons.person_outline,
                                      label: 'Full Name',
                                      value: name,
                                    ),
                              const SizedBox(height: 16),

                              // Phone info
                              isEditing
                                  ? EditableProfileField(
                                      icon: Icons.phone_outlined,
                                      label: 'Phone Number',
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                    )
                                  : ProfileInfoItem(
                                      icon: Icons.phone_outlined,
                                      label: 'Phone Number',
                                      value: phone,
                                    ),
                              const SizedBox(height: 16),

                              // DOB info
                              isEditing
                                  ? GestureDetector(
                                      onTap: () => _selectDate(context),
                                      child: AbsorbPointer(
                                        child: EditableProfileField(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'Date of Birth',
                                          controller: dobController,
                                          keyboardType: TextInputType.datetime,
                                          suffix: const Icon(
                                              Icons.calendar_today,
                                              size: 18),
                                        ),
                                      ),
                                    )
                                  : ProfileInfoItem(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Date of Birth',
                                      value: dob,
                                    ),
                              const SizedBox(height: 16),

                              // Gender info (not editable)
                              ProfileInfoItem(
                                icon: Icons.person_outline,
                                label: 'Gender',
                                value: gender,
                              ),
                              const SizedBox(height: 16),

                              // PAN Number info (not editable)
                              ProfileInfoItem(
                                icon: Icons.credit_card_outlined,
                                label: 'PAN Number',
                                value: panNumber,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      if (isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          isEditing = false;
                                          // Reset controllers to original values
                                          nameController.text = name;
                                          phoneController.text = phone;
                                          dobController.text = dob;
                                        });
                                      },
                                child: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : updateProfile,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isSaving
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Saving...'),
                                        ],
                                      )
                                    : const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditableProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Widget? suffix;

  const EditableProfileField({
    Key? key,
    required this.icon,
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  isDense: true,
                  border: const UnderlineInputBorder(),
                  suffix: suffix,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
