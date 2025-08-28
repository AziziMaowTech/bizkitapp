import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

// Imports for the new sidebar's navigation
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_view.dart';


class PosViewDesktop extends StatefulWidget {
  const PosViewDesktop({super.key});

  @override
  State<PosViewDesktop> createState() => _PosViewDesktopState();
}

class _PosViewDesktopState extends State<PosViewDesktop> {
  String? selectedCatalog;
  List<Map<String, dynamic>> billItems = [];
  double total = 0.0; // Subtotal before any discounts
  String? customerName;
  String? selectedMemberId; // Stores the ID of the selected member
  String? selectedPayment;
  String? checkoutMessage;
  String searchQuery = '';
  
  bool _isSidebarExpanded = false; // State for new sidebar
  bool _isBillDetailsExpanded = true; // State for expandable bill details

  List<Map<String, dynamic>> appliedDiscounts = [];

  bool _isManualDiscountInputEnabled = false;
  final TextEditingController _manualDiscountController = TextEditingController();

  final TextEditingController _couponCodeController = TextEditingController();
  Timer? _couponDebounceTimer;

  @override
  void initState() {
    super.initState();
    _manualDiscountController.addListener(_onManualDiscountChanged);
    _couponCodeController.addListener(_onCouponCodeChanged);
  }

  @override
  void didUpdateWidget(covariant PosViewDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This allows manualDiscountController to be updated by other logic (like clear on member select)
    // without triggering its own listener if the text content didn't actually change.
    // However, the _onManualDiscountChanged is attached, so it will still fire.
    // The previous implementation of _onManualDiscountChanged already checks if _isManualDiscountInputEnabled.
  }

  @override
  void dispose() {
    _manualDiscountController.removeListener(_onManualDiscountChanged);
    _manualDiscountController.dispose();
    _couponCodeController.removeListener(_onCouponCodeChanged);
    _couponCodeController.dispose();
    _couponDebounceTimer?.cancel();
    super.dispose();
  }

  void _onManualDiscountChanged() {
    setState(() {
      if (!_isManualDiscountInputEnabled) {
        _clearDiscountType('Manual Discount');
        return; 
      }

      final String value = _manualDiscountController.text;
      double? parsedValue = double.tryParse(value);

      if (parsedValue != null && parsedValue >= 0 && parsedValue <= 100) {
        _addOrUpdateDiscount('Manual Discount', parsedValue);
      } else {
        _clearDiscountType('Manual Discount');
      }
    });
  }

  void _onCouponCodeChanged() {
    _couponDebounceTimer?.cancel();
    _couponDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final String couponCode = _couponCodeController.text.trim();
      if (couponCode.isNotEmpty) {
        _applyCouponDiscount(couponCode);
      } else {
        setState(() {
          _clearDiscountType('Coupon Discount');
        });
      }
    });
  }

  Future<void> _applyCouponDiscount(String couponCode) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    if (total <= 0) { // No discount if total is 0
      setState(() {
        _clearDiscountType('Coupon Discount');
      });
      return;
    }

    if (userId.isEmpty || couponCode.isEmpty) {
      setState(() {
        _clearDiscountType('Coupon Discount');
      });
      return;
    }

    try {
      final couponQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('promo_coupons')
          .where('code', isEqualTo: couponCode)
          .limit(1)
          .get();

      if (couponQuerySnapshot.docs.isNotEmpty) {
        final couponDocSnapshot = couponQuerySnapshot.docs.first;
        final data = couponDocSnapshot.data();
        final bool isActive = data['isActive'] ?? false;
        final String? discountType = data['discountType']?.toString();
        final double discountValue = (data['discountValue'] as num?)?.toDouble() ?? 0.0;
        final Timestamp? expiryDate = data['expiryDate'] as Timestamp?;
        final int currentUses = (data['currentUses'] as num?)?.toInt() ?? 0;
        final int maxUses = (data['maxUses'] as num?)?.toInt() ?? -1;

        if (!isActive) {
          print('DEBUG: Coupon is not active.');
          setState(() => _clearDiscountType('Coupon Discount'));
          return;
        }
        if (expiryDate != null && expiryDate.toDate().isBefore(DateTime.now())) {
          print('DEBUG: Coupon has expired.');
          setState(() => _clearDiscountType('Coupon Discount'));
          return;
        }
        if (maxUses != -1 && currentUses >= maxUses) {
          print('DEBUG: Coupon has reached its maximum uses.');
          setState(() => _clearDiscountType('Coupon Discount'));
          return;
        }
        if (discountValue <= 0) {
          print('DEBUG: Coupon has invalid discount value.');
          setState(() => _clearDiscountType('Coupon Discount'));
          return;
        }

        double calculatedPercentage = 0.0;
        if (discountType == 'percentage') {
          calculatedPercentage = discountValue.clamp(0.0, 100.0);
        } else if (discountType == 'fixed amount') {
          calculatedPercentage = (discountValue / total * 100).clamp(0.0, 100.0);
          print('DEBUG: Fixed amount coupon converted to percentage: $calculatedPercentage%');
        } else {
          print('DEBUG: Unknown discount type for coupon.');
          setState(() => _clearDiscountType('Coupon Discount'));
          return;
        }
        
        setState(() {
          _addOrUpdateDiscount('Coupon Discount', calculatedPercentage);
          print('DEBUG: Coupon Discount applied: $calculatedPercentage%');
        });
        
      } else {
        setState(() {
          _clearDiscountType('Coupon Discount');
          print('DEBUG: Coupon code "$couponCode" does not exist.');
        });
      }
    } catch (e) {
      print('ERROR: Applying coupon discount: $e');
      setState(() {
        _clearDiscountType('Coupon Discount');
      });
    }
  }


  void _addOrUpdateDiscount(String type, double percentage) {
    int index = appliedDiscounts.indexWhere((d) => d['type'] == type);
    if (percentage > 0) {
      if (index != -1) {
        appliedDiscounts[index]['percentage'] = percentage;
      } else {
        appliedDiscounts.add({'type': type, 'percentage': percentage});
      }
    } else {
      if (index != -1) {
        appliedDiscounts.removeAt(index);
      }
    }
  }

  void _clearDiscountType(String type) {
    appliedDiscounts.removeWhere((d) => d['type'] == type);
  }

  double get _totalDiscountPercentage {
    double sum = 0.0;
    for (var discount in appliedDiscounts) {
      sum += (discount['percentage'] as double);
    }
    return sum.clamp(0.0, 100.0);
  }


  void addToBill(Map<String, dynamic> product) {
    setState(() {
      final String productName = product['name'];
      final double productPrice = (product['price'] ?? 0.0);

      int existingIndex = billItems.indexWhere((item) => item['name'] == productName);

      if (existingIndex != -1) {
        billItems[existingIndex]['quantity'] += 1;
        billItems[existingIndex]['itemTotal'] += productPrice;
      } else {
        billItems.add({
          'name': productName,
          'unitPrice': productPrice,
          'quantity': 1,
          'itemTotal': productPrice,
        });
      }
      total += productPrice;

      _couponDebounceTimer?.cancel();
      _couponDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final String couponCode = _couponCodeController.text.trim();
        if (couponCode.isNotEmpty) {
          _applyCouponDiscount(couponCode);
        } else {
          setState(() {
            _clearDiscountType('Coupon Discount');
          });
        }
      });
    });
  }

  void removeFromBill(int index) {
    setState(() {
      final item = billItems[index];
      final double unitPrice = item['unitPrice'];

      if (item['quantity'] > 1) {
        item['quantity'] -= 1;
        item['itemTotal'] -= unitPrice;
      } else {
        billItems.removeAt(index);
      }
      total -= unitPrice;

      _couponDebounceTimer?.cancel();
      _couponDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final String couponCode = _couponCodeController.text.trim();
        if (couponCode.isNotEmpty) {
          _applyCouponDiscount(couponCode);
        } else {
          setState(() {
            _clearDiscountType('Coupon Discount');
          });
        }
      });
    });
  }


  Future<void> _getMemberDiscount(String? memberId) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    print('DEBUG: _getMemberDiscount called. userId: $userId, memberId: $memberId');

    if (userId.isEmpty || memberId == null || memberId.isEmpty) {
      setState(() {
        _clearDiscountType('Member Discount');
        print('DEBUG: No member selected or userId empty. Removing Member Discount.');
      });
      return;
    }
    
    try {
      final memberDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('members')
          .doc(memberId)
          .get();

      if (memberDocSnapshot.exists) {
        final data = memberDocSnapshot.data();
        final discountStringWithPercent = data?['discount']?.toString();
        
        print('DEBUG: Found member document for "$memberId". Raw data: $data');
        print('DEBUG: Raw discount string from member document: "$discountStringWithPercent"');

        double parsedDiscount = 0.0;
        if (discountStringWithPercent != null && discountStringWithPercent.isNotEmpty) {
          final cleanedDiscountString = discountStringWithPercent.replaceAll('%', '').trim();
          parsedDiscount = double.tryParse(cleanedDiscountString) ?? 0.0;
        }

        setState(() {
          _addOrUpdateDiscount('Member Discount', parsedDiscount);
          print('DEBUG: Member Discount applied: $parsedDiscount');
        });
      } else {
        setState(() {
          _clearDiscountType('Member Discount');
          print('DEBUG: Member document "$memberId" does NOT exist. Removing Member Discount.');
        });
      }
    } catch (e) {
      print("ERROR: getting member discount: $e");
      setState(() {
        _clearDiscountType('Member Discount');
      });
    }
  }

  Future<void> checkout() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    for (var item in billItems) {
      final String itemName = item['name'];
      final int itemQuantityInBill = item['quantity'];

      final catalogQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('catalogs')
          .get();

      for (var catalog in catalogQuery.docs) {
        final productQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('catalogs')
            .doc(catalog.id)
            .collection('products')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();

        if (productQuery.docs.isNotEmpty) {
          final doc = productQuery.docs.first;
          final data = doc.data();
          int currentQtyInFirestore = int.tryParse(data['quantity'].toString()) ?? 0;
          int newQty = currentQtyInFirestore - itemQuantityInBill;
          await doc.reference.update({'quantity': newQty < 0 ? 0 : newQty});
        }
      }
    }

    double finalTotal = total * (1 - _totalDiscountPercentage / 100);

    final couponEntry = appliedDiscounts.firstWhereOrNull((d) => d['type'] == 'Coupon Discount');
    if (couponEntry != null && _couponCodeController.text.isNotEmpty) {
        final String couponCode = _couponCodeController.text.trim();
        try {
            final couponQuery = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('promo_coupons')
                .where('code', isEqualTo: couponCode)
                .limit(1)
                .get();

            if (couponQuery.docs.isNotEmpty) {
                final couponDocRef = couponQuery.docs.first.reference;
                final currentUses = (couponQuery.docs.first.data()['currentUses'] as num?)?.toInt() ?? 0;
                await couponDocRef.update({'currentUses': currentUses + 1});
                print('DEBUG: Incremented usage for coupon: $couponCode');
            }
        } catch (e) {
            print('ERROR: Failed to increment coupon usage for $couponCode: $e');
        }
    }


    final billData = {
      'items': billItems.map((item) => {
        'name': item['name'],
        'unitPrice': item['unitPrice'],
        'quantity': item['quantity'],
        'itemTotal': item['itemTotal'],
      }).toList(),
      'originalTotal': total,
      'finalTotal': finalTotal,
      'customerName': customerName,
      'selectedMemberId': selectedMemberId,
      'appliedDiscounts': appliedDiscounts.map((d) => {
        'type': d['type'],
        'percentage': d['percentage'],
      }).toList(),
      'totalDiscountPercentage': _totalDiscountPercentage,
      'totalDiscountAmount': total * (_totalDiscountPercentage / 100),
      'payment': selectedPayment,
      'message': checkoutMessage,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('log')
        .add(billData);

    setState(() {
      billItems.clear();
      total = 0.0;
      customerName = null;
      selectedMemberId = null;
      selectedPayment = null;
      checkoutMessage = null;
      appliedDiscounts.clear(); // Clear all discounts
      _isManualDiscountInputEnabled = false;
      _manualDiscountController.clear();
      _couponCodeController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout successful!')),
    );
  }

  Widget _buildExpandedBillDetails() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    double discountedTotal = total * (1 - _totalDiscountPercentage / 100);

    return Container(
      color: Colors.white, // Set background color to white
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                tooltip: 'Collapse',
                onPressed: () {
                  setState(() {
                    _isBillDetailsExpanded = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Combined Customer Name and Member Selection
          _CustomerNameAndMemberInput(
            userId: userId,
            initialCustomerName: customerName, // Pass current customer name
            initialMemberId: selectedMemberId, // Pass current selected member ID
            onChangedAndMemberId: (name, memberId) {
              setState(() {
                customerName = name;
                selectedMemberId = memberId;
                _isManualDiscountInputEnabled = false;
                _manualDiscountController.clear();
                _clearDiscountType('Manual Discount');
                _couponCodeController.clear(); // Clear coupon on member selection
                _clearDiscountType('Coupon Discount'); // Clear coupon discount
                _getMemberDiscount(memberId);
              });
            },
          ),
          const SizedBox(height: 16),
          // Manual Discount Input with Checkbox
          Row(
            children: [
              Checkbox(
                value: _isManualDiscountInputEnabled,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isManualDiscountInputEnabled = newValue ?? false;
                    if (!_isManualDiscountInputEnabled) {
                      _manualDiscountController.clear();
                      _clearDiscountType('Manual Discount');
                    }
                    // No longer clear member discount if manual is enabled, as they now stack
                    _onManualDiscountChanged();
                  });
                },
              ),
              Expanded(
                child: TextFormField(
                  controller: _manualDiscountController,
                  enabled: _isManualDiscountInputEnabled,
                  decoration: const InputDecoration(
                    labelText: 'Manual Discount (%)',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Coupon Code Input Field
          TextFormField(
            controller: _couponCodeController,
            decoration: const InputDecoration(
              labelText: 'Coupon Code',
              hintText: 'Enter coupon code',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.local_offer),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Payment',
              border: OutlineInputBorder(),
            ),
            value: selectedPayment,
            items: const [
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(value: 'Card', child: Text('Card')),
              DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet')),
            ],
            onChanged: (value) => setState(() => selectedPayment = value),
          ),
          const SizedBox(height: 16),
          // TextField for the custom message
          TextField(
            decoration: const InputDecoration(
              labelText: 'Checkout Message (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => checkoutMessage = val,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: billItems.length,
              itemBuilder: (context, index) {
                final item = billItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} ${item['quantity'] > 1 ? 'x${item['quantity']}' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Text('\$${(item['itemTotal'] ?? 0.0).toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange),
                            onPressed: () => removeFromBill(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 16)),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            ],
          ),
          ...appliedDiscounts.map((discount) {
            final discountPercentage = discount['percentage'] as double;
            final discountAmount = total * (discountPercentage / 100);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${discount['type']} (${discountPercentage.toStringAsFixed(0)}%):',
                    style: const TextStyle(fontSize: 16, color: Colors.green)),
                Text(
                    '-\$${discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, color: Colors.green)),
              ],
            );
          }).toList(),
          
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18)),
              Text(
                  '\$${discountedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: billItems.isNotEmpty ? checkout : null,
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedBillDetails() {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        tooltip: 'Expand Bill Details',
        onPressed: () {
          setState(() {
            _isBillDetailsExpanded = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building PosViewDesktop. Total Discount Percentage: $_totalDiscountPercentage, Total Discount Amount: ${total * (_totalDiscountPercentage / 100)}, Applied Discounts: $appliedDiscounts');

    return Scaffold(
      body: Row(
        children: [
          // New Sidebar from dashboard_view.desktop.dart
          MouseRegion(
            onEnter: (event) {
              setState(() {
                _isSidebarExpanded = true;
              });
            },
            onExit: (event) {
              setState(() {
                _isSidebarExpanded = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isSidebarExpanded ? 240 : 70,
              child: Sidebar(
                isExpanded: _isSidebarExpanded,
              ),
            ),
          ),
          // Main Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    children: [
                      Text('Orders', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _RealtimeTimeDateWidget(),
                      const SizedBox(width: 24),
                      IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                      backgroundColor: Colors.blueGrey[700],
                      child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                    Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Products',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    ),
                  // Catalogs from Firestore
                  SizedBox(
                    height: 48,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                          .collection('catalogs')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Row(
                            children: [
                              _CategoryChip(
                                label: 'All',
                                selected: selectedCatalog == null,
                                onTap: () => setState(() => selectedCatalog = null),
                              ),
                            ],
                          );
                        }
                        final catalogs = snapshot.data!.docs;
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: 'All',
                              selected: selectedCatalog == null,
                              onTap: () => setState(() => selectedCatalog = null),
                            ),
                            ...catalogs.map((cat) {
                              final catData = cat.data() as Map<String, dynamic>;
                              final catId = cat.id;
                              final catName = catData['name'] ?? catId;
                              return _CategoryChip(
                                label: catName,
                                selected: selectedCatalog == catId,
                                onTap: () => setState(() => selectedCatalog = catId),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = '';
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                          ),
                          controller: TextEditingController(text: searchQuery)
                            ..selection = TextSelection.collapsed(offset: searchQuery.length),
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val.trim().toLowerCase();
                            });
                          },
                        ),
                        SizedBox(height: 16),
                  // Products grid from Firestore
                  Expanded(
                    child: StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: selectedCatalog == null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                              .collection('catalogs')
                              .snapshots()
                              .asyncExpand((catalogSnap) async* {
                                List<QueryDocumentSnapshot> allDocs = [];
                                for (var catalog in catalogSnap.docs) {
                                  final productSnap = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                                      .collection('catalogs')
                                      .doc(catalog.id)
                                      .collection('products')
                                      .get();
                                  allDocs.addAll(productSnap.docs);
                                }
                                yield allDocs;
                              })
                          : FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                              .collection('catalogs')
                              .doc(selectedCatalog)
                              .collection('products')
                              .snapshots()
                              .map((snap) => snap.docs),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No products found.'));
                        }
                        final products = snapshot.data!;
                        // Filter products by search query
                        final filteredProducts = searchQuery.isEmpty
                            ? products
                            : products.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = (data['name'] ?? '').toString().toLowerCase();
                                final desc = (data['description'] ?? '').toString().toLowerCase();
                                // Handle colors as List<String>
                                final colorsList = data['colors'] is List
                                    ? (data['colors'] as List).map((e) => e.toString().toLowerCase()).toList()
                                    : (data['colors'] ?? '').toString().toLowerCase().split(',');
                                final colors = colorsList.join(' ');
                                final size = (data['size'] ?? '').toString().toLowerCase();
                                final catalogName = (data['catalogName'] ?? '').toString().toLowerCase();
                                return name.contains(searchQuery) ||
                                    desc.contains(searchQuery) ||
                                    colors.contains(searchQuery) ||
                                    size.contains(searchQuery) ||
                                    catalogName.contains(searchQuery);
                              }).toList();
                        if (filteredProducts.isEmpty) {
                          return const Center(child: Text('No products match your search.'));
                        }
                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.5, // Further adjusted for even taller cards
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final data = filteredProducts[index].data() as Map<String, dynamic>;
                            String priceStr = (data['price'] ?? '0').toString().replaceAll('\$', '').trim();
                            final double price = double.tryParse(priceStr) ?? 0.0;
                            final int quantity = int.tryParse(data['quantity'].toString()) ?? 0;
                            final bool outOfStock = quantity <= 0;
                            final dynamic imageData = data['images'];
                            List<String> imageUrls = [];
                            if (imageData is List) {
                              imageUrls = imageData.map((item) => item.toString()).toList();
                            }
                            // Handle colors as List<String>
                            List<Color> _pickedColors = [];
                            if (data['colors'] is List) {
                              final colorsList = (data['colors'] as List)
                                  .map((e) => e.toString())
                                  .toList();
                              // Try to parse color strings to Color objects
                              _pickedColors = colorsList.map((colorStr) {
                                try {
                                  // Accepts hex string like "#RRGGBB" or "0xFFRRGGBB"
                                  String hex = colorStr.replaceAll('#', '');
                                  if (hex.length == 6) hex = 'FF$hex';
                                  return Color(int.parse('0x$hex'));
                                } catch (_) {
                                  return Colors.grey; // fallback color
                                }
                              }).toList();
                            }
                            if (_pickedColors.isEmpty) {
                              _pickedColors.add(Colors.transparent); // Representing 'No color'
                            }
                            return _ProductCard(
                              name: data['name'] ?? '',
                              quantity: quantity,
                              price: price,
                              description: data['description'] ?? '',
                              colors: _pickedColors.isNotEmpty
                                  ? Row(
                                      children: _pickedColors
                                          .map((c) => Container(
                                                width: 18,
                                                height: 18,
                                                margin: const EdgeInsets.only(right: 4),
                                                decoration: BoxDecoration(
                                                  color: c,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                              ))
                                          .toList(),
                                    )
                                  : Text((data['colors'] ?? 'N/A').toString()),
                              size: data['size'] ?? 'N/A',
                              categoryName: data['categoryName'] ?? 'N/A',
                              onSelect: outOfStock
                                  ? null
                                  : () => addToBill({
                                        'name': data['name'],
                                        'price': price,
                                      }),
                              outOfStock: outOfStock,
                              imageUrls: imageUrls,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable Bill Details
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isBillDetailsExpanded ? 320 : 60,
            color: Colors.grey[100],
            child: _isBillDetailsExpanded
                ? _buildExpandedBillDetails()
                : _buildCollapsedBillDetails(),
          ),
        ],
      ),
    );
  }
}

// --- Sidebar Widget (from dashboard_view.desktop.dart) ---
class Sidebar extends StatelessWidget {
  final bool isExpanded;

  const Sidebar({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    // List of navigation items
    final navItems = [
      _SidebarNavItem(
        icon: Icons.home,
        label: 'Dashboard',
        isSelected: false, // In POS view, Dashboard is not selected
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DashboardView()),
          );
        },
      ),
      _SidebarNavItem(
        icon: Icons.point_of_sale,
        label: 'POS',
        isSelected: true, // POS is selected
        isExpanded: isExpanded,
        onTap: () {
          // Already on POS view, no action needed or refresh
        },
      ),
      _SidebarNavItem(
        icon: Icons.inventory,
        label: 'Inventory',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CatalougeView()),
          );
        },
      ),
      // _SidebarNavItem(
      //   icon: Icons.local_shipping,
      //   label: 'Orders',
      //   isExpanded: isExpanded,
      //   onTap: () {
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (context) => const OrdersView()),
      //     );
      //   },
      // ),
      _SidebarNavItem(
        icon: Icons.calendar_month,
        label: 'Calendar',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CalendarView()),
          );
        },
      ),
      _SidebarNavItem(
        icon: Icons.group,
        label: 'Customers',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MemberView()),
          );
        },
      ),
      // _SidebarNavItem(
      //   icon: Icons.history,
      //   label: 'History',
      //   isExpanded: isExpanded,
      //   onTap: () {
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (context) => const HistoryView()),
      //     );
      //   },
      // ),
    ];

    return Container(
      width: isExpanded ? 240 : 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6F01FD),
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: 96.0),
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: isExpanded
                  ? Image.asset(
                      'assets/images/placeholder.png',
                      height: 100,
                      width: 100,
                    )
                  : Image.asset(
                      'assets/images/placeholder_small.png',
                      height: 50,
                      width: 50,
                    ),
            ),
          ),
          const SizedBox(height: 24.0),
          // Center navigation items vertically
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: navItems,
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24.0),
                child: InkWell(
                  onTap: () async {},
                  borderRadius: BorderRadius.circular(24.0),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 12.0),
                          Text(
                            'Basic Plan',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6F01FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 0.0, vertical: 8.0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.0),
              child: InkWell(
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  final userId = user?.uid;

                  if (userId != null) {
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(userId).collection('activity').add({
                        'type': 'Logout',
                        'message': 'User logged out',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      print('DEBUG: Logout event logged to "activity" collection for user $userId');
                    } catch (e) {
                      print('ERROR: Failed to log logout event for user $userId: $e');
                    }
                  }

                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
                borderRadius: BorderRadius.circular(24.0),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFB8C63),
                        Color(0xFFF74403),
                        Color(0xFFFB8C63),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Container(
                    height: 48,
                    alignment: isExpanded ? Alignment.center : Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24.0 : 0),
                    child: isExpanded
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_outlined, color: Colors.white),
                              SizedBox(width: 12.0),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.logout_outlined, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isPrimary;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isPrimary = false,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    const Color contentBackgroundColor = Color(0xFFF1F5F9);

    Color itemIconColor = isSelected ? const Color(0xFF6F01FD) : Colors.white;

    Color itemTextColor = isSelected ? const Color(0xFF6F01FD) : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected ? contentBackgroundColor : Colors.transparent,
        borderRadius: isSelected
            ? const BorderRadius.horizontal(left: Radius.circular(32.0))
            : const BorderRadius.horizontal(right: Radius.circular(12.0)),
        child: InkWell(
          onTap: onTap,
          borderRadius: isSelected
              ? const BorderRadius.horizontal(left: Radius.circular(32.0))
              : const BorderRadius.horizontal(right: Radius.circular(12.0)),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24.0 : 0.0),
            alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
            child: isExpanded
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: itemIconColor,
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: itemTextColor,
                        ),
                      ),
                    ],
                  )
                : Icon(icon, color: itemIconColor, size: 24),
          ),
        ),
      ),
    );
  }
}


class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.blueGrey[200],
        backgroundColor: Colors.blueGrey[50],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final String description;
  final Widget colors;
  final String size;
  final int quantity;
  final String categoryName;
  final VoidCallback? onSelect;
  final bool outOfStock;
  final List<String>? imageUrls;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.onSelect,
    required this.description,
    required this.colors,
    required this.size,
    required this.quantity,
    this.imageUrls,
    this.outOfStock = false,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext classcontext) {
    Widget imageDisplaySection;

    if (imageUrls != null && imageUrls!.isNotEmpty) {
      Widget actualImageWidget;
      if (imageUrls!.length == 1) {
        actualImageWidget = CachedNetworkImage(
          imageUrl: imageUrls!.first,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[100],
            child: const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          memCacheWidth: 300,
          memCacheHeight: 300,
        );
      } else {
        actualImageWidget = LayoutBuilder(
          builder: (context, constraints) {
            return _ProductImageCarousel(
              imageUrls: imageUrls!,
              height: constraints.maxWidth,
            );
          },
        );
      }
      imageDisplaySection = AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: actualImageWidget,
        ),
      );
    } else {
      imageDisplaySection = AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: Colors.grey[200],
          ),
          child: const Center(
            child: Icon(Icons.fastfood, size: 48, color: Colors.blueGrey),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: outOfStock ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              imageDisplaySection,
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              Text('Qty: $quantity',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Colour: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [colors],
              ),
              Text('Size: $size',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
              Text(description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('\$${price.toStringAsFixed(2)}', textAlign: TextAlign.center),
              const Spacer(),
              ElevatedButton(
                onPressed: outOfStock ? null : onSelect,
                style: outOfStock
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      )
                    : null,
                child: Text(outOfStock ? 'No Stock' : 'Select'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const _ProductImageCarousel({
    required this.imageUrls,
    this.height = 150.0,
  });

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();

    final initialPage = widget.imageUrls.length * 1000;
    _pageController = PageController(initialPage: initialPage);
    _currentPage = initialPage;

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!_isUserInteracting && _pageController.hasClients && mounted) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrls[0],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[100],
              child: const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
            ),
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final imageIndex = index % widget.imageUrls.length;

              return ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[imageIndex],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  memCacheWidth: 400,
                  memCacheHeight: 400,
                ),
              );
            },
          ),

          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) {
                  final isActive = (_currentPage % widget.imageUrls.length) == index;

                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Realtime Time and Date Widget
class _RealtimeTimeDateWidget extends StatefulWidget {
  @override
  State<_RealtimeTimeDateWidget> createState() => _RealtimeTimeDateWidgetState();
}

class _RealtimeTimeDateWidgetState extends State<_RealtimeTimeDateWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}";
    final date = "${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// REVISED WIDGET FOR COMBINED CUSTOMER/MEMBER INPUT
class _CustomerNameAndMemberInput extends StatefulWidget {
  final String? userId;
  final Function(String? name, String? memberId) onChangedAndMemberId;
  final String? initialCustomerName;
  final String? initialMemberId;

  const _CustomerNameAndMemberInput({
    super.key,
    required this.userId,
    required this.onChangedAndMemberId,
    this.initialCustomerName,
    this.initialMemberId,
  });

  @override
  State<_CustomerNameAndMemberInput> createState() => _CustomerNameAndMemberInputState();
}

class _CustomerNameAndMemberInputState extends State<_CustomerNameAndMemberInput> {
  late TextEditingController _customerNameController;
  
  bool _ignoreTextChanges = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.initialCustomerName);
    _customerNameController.addListener(_onTextFieldChanged);
  }

  @override
  void didUpdateWidget(covariant _CustomerNameAndMemberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCustomerName != _customerNameController.text) {
      _ignoreTextChanges = true;
      _customerNameController.text = widget.initialCustomerName ?? '';
      _customerNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _customerNameController.text.length));
      _ignoreTextChanges = false;
    }
  }

  void _onTextFieldChanged() {
    if (_ignoreTextChanges) {
      return;
    }
    final String? currentText = _customerNameController.text.isEmpty ? null : _customerNameController.text;
    widget.onChangedAndMemberId(currentText, null);
  }

  @override
  void dispose() {
    _customerNameController.removeListener(_onTextFieldChanged);
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _selectMember() async {
    final selectedMember = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Member'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('members')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No members found.'));
                }
                final members = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: const Text('Clear Member Selection'),
                        leading: const Icon(Icons.clear),
                        onTap: () {
                          Navigator.pop(dialogContext, {'id': null, 'name': null});
                        },
                      );
                    }
                    final memberDoc = members[index - 1];
                    final memberData = memberDoc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(memberData['name'] ?? memberDoc.id),
                      subtitle: Text('ID: ${memberDoc.id}'),
                      onTap: () {
                        Navigator.pop(dialogContext, {'id': memberDoc.id, 'name': memberData['name']});
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedMember != null) {
      final String? newMemberId = selectedMember['id'];
      final String? newMemberName = selectedMember['name'];

      _ignoreTextChanges = true;
      _customerNameController.text = newMemberName ?? '';
      _customerNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _customerNameController.text.length));
      _ignoreTextChanges = false;

      widget.onChangedAndMemberId(newMemberName, newMemberId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _customerNameController,
      decoration: InputDecoration(
        labelText: 'Customer Name or Select Member',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.person_search),
          onPressed: _selectMember,
          tooltip: 'Select an existing member',
        ),
      ),
    );
  }
}