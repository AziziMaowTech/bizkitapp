// coupon_management_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- PromoCoupon Model ---
class PromoCoupon {
  final String id;
  final String code;
  final String discountType; // e.g., 'percentage', 'fixed'
  final double discountValue;
  final DateTime? expiryDate;
  final bool isActive;
  final int? maxUses; // Total uses for this coupon across all customers
  final int? currentUses; // Current uses for this coupon across all customers

  PromoCoupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.expiryDate,
    required this.isActive,
    this.maxUses,
    this.currentUses,
  });

  factory PromoCoupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoCoupon(
      id: doc.id,
      code: data['code'] ?? '',
      discountType: data['discountType'] ?? 'percentage',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      maxUses: data['maxUses'] as int?,
      currentUses: data['currentUses'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isActive': isActive,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// --- CouponManagementCard ---
class CouponManagementTab extends StatefulWidget {
  const CouponManagementTab({super.key});

  @override
  State<CouponManagementTab> createState() => _CouponManagementTabState();
}

class _CouponManagementTabState extends State<CouponManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _maxUsesController = TextEditingController();
  String _selectedDiscountType = 'percentage';
  bool _isActive = true;
  DateTime? _selectedExpiryDate;

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _addCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add coupons.')),
        );
      }
      return;
    }

    try {
      final code = _codeController.text.trim().toUpperCase();
      final discountValue = double.parse(_valueController.text);
      final maxUses = int.tryParse(_maxUsesController.text);

      final existingCoupons = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('promo_coupons')
          .where('code', isEqualTo: code)
          .get();

      if (existingCoupons.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon code already exists!'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final newCoupon = PromoCoupon(
        id: '',
        code: code,
        discountType: _selectedDiscountType,
        discountValue: discountValue,
        expiryDate: _selectedExpiryDate,
        isActive: _isActive,
        maxUses: maxUses,
        currentUses: 0,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('promo_coupons')
          .add(newCoupon.toFirestore());

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error adding coupon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add coupon: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateCoupon(PromoCoupon coupon) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update coupons.')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('promo_coupons')
          .doc(coupon.id)
          .update(coupon.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error updating coupon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update coupon: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCoupon(String couponId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to delete coupons.')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('promo_coupons')
          .doc(couponId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon deleted successfully!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error deleting coupon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete coupon: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _codeController.clear();
    _valueController.clear();
    _maxUsesController.clear();
    setState(() {
      _selectedDiscountType = 'percentage';
      _isActive = true;
      _selectedExpiryDate = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _showEditCouponDialog(BuildContext dialogContext, PromoCoupon coupon) {
    final editFormKey = GlobalKey<FormState>();
    final TextEditingController editCodeController = TextEditingController(text: coupon.code);
    final TextEditingController editValueController = TextEditingController(text: coupon.discountValue.toString());
    final TextEditingController editMaxUsesController = TextEditingController(text: coupon.maxUses?.toString() ?? '');
    String editSelectedDiscountType = coupon.discountType;
    bool editIsActive = coupon.isActive;
    DateTime? editSelectedExpiryDate = coupon.expiryDate;

    showDialog(
      context: dialogContext,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: editFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Coupon: ${coupon.code}',
                              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: editCodeController,
                          decoration: const InputDecoration(labelText: 'Coupon Code'),
                          validator: (value) => value!.isEmpty ? 'Code cannot be empty' : null,
                        ),
                        const SizedBox(height: 16.0),
                        DropdownButtonFormField<String>(
                          value: editSelectedDiscountType,
                          decoration: const InputDecoration(labelText: 'Discount Type'),
                          items: const [
                            DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                            DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                          ],
                          onChanged: (newValue) {
                            setDialogState(() {
                              editSelectedDiscountType = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: editValueController,
                          decoration: InputDecoration(
                              labelText: editSelectedDiscountType == 'percentage'
                                  ? 'Discount Value (%)'
                                  : 'Discount Value (\$)'
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Value cannot be empty';
                            final numValue = double.tryParse(value);
                            if (numValue == null || numValue < 0) return 'Enter a valid number';
                            if (editSelectedDiscountType == 'percentage' && numValue > 100) {
                              return 'Percentage cannot exceed 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: editMaxUsesController,
                          decoration: const InputDecoration(labelText: 'Maximum Uses (optional)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isNotEmpty && int.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        ListTile(
                          title: Text(editSelectedExpiryDate == null
                              ? 'No Expiry Date'
                              : 'Expiry Date: ${editSelectedExpiryDate!.toLocal().toIso8601String().split('T')[0]}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: editSelectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != editSelectedExpiryDate) {
                              setDialogState(() {
                                editSelectedExpiryDate = picked;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Checkbox(
                              value: editIsActive,
                              onChanged: (bool? newValue) {
                                setDialogState(() {
                                  editIsActive = newValue!;
                                });
                              },
                            ),
                            const Text('Is Active'),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12.0),
                            ElevatedButton(
                              onPressed: () async {
                                if (editFormKey.currentState?.validate() ?? false) {
                                  final updatedCoupon = PromoCoupon(
                                    id: coupon.id,
                                    code: editCodeController.text.trim().toUpperCase(),
                                    discountType: editSelectedDiscountType,
                                    discountValue: double.parse(editValueController.text),
                                    expiryDate: editSelectedExpiryDate,
                                    isActive: editIsActive,
                                    maxUses: int.tryParse(editMaxUsesController.text),
                                    currentUses: coupon.currentUses,
                                  );
                                  await _updateCoupon(updatedCoupon);
                                  if (mounted) Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteCouponConfirmation(BuildContext context, String couponId, String couponCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Coupon'),
          content: Text('Are you sure you want to delete coupon "$couponCode"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteCoupon(couponId);
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, color: Colors.blue[800], size: 20),
                const SizedBox(width: 8.0),
                Text(
                  'Promotional Coupons',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'Create and manage unique coupon codes for promotions.',
              style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16.0),

            // --- Add New Coupon Form ---
            Text(
              'Add New Coupon',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8.0),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'Coupon Code'),
                    validator: (value) => value!.isEmpty ? 'Code cannot be empty' : null,
                  ),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: _selectedDiscountType,
                    decoration: const InputDecoration(labelText: 'Discount Type'),
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDiscountType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _valueController,
                    decoration: InputDecoration(
                        labelText: _selectedDiscountType == 'percentage'
                            ? 'Discount Value (%)'
                            : 'Discount Value (\$)'
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Value cannot be empty';
                      final numValue = double.tryParse(value);
                      if (numValue == null || numValue < 0) return 'Enter a valid number';
                      if (_selectedDiscountType == 'percentage' && numValue > 100) {
                        return 'Percentage cannot exceed 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _maxUsesController,
                    decoration: const InputDecoration(labelText: 'Maximum Uses (optional)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isNotEmpty && int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0),
                  ListTile(
                    title: Text(_selectedExpiryDate == null
                        ? 'No Expiry Date'
                        : 'Expiry Date: ${_selectedExpiryDate!.toLocal().toIso8601String().split('T')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _isActive,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _isActive = newValue!;
                          });
                        },
                      ),
                      const Text('Is Active'),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addCoupon,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Coupon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),

            // --- Coupon List ---
            Text(
              'Existing Coupons',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16.0),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
                if (user == null) {
                  return Stream.empty();
                }
                return FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('promo_coupons')
                    .snapshots();
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading coupons: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No promotional coupons found.'),
                  );
                }

                final coupons = snapshot.data!.docs
                    .map((doc) => PromoCoupon.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 0.5,
                      child: ListTile(
                        title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${coupon.discountValue}${coupon.discountType == 'percentage' ? '%' : '\$' + (coupon.discountType == 'fixed' ? '' : '')} Off'),
                            if (coupon.expiryDate != null)
                              Text('Expires: ${coupon.expiryDate!.toLocal().toIso8601String().split('T')[0]}'),
                            Text('Status: ${coupon.isActive ? 'Active' : 'Inactive'}'),
                            if (coupon.maxUses != null)
                              Text('Uses: ${coupon.currentUses ?? 0}/${coupon.maxUses}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditCouponDialog(context, coupon);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteCouponConfirmation(context, coupon.id, coupon.code);
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
          ],
        ),
      ),
    );
  }
}