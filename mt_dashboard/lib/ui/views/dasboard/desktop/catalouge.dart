import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Adjust this import path and class name for your AuthService, if you use it
// import 'package:your_app_name/auth_services.dart';


// Make sure to initialize Firebase before running the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Uncomment if you have default options generated
  );

  runApp(const Catalouge());
}

class Catalouge extends StatelessWidget {
  const Catalouge({super.key});

  // A global key for the ScaffoldMessengerState which is highly stable.
  // This can be used to show SnackBars from anywhere without needing a context.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Catalouge App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Assign the static key to the ScaffoldMessenger
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const CatalougeScreen(),
    );
  }
}

class CatalougeScreen extends StatefulWidget {
  const CatalougeScreen({super.key});

  @override
  State<CatalougeScreen> createState() => _CatalougeScreenState();
}

class _CatalougeScreenState extends State<CatalougeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _catalougeNameController = TextEditingController();

  // --- Category Search Controller & State ---
  final TextEditingController _categorySearchController = TextEditingController();
  String _categorySearchQuery = '';
  bool _isSearchingCategories = false;

  // --- Brand Search Controller & State ---
  final TextEditingController _brandSearchController = TextEditingController();
  String _brandSearchQuery = '';
  bool _isSearchingBrands = false;

  // --- Brand Input Controllers & State (used for both Add and Edit) ---
  String? _selectedCategoryId;
  String? _selectedCategoryName; // To store the name of the selected category for denormalization
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _quantitiesController = TextEditingController();
  final TextEditingController _colourController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _reauthPasswordController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _categorySearchController.addListener(() {
      setState(() {
        _categorySearchQuery = _categorySearchController.text;
      });
    });
    _brandSearchController.addListener(() {
      setState(() {
        _brandSearchQuery = _brandSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _catalougeNameController.dispose();
    _brandNameController.dispose();
    _quantitiesController.dispose();
    _colourController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _reauthPasswordController.dispose();
    _categorySearchController.dispose(); // Dispose search controllers
    _brandSearchController.dispose();
    super.dispose();
  }

  // --- Utility to get current user ---
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // --- Add Category Function ---
  Future<void> _addCatalouge(NavigatorState dialogNavigator) async {
    final String categoryName = _catalougeNameController.text.trim();
    if (categoryName.isEmpty) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Category name cannot be empty')),
      );
      return;
    }

    if (_currentUser == null) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in first.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('category')
          .add({
        'name': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      dialogNavigator.pop();
      _catalougeNameController.clear();
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Category added successfully!')),
      );
    } catch (e) {
      print('Error adding Category: $e');
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to add Category: $e')),
      );
    }
  }

  // --- Re-authentication Helper Function ---
  // Returns true if re-authentication/verification passes, false otherwise.
  // Context is passed to this function for showing its own dialogs.
  Future<bool> _reauthenticateUser(BuildContext context) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('No user logged in for re-authentication.')),
      );
      return false;
    }

    bool isEmailPasswordUser = currentUser.providerData.any((info) => info.providerId == 'password');
    bool isGoogleUser = currentUser.providerData.any((info) => info.providerId == 'google.com');


    if (isEmailPasswordUser) {
      _reauthPasswordController.clear(); // Clear password field for new attempt
      bool? confirmed = await showDialog<bool>(
        context: context, // Use the context passed to this function
        barrierDismissible: false, // User must interact with dialog
        builder: (reauthDialogContext) {
          return AlertDialog(
            title: const Text('Confirm your password'),
            content: TextField(
              controller: _reauthPasswordController,
              obscureText: true, // Hide password
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(reauthDialogContext).pop(false), // User cancelled
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String password = _reauthPasswordController.text;
                  try {
                    // Create an AuthCredential with the user's email and entered password
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: currentUser.email!, // Assumes email is available
                      password: password,
                    );
                    await currentUser.reauthenticateWithCredential(credential);
                    Navigator.of(reauthDialogContext).pop(true); // Password confirmed, pop reauth dialog
                  } on FirebaseAuthException catch (e) {
                    // Don't pop dialog on failure, let user retry
                    Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(content: Text('Re-authentication failed: ${e.message}')),
                    );
                  } catch (e) {
                    Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(content: Text('An unexpected error occurred during re-authentication.')),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      return confirmed ?? false; // Return false if dialog is dismissed without selection
    } else if (isGoogleUser) {
      // --- Simple Captcha for Google users (Demonstration) ---
      // NOTE: For true security, you would use a robust reCAPTCHA service
      // or re-authenticate via Google's own re-signin flow (which might trigger external browser/popup).
      // This is a simplified example as requested.
      final TextEditingController captchaController = TextEditingController();
      const String correctCaptcha = "VERIFY"; // Simple captcha word

      bool? captchaConfirmed = await showDialog<bool>(
        context: context, // Use the context passed to this function
        barrierDismissible: false,
        builder: (captchaDialogContext) {
          return AlertDialog(
            title: const Text('Security Check (Captcha)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please type "$correctCaptcha" to confirm you are human.'),
                TextField(
                  controller: captchaController,
                  decoration: const InputDecoration(labelText: 'Type "$correctCaptcha"'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(captchaDialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (captchaController.text.trim().toUpperCase() == correctCaptcha) {
                    Navigator.of(captchaDialogContext).pop(true); // Captcha confirmed
                  } else {
                    Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Incorrect captcha. Try again.')),
                    );
                    // Don't pop dialog on incorrect captcha, let user retry
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      return captchaConfirmed ?? false; // Return false if dialog is dismissed
    } else {
      // For other providers (e.g., anonymous, custom token, phone, etc.)
      // In a real app, you MUST implement appropriate re-authentication for sensitive operations.
      // For this example, we'll bypass it for non-email/password and non-Google for simplicity.
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Re-authentication for this provider type is not implemented in this example. Bypassing security check.')),
      );
      return true; // Bypass re-auth for unsupported provider types in this example
    }
  }


  // --- Perform Brand Update (after verification) ---
  Future<void> _performBrandUpdate(String brandDocPath, Map<String, dynamic> updatedData, NavigatorState editDialogNavigator) async {
    try {
      await FirebaseFirestore.instance.doc(brandDocPath).update(updatedData);

      editDialogNavigator.pop(); // Pop the Edit Brand dialog after successful update

      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Brand updated successfully!')),
      );
    } catch (e) {
      print('Error updating Brand: $e');
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to update Brand: $e')),
      );
    }
  }


  // --- Show Add Category Dialog ---
  void _showAddCatalougeDialog() {
    _catalougeNameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _catalougeNameController,
            decoration: const InputDecoration(
              hintText: 'Enter category name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _catalougeNameController.clear();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              onPressed: () => _addCatalouge(Navigator.of(dialogContext)),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // --- Show Add Brand Dialog ---
  void _showAddBrandDialog() {
    _brandNameController.clear();
    _quantitiesController.clear();
    _colourController.clear();
    _sizeController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategoryId = null; // Reset selection
      _selectedCategoryName = null; // Reset name
    });

    if (_currentUser == null) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('User not logged in. Cannot add brand.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Brand'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser!.uid)
                      .collection('category')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No Categories found. Please add one first.'),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Error loading Categories: ${snapshot.error}'),
                      );
                    }

                    List<DropdownMenuItem<String>> categoryItems = [];
                    String? currentSelectedName; // Store name temporarily for initial selection
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      final categoryName = (data?['name'] as String?) ?? 'Unnamed Category';
                      categoryItems.add(
                        DropdownMenuItem(
                          value: doc.id,
                          child: Text(categoryName),
                        ),
                      );
                      if (doc.id == _selectedCategoryId) {
                        currentSelectedName = categoryName;
                      }
                    }

                    if (_selectedCategoryId == null && categoryItems.isNotEmpty) {
                      _selectedCategoryId = categoryItems.first.value;
                      currentSelectedName = (snapshot.data!.docs.first.data() as Map<String,dynamic>?)?['name'] ?? 'Unnamed Category';
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_selectedCategoryId != null && currentSelectedName != _selectedCategoryName) {
                        setState(() {
                          _selectedCategoryName = currentSelectedName;
                        });
                      }
                    });


                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Select Category'),
                      items: categoryItems,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategoryId = newValue;
                          _selectedCategoryName = snapshot.data!.docs
                              .firstWhere((doc) => doc.id == newValue)
                              .get('name');
                        });
                      },
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantitiesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantities',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _colourController,
                  decoration: const InputDecoration(
                    labelText: 'Colour',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Size (e.g., S, M, L / 32, 34)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _brandNameController.clear();
                _quantitiesController.clear();
                _colourController.clear();
                _sizeController.clear();
                _descriptionController.clear();
                setState(() {
                  _selectedCategoryId = null;
                  _selectedCategoryName = null;
                });
              },
            ),
            ElevatedButton(
              onPressed: () => _addBrand(Navigator.of(dialogContext)),
              child: const Text('Add Brand'),
            ),
          ],
        );
      },
    );
  }

  // --- Add Brand Function ---
  Future<void> _addBrand(NavigatorState dialogNavigator) async {
    final String? categoryId = _selectedCategoryId;
    final String? categoryName = _selectedCategoryName; // Use the stored category name
    final String brandName = _brandNameController.text.trim();
    final int quantities = int.tryParse(_quantitiesController.text.trim()) ?? 0;
    final String colour = _colourController.text.trim();
    final String size = _sizeController.text.trim();
    final String description = _descriptionController.text.trim();

    if (categoryId.isNullOrEmpty || categoryName.isNullOrEmpty) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please select a category and ensure its name is loaded.')),
      );
      return;
    }
    if (brandName.isEmpty) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Brand name cannot be empty.')),
      );
      return;
    }
    if (_currentUser == null) {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in first.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('category')
          .doc(categoryId)
          .collection('brand')
          .add({
        'name': brandName,
        'quantities': quantities,
        'colour': colour,
        'size': size,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName, // Save category name here!
        'createdAt': FieldValue.serverTimestamp(),
      });

      dialogNavigator.pop();
      _brandNameController.clear();
      _quantitiesController.clear();
      _colourController.clear();
      _sizeController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null; // Clear name after successful add
      });
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Brand added successfully!')),
      );
    } catch (e) {
      print('Error adding Brand: $e');
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to add Brand: $e')),
      );
    }
  }

  // --- Verify Auth and Update Brand ---
  Future<void> _verifyAuthAndUpdateBrand(String brandDocPath, Map<String, dynamic> updatedData, NavigatorState editDialogNavigator) async {
    bool verified = await _reauthenticateUser(context);
    if (verified) {
      await _performBrandUpdate(brandDocPath, updatedData, editDialogNavigator);
    } else {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Verification failed. Brand not updated.')),
      );
    }
  }

  // --- Show Edit Brand Dialog ---
  Future<void> _showEditBrandDialog(DocumentSnapshot brandDoc) async {
    final data = brandDoc.data() as Map<String, dynamic>?;
    if (data == null) return;

    // Pre-fill controllers with existing data from the brand document
    _brandNameController.text = (data['name'] as String?) ?? '';
    _quantitiesController.text = (data['quantities'] as num?)?.toString() ?? '';
    _colourController.text = (data['colour'] as String?) ?? '';
    _sizeController.text = (data['size'] as String?) ?? '';
    _descriptionController.text = (data['description'] as String?) ?? '';

    // Set selected category ID and Name for the dropdown / display
    setState(() {
      _selectedCategoryId = (data['categoryId'] as String?);
      _selectedCategoryName = (data['categoryName'] as String?); // NEW: Get category name from brand doc
    });

    final String brandDocPath = brandDoc.reference.path;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Brand'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Display (Read-only for edit)
                // Display the stored categoryName directly from state/brandDoc.
                AbsorbPointer(
                  absorbing: true, // Make this section non-interactive
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    items: _selectedCategoryId != null && _selectedCategoryName != null
                        ? [
                            DropdownMenuItem(
                              value: _selectedCategoryId,
                              child: Text(_selectedCategoryName!), // Use the stored name
                            ),
                          ]
                        : [], // Empty if no category selected
                    onChanged: (newValue) {}, // No change allowed
                    decoration: const InputDecoration(
                      labelText: 'Category (Cannot change)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantitiesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantities',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _colourController,
                  decoration: const InputDecoration(
                    labelText: 'Colour',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Size (e.g., S, M, L / 32, 34)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Clear and reset state on cancel (important for next add/edit operation)
                _brandNameController.clear();
                _quantitiesController.clear();
                _colourController.clear();
                _sizeController.clear();
                _descriptionController.clear();
                setState(() {
                  _selectedCategoryId = null;
                  _selectedCategoryName = null; // Clear name
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // Prepare updated data from controllers
                final updatedData = {
                  'name': _brandNameController.text.trim(),
                  'quantities': int.tryParse(_quantitiesController.text.trim()) ?? 0,
                  'colour': _colourController.text.trim(),
                  'size': _sizeController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  // Category ID and createdAt are usually not updated during edit
                  // parent category cannot be changed via simple update, requires delete + add
                  'categoryName': _selectedCategoryName, // NEW: Pass the currently selected/displayed category name
                };
                await _verifyAuthAndUpdateBrand(brandDocPath, updatedData, Navigator.of(dialogContext));
              },
              child: const Text('Update Brand'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Please Log In'),
        ),
        body: const Center(
          child: Text('You must be logged in to view categories.'),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          // Left "Category" Section (Main Content Area)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Categories',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          // Toggle search bar visibility
                          setState(() {
                            _isSearchingCategories = !_isSearchingCategories;
                            if (!_isSearchingCategories) {
                              _categorySearchController.clear();
                              _categorySearchQuery = ''; // Clear query when closing search
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _showAddCatalougeDialog,
                      ),
                    ],
                  ),
                ),
                // NEW: Category Search Input Field
                if (_isSearchingCategories)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _categorySearchController,
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _categorySearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _categorySearchController.clear();
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .collection('category')
                        .orderBy('createdAt', descending: true)
                        // NEW: Apply search filter
                        .where('name',
                            isGreaterThanOrEqualTo: _categorySearchQuery.isEmpty ? null : _categorySearchQuery)
                        .where('name',
                            isLessThanOrEqualTo: _categorySearchQuery.isEmpty ? null : _categorySearchQuery + '\uf8ff')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No categories found. Add one!'),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>?;

                          final String categoryName = (data?['name'] as String?) ?? 'Unnamed Category';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      categoryName,
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () async {
                                      if (!mounted) {
                                        print('Widget already unmounted during delete click.');
                                        return;
                                      }

                                      // NEW: Re-authenticate before deleting category
                                      bool verified = await _reauthenticateUser(context);
                                      if (!verified) {
                                        Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                          const SnackBar(content: Text('Deletion cancelled due to verification failure.')),
                                        );
                                        return;
                                      }

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser.uid)
                                            .collection('category')
                                            .doc(doc.id)
                                            .delete();

                                        if (mounted) {
                                          Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                            const SnackBar(content: Text('Category deleted!')),
                                          );
                                        }
                                      } catch (e) {
                                        print('Error deleting Category: $e');
                                        if (mounted) {
                                          Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                            SnackBar(content: Text('Failed to delete Category: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right "Additional Content" Container
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.blueGrey[100],
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Additional Content / Details Here\n\nThis section is now larger!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: _isSearchingBrands // Toggle AppBar title with search field
                  ? TextField(
                      controller: _brandSearchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search brands...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                      ),
                    )
                  : const Text('Brands'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(_isSearchingBrands ? Icons.close : Icons.search), // Toggle icon
                  onPressed: () {
                    setState(() {
                      _isSearchingBrands = !_isSearchingBrands;
                      if (!_isSearchingBrands) {
                        _brandSearchController.clear();
                        _brandSearchQuery = ''; // Clear query when closing search
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddBrandDialog,
                ),
              ],
            ),
            // --- Brand List Content (Categorized and Searchable) ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Outer StreamBuilder: fetches all categories
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('category')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, categorySnapshot) {
                  if (categorySnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (categorySnapshot.hasError) {
                    return Center(child: Text('Error loading categories: ${categorySnapshot.error}'));
                  }
                  if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No categories found to display brands.'));
                  }

                  // Build a ListView of ExpansionTiles, one for each category
                  return ListView.builder(
                    itemCount: categorySnapshot.data!.docs.length,
                    itemBuilder: (context, catIndex) {
                      final categoryDoc = categorySnapshot.data!.docs[catIndex];
                      final categoryData = categoryDoc.data() as Map<String, dynamic>?;
                      final String categoryId = categoryDoc.id;
                      final String categoryName = (categoryData?['name'] as String?) ?? 'Unnamed Category';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ExpansionTile( // Use ExpansionTile for collapsible categories
                          title: Text(
                            categoryName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          children: [
                            // Inner StreamBuilder: fetches brands for this specific category, filtered by search query
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .collection('category')
                                  .doc(categoryId) // Get brands only for this category
                                  .collection('brand')
                                  .orderBy('name', descending: false) // Order brands by name
                                  // NEW: Apply brand search filter
                                  .where('name',
                                      isGreaterThanOrEqualTo: _brandSearchQuery.isEmpty ? null : _brandSearchQuery)
                                  .where('name',
                                      isLessThanOrEqualTo: _brandSearchQuery.isEmpty ? null : _brandSearchQuery + '\uf8ff')
                                  .snapshots(),
                              builder: (context, brandSnapshot) {
                                if (brandSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (brandSnapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('Error loading brands: ${brandSnapshot.error}'),
                                  );
                                }
                                if (!brandSnapshot.hasData || brandSnapshot.data!.docs.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No brands in this category. Add one!'),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true, // Important: prevents unbounded height error in nested ListView
                                  physics: const NeverScrollableScrollPhysics(), // Important: for nested scrolling
                                  itemCount: brandSnapshot.data!.docs.length,
                                  itemBuilder: (context, brandIndex) {
                                    final brandDoc = brandSnapshot.data!.docs[brandIndex];
                                    final brandData = brandDoc.data() as Map<String, dynamic>?;

                                    final String brandName = (brandData?['name'] as String?) ?? 'Unnamed Brand';
                                    final int quantities = (brandData?['quantities'] as num?)?.toInt() ?? 0;
                                    final String colour = (brandData?['colour'] as String?) ?? 'Unknown';
                                    final String size = (brandData?['size'] as String?) ?? 'N/A';
                                    final String description = (brandData?['description'] as String?) ?? 'No description';
                                    // categoryName is already handled by the parent ExpansionTile's title


                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: InkWell(
                                        onTap: () => _showEditBrandDialog(brandDoc),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                brandName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Smaller font for sub-items
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 2),
                                              // Removed direct category display as it's the parent ExpansionTile's job
                                              Text('Qty: $quantities'),
                                              Text('Colour: $colour'),
                                              if (size != 'N/A') Text('Size: $size'),
                                              if (description != 'No description') Text('Description: $description'),
                                              Align(
                                                alignment: Alignment.bottomRight,
                                                child: IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), // Smaller icon
                                                  onPressed: () async {
                                                    if (!mounted) return;

                                                    // NEW: Re-authenticate before deleting brand
                                                    bool verified = await _reauthenticateUser(context);
                                                    if (!verified) {
                                                      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                                        const SnackBar(content: Text('Deletion cancelled due to verification failure.')),
                                                      );
                                                      return;
                                                    }

                                                    try {
                                                      await brandDoc.reference.delete();
                                                      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                                        const SnackBar(content: Text('Brand deleted!')),
                                                      );
                                                    } catch (e) {
                                                      print('Error deleting Brand: $e');
                                                      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                                        SnackBar(content: Text('Failed to delete Brand: $e')),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to check if String is null or empty. (Common utility)
extension StringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}