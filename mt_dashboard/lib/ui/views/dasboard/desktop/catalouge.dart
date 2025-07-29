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

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Catalouge App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  final TextEditingController _catalougeNameController = TextEditingController();

  // --- Brand Search Controller & State (for middle panel) ---
  final TextEditingController _brandSearchController = TextEditingController();
  String _brandSearchQuery = '';
  bool _isSearchingBrands = false;

  // --- Brand Input Controllers & State (used for both Add and Edit) ---
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _quantitiesController = TextEditingController();
  final TextEditingController _colourController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _reauthPasswordController = TextEditingController();

  String? _currentlySelectedCategoryIdForMiddlePanel;
  String? _currentlySelectedCategoryNameForMiddlePanel;

  DocumentSnapshot? _currentlySelectedBrandForPreview;

  @override
  void initState() {
    super.initState();
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
    _priceController.dispose();
    _descriptionController.dispose();
    _reauthPasswordController.dispose();
    _brandSearchController.dispose();
    super.dispose();
  }

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
      _reauthPasswordController.clear();
      bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (reauthDialogContext) {
          return AlertDialog(
            title: const Text('Confirm your password'),
            content: TextField(
              controller: _reauthPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(reauthDialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String password = _reauthPasswordController.text;
                  try {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: currentUser.email!,
                      password: password,
                    );
                    await currentUser.reauthenticateWithCredential(credential);
                    Navigator.of(reauthDialogContext).pop(true);
                  } on FirebaseAuthException catch (e) {
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
      return confirmed ?? false;
    } else if (isGoogleUser) {
      final TextEditingController captchaController = TextEditingController();
      const String correctCaptcha = "VERIFY";

      bool? captchaConfirmed = await showDialog<bool>(
        context: context,
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
                    Navigator.of(captchaDialogContext).pop(true);
                  } else {
                    Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Incorrect captcha. Try again.')),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      return captchaConfirmed ?? false;
    } else {
      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
            content: Text(
                'Re-authentication for this provider type is not implemented in this example. Bypassing security check.')),
      );
      return true;
    }
  }

  Future<void> _performBrandUpdate(String brandDocPath, Map<String, dynamic> updatedData, NavigatorState editDialogNavigator) async {
    try {
      await FirebaseFirestore.instance.doc(brandDocPath).update(updatedData);

      editDialogNavigator.pop();

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

  void _showAddBrandDialog() {
    _brandNameController.clear();
    _quantitiesController.clear();
    _colourController.clear();
    _sizeController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
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
                        child: Text('No Catalouges found. Please add one first.'),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Error loading Catalouges: ${snapshot.error}'),
                      );
                    }

                    List<DropdownMenuItem<String>> categoryItems = [];
                    String? currentSelectedName;
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
                // Price field with $ prefix
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  inputFormatters: [
                    // Optionally, you can add input formatters for numeric input
                  ],
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
                _priceController.clear();
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

  Future<void> _addBrand(NavigatorState dialogNavigator) async {
    final String? categoryId = _selectedCategoryId;
    final String? categoryName = _selectedCategoryName;
    final String brandName = _brandNameController.text.trim();
    final int quantities = int.tryParse(_quantitiesController.text.trim()) ?? 0;
    final String colour = _colourController.text.trim();
    final String size = _sizeController.text.trim();
    String price = _priceController.text.trim();
    final String description = _descriptionController.text.trim();

    // Ensure price always starts with a dollar sign
    if (price.isNotEmpty && !price.startsWith('\$')) {
      price = '\$' + price;
    }

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
        'price': price, // Always with dollar sign
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      dialogNavigator.pop();
      _brandNameController.clear();
      _quantitiesController.clear();
      _colourController.clear();
      _sizeController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
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

  Future<void> _showEditBrandDialog(DocumentSnapshot brandDoc) async {
    final data = brandDoc.data() as Map<String, dynamic>?;
    if (data == null) return;

    _brandNameController.text = (data['name'] as String?) ?? '';
    _quantitiesController.text = (data['quantities'] as num?)?.toString() ?? '';
    _colourController.text = (data['colour'] as String?) ?? '';
    _sizeController.text = (data['size'] as String?) ?? '';
    // Remove any leading $ for editing, but will add back on save
    String priceValue = (data['price'] as String?) ?? '';
    _priceController.text = priceValue.startsWith('\$') ? priceValue.substring(1) : priceValue;
    _descriptionController.text = (data['description'] as String?) ?? '';

    setState(() {
      _selectedCategoryId = (data['categoryId'] as String?);
      _selectedCategoryName = (data['categoryName'] as String?);
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
                AbsorbPointer(
                  absorbing: true,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    items: _selectedCategoryId != null && _selectedCategoryName != null
                        ? [
                            DropdownMenuItem(
                              value: _selectedCategoryId,
                              child: Text(_selectedCategoryName!),
                            ),
                          ]
                        : [],
                    onChanged: (newValue) {},
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
                // Price field with $ prefix
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  inputFormatters: [
                    // Optionally, you can add input formatters for numeric input
                  ],
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
                _priceController.clear();
                _descriptionController.clear();
                setState(() {
                  _selectedCategoryId = null;
                  _selectedCategoryName = null;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedPrice = _priceController.text.trim();
                if (updatedPrice.isNotEmpty && !updatedPrice.startsWith('\$')) {
                  updatedPrice = '\$' + updatedPrice;
                }
                final updatedData = {
                  'name': _brandNameController.text.trim(),
                  'quantities': int.tryParse(_quantitiesController.text.trim()) ?? 0,
                  'colour': _colourController.text.trim(),
                  'size': _sizeController.text.trim(),
                  'price': updatedPrice,
                  'description': _descriptionController.text.trim(),
                  'categoryName': _selectedCategoryName,
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
        key: GlobalKey<ScaffoldState>(),
        appBar: AppBar(
          title: const Text('Please Log In'),
        ),
        body: const Center(
          child: Text('You must be logged in to view catalouges.'),
        ),
      );
    }

    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
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
                      Expanded(
                        child: Text(
                          'Catalouges',
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
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _showAddCatalougeDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .collection('category')
                        .orderBy('createdAt', descending: true)
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
                          child: Text('No catalouges found. Add one!'),
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
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentlySelectedCategoryIdForMiddlePanel = doc.id;
                                  _currentlySelectedCategoryNameForMiddlePanel = categoryName;
                                  _brandSearchController.clear();
                                  _brandSearchQuery = '';
                                  _isSearchingBrands = false;
                                  _currentlySelectedBrandForPreview = null;
                                });
                              },
                                child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                  Expanded(
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
                                      // Display brand count
                                      StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .collection('category')
                                        .doc(doc.id)
                                        .collection('brand')
                                        .snapshots(),
                                      builder: (context, brandSnapshot) {
                                        if (brandSnapshot.hasError) {
                                        return const SizedBox.shrink();
                                        }
                                        if (!brandSnapshot.hasData) {
                                        return const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                        }
                                        final int count = brandSnapshot.data!.docs.length;
                                        return Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          ),
                                        ),
                                        );
                                      },
                                      ),
                                    ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () async {
                                    if (!mounted) {
                                      print('Widget already unmounted during delete click.');
                                      return;
                                    }

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

                                      if (_currentlySelectedCategoryIdForMiddlePanel == doc.id) {
                                      setState(() {
                                        _currentlySelectedCategoryIdForMiddlePanel = null;
                                        _currentlySelectedCategoryNameForMiddlePanel = null;
                                        _currentlySelectedBrandForPreview = null;
                                      });
                                      }

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
          // Middle Container: Displays Brands based on selected category (or all brands categorized)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                AppBar(
                  title: _currentlySelectedCategoryIdForMiddlePanel == null
                      ? _isSearchingBrands
                          ? TextField(
                              controller: _brandSearchController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Search all products...',
                                hintStyle: TextStyle(color: Colors.black),
                                border: InputBorder.none,
                              ),
                            )
                          : const Text('All Products')
                      : Text(_currentlySelectedCategoryNameForMiddlePanel ?? 'Brands'),
                  leading: _currentlySelectedCategoryIdForMiddlePanel != null
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              _currentlySelectedCategoryIdForMiddlePanel = null;
                              _currentlySelectedCategoryNameForMiddlePanel = null;
                              _brandSearchController.clear();
                              _brandSearchQuery = '';
                              _isSearchingBrands = false;
                              _currentlySelectedBrandForPreview = null;
                            });
                          },
                        )
                      : null,
                  automaticallyImplyLeading: false,
                  actions: [
                    if (_currentlySelectedCategoryIdForMiddlePanel == null)
                      IconButton(
                        icon: Icon(_isSearchingBrands ? Icons.close : Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearchingBrands = !_isSearchingBrands;
                            if (!_isSearchingBrands) {
                              _brandSearchController.clear();
                              _brandSearchQuery = '';
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
                Expanded(
                  child: _currentlySelectedCategoryIdForMiddlePanel == null
                      ? StreamBuilder<QuerySnapshot>(
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
                              return Center(child: Text('Error loading catalouges: ${categorySnapshot.error}'));
                            }
                            if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
                              return const Center(child: Text('No catalouges found to display brands.'));
                            }

                            return ListView.builder(
                              itemCount: categorySnapshot.data!.docs.length,
                              itemBuilder: (context, catIndex) {
                                final categoryDoc = categorySnapshot.data!.docs[catIndex];
                                final categoryData = categoryDoc.data() as Map<String, dynamic>?;
                                final String categoryId = categoryDoc.id;
                                final String categoryName = (categoryData?['name'] as String?) ?? 'Unnamed Category';

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: ExpansionTile(
                                    title: Text(
                                      categoryName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    children: [
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser.uid)
                                            .collection('category')
                                            .doc(categoryId)
                                            .collection('brand')
                                            .orderBy('name', descending: false)
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
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: brandSnapshot.data!.docs.length,
                                            itemBuilder: (context, brandIndex) {
                                              final brandDoc = brandSnapshot.data!.docs[brandIndex];
                                              final brandData = brandDoc.data() as Map<String, dynamic>?;

                                              final String brandName = (brandData?['name'] as String?) ?? 'Unnamed Brand';
                                              final int quantities = (brandData?['quantities'] as num?)?.toInt() ?? 0;
                                              final String colour = (brandData?['colour'] as String?) ?? 'Unknown';
                                              final String size = (brandData?['size'] as String?) ?? 'N/A';
                                              final String price = (brandData?['price'] as String?) ?? '\$0.00';
                                              final String description = (brandData?['description'] as String?) ?? 'No description';

                                              return Card(
                                                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _currentlySelectedBrandForPreview = brandDoc;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          brandName,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text('Qty: $quantities'),
                                                        Text('Colour: $colour'),
                                                        if (size != 'N/A') Text('Size: $size'),
                                                        Text('Price: $price'),
                                                        if (description != 'No description') Text('Description: $description'),
                                                        Align(
                                                          alignment: Alignment.bottomRight,
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 18),
                                                                onPressed: () => _showEditBrandDialog(brandDoc),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                                                onPressed: () async {
                                                                  if (!mounted) return;
                                                                  bool verified = await _reauthenticateUser(context);
                                                                  if (!verified) {
                                                                    Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                                                      const SnackBar(content: Text('Deletion cancelled due to verification failure.')),
                                                                    );
                                                                    return;
                                                                  }
                                                                  try {
                                                                    await brandDoc.reference.delete();
                                                                    if (_currentlySelectedBrandForPreview?.id == brandDoc.id) {
                                                                      setState(() {
                                                                        _currentlySelectedBrandForPreview = null;
                                                                      });
                                                                    }
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
                                                            ],
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
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .collection('category')
                              .doc(_currentlySelectedCategoryIdForMiddlePanel)
                              .collection('brand')
                              .orderBy('name', descending: false)
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
                              return Center(child: Text('Error loading brands: ${brandSnapshot.error}'));
                            }
                            if (!brandSnapshot.hasData || brandSnapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text('No brands found for this category. Add one!'),
                              );
                            }

                            return ListView.builder(
                              itemCount: brandSnapshot.data!.docs.length,
                              itemBuilder: (context, brandIndex) {
                                final brandDoc = brandSnapshot.data!.docs[brandIndex];
                                final brandData = brandDoc.data() as Map<String, dynamic>?;

                                final String brandName = (brandData?['name'] as String?) ?? 'Unnamed Brand';
                                final int quantities = (brandData?['quantities'] as num?)?.toInt() ?? 0;
                                final String colour = (brandData?['colour'] as String?) ?? 'Unknown';
                                final String size = (brandData?['size'] as String?) ?? 'N/A';
                                final String price = (brandData?['price'] as String?) ?? '\$0.00';
                                final String description = (brandData?['description'] as String?) ?? 'No description';

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentlySelectedBrandForPreview = brandDoc;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            brandName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Qty: $quantities'),
                                          Text('Colour: $colour'),
                                          if (size != 'N/A') Text('Size: $size'),
                                          Text('Price: $price'),
                                          if (description != 'No description') Text('Description: $description'),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 18),
                                                  onPressed: () => _showEditBrandDialog(brandDoc),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                                  onPressed: () async {
                                                    if (!mounted) return;

                                                    bool verified = await _reauthenticateUser(context);
                                                    if (!verified) {
                                                      Catalouge.scaffoldMessengerKey.currentState?.showSnackBar(
                                                        const SnackBar(content: Text('Deletion cancelled due to verification failure.')),
                                                      );
                                                      return;
                                                    }

                                                    try {
                                                      await brandDoc.reference.delete();
                                                      if (_currentlySelectedBrandForPreview?.id == brandDoc.id) {
                                                        setState(() {
                                                          _currentlySelectedBrandForPreview = null;
                                                        });
                                                      }
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
                                              ],
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
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _currentlySelectedBrandForPreview == null
                ? Container(
                    color: Colors.blueGrey[50],
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Click a brand to see its preview here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.blueGrey[50],
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _currentlySelectedBrandForPreview = null;
                                });
                              },
                            ),
                          ),
                          Text(
                            (_currentlySelectedBrandForPreview!['name'] as String?) ?? 'Unnamed Brand',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Category: ${(_currentlySelectedBrandForPreview!['categoryName'] as String?) ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text('Price: ${(_currentlySelectedBrandForPreview!['price'] as String?) ?? '\$0.00'}'),
                          Text('Quantities: ${(_currentlySelectedBrandForPreview!['quantities'] as num?) ?? 0}'),
                          Text('Colour: ${(_currentlySelectedBrandForPreview!['colour'] as String?) ?? 'Unknown'}'),
                          if ((_currentlySelectedBrandForPreview!['size'] as String?) != 'N/A')
                            Text('Size: ${(_currentlySelectedBrandForPreview!['size'] as String?)}'),
                          if ((_currentlySelectedBrandForPreview!['description'] as String?) != 'No description')
                            Text('Description: ${(_currentlySelectedBrandForPreview!['description'] as String?)}'),
                          const SizedBox(height: 20),
                          const Divider(),
                          const Text(
                            'Additional Brand Preview Details (e.g., images, charts)',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      drawer: null,
    );
  }
}

extension StringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
