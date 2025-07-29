import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'dart:async';
import 'dart:ui' as ui; // Import for ui.Image

class PublicCatalougeViewDesktop extends StatefulWidget {
  final String? userId; // Add userId parameter

  const PublicCatalougeViewDesktop({super.key, this.userId}); // Add userId to the constructor

  @override
  State<PublicCatalougeViewDesktop> createState() => _PublicCatalougeViewDesktopState();
}

class _PublicCatalougeViewDesktopState extends State<PublicCatalougeViewDesktop> with TickerProviderStateMixin {
  // Future that will hold the result of the Firestore query for products
  late Future<QuerySnapshot<Map<String, dynamic>>> _productsFuture = Future.value(
      FirebaseFirestore.instance.collection('dummy').get() // Initial dummy future
  );

  // Controller for the search input field
  final TextEditingController _searchController = TextEditingController();
  // String to store the current search query
  String _searchQuery = '';

  // TabController for managing category tabs
  late TabController _tabController;
  // List of unique categories, including "All"
  List<String> _categories = ['All'];
  // Currently selected category
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Initialize TabController with a dummy length; it will be re-initialized after categories are fetched
    _tabController = TabController(length: _categories.length, vsync: this);

    _fetchCategoriesAndProducts(); // Fetch categories first, then products
    _searchController.addListener(_onSearchChanged); // Listen to search bar changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.removeListener(_onCategoryTabChanged); // Remove listener before disposing
    _tabController.dispose(); // Dispose the tab controller
    super.dispose();
  }

  // Method called when the text in the search bar changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _fetchPublicProducts(); // Re-fetch products with the new search query and current category
    });
  }

  // Fetches distinct categories from Firestore
  Future<void> _fetchCategoriesAndProducts() async {
    print('Fetching categories...');
    try {
      await Firebase.initializeApp();

      // Query to get all product documents to extract categories
      // This might be inefficient for very large datasets; consider a separate 'categories' collection
      final QuerySnapshot<Map<String, dynamic>> productsSnapshot =
          await FirebaseFirestore.instance.collectionGroup('products').get();

      Set<String> uniqueCategories = {};
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('categoryName') && data['categoryName'] is String && (data['categoryName'] as String).isNotEmpty) {
          uniqueCategories.add(data['categoryName'] as String);
        }
      }

      // Sort categories alphabetically
      List<String> fetchedCategories = uniqueCategories.toList()..sort();

      setState(() {
        _categories = ['All', ...fetchedCategories]; // Add 'All' as the first tab

        // Before creating a new TabController, remove the listener from the old one
        // and dispose of the old one if it exists.
        _tabController.removeListener(_onCategoryTabChanged);
        _tabController.dispose();

        // Re-initialize TabController with the correct number of tabs
        _tabController = TabController(length: _categories.length, vsync: this);
        // Add listener for tab changes to the NEW controller
        _tabController.addListener(_onCategoryTabChanged);

        // Ensure the selected category is still valid, or reset to 'All'
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
          _tabController.index = 0; // Set tab to 'All'
        }
      });

      // After categories are loaded, fetch initial products based on 'All' category
      _fetchPublicProducts();

    } catch (e) {
      print('Error fetching categories: $e');
      // Even if categories fail, still try to load products
      _fetchPublicProducts();
    }
  }

  // Method called when a category tab is changed
  void _onCategoryTabChanged() {
    // Check if the tab controller is not currently animating between tabs
    // and if the index is valid
    if (!_tabController.indexIsChanging && _tabController.index < _categories.length) {
      setState(() {
        _selectedCategory = _categories[_tabController.index];
        print('Selected category: $_selectedCategory');
        _fetchPublicProducts(); // Re-fetch products based on new category
      });
    }
  }

  // Asynchronously fetches public product data from Firestore
  Future<void> _fetchPublicProducts() async {
    print('Attempting to fetch public products for category: $_selectedCategory, search query: $_searchQuery, userId: ${widget.userId}');
    try {
      await Firebase.initializeApp();

      Query<Map<String, dynamic>> query;

      // Check if a userId is provided.
      // If userId is provided, query the specific user's products subcollection.
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        query = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('products');
      } else {
        // If no userId is provided, fall back to collectionGroup (all public products)
        // or handle this case as an error if a userId is always expected.
        query = FirebaseFirestore.instance.collectionGroup('products');
        print('No userId provided, fetching from collectionGroup for all products.');
      }

      // Apply category filter if a specific category is selected
      if (_selectedCategory != 'All') {
        query = query.where('categoryName', isEqualTo: _selectedCategory);
      }

      // Apply search query filter if _searchQuery is not empty
      if (_searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: _searchQuery)
            .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }

      setState(() {
        _productsFuture = query.get();
      });
      print('Firestore query initiated.');

    } catch (e) {
      print('Error fetching public products: $e');
      setState(() {
        _productsFuture = Future.error('Failed to load public products: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Product Showcase'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110.0), // Increased height for search and tabs
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Category Tabs
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Padding below tabs
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true, // Allow tabs to scroll if many categories
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: _categories.map((category) => Tab(text: category)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading products: ${snapshot.error}\nPlease check your Firestore Index and Security Rules.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No public products found for this selection.'));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.55,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productData = products[index].data();
              return ProductCard(product: productData);
            },
          );
        },
      ),
    );
  }
}

// ProductCard (No changes needed for this widget itself)
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Size? _imageDimensions;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product['images']?[0] != oldWidget.product['images']?[0]) {
      _removeImageListener();
      _loadImageDimensions();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
  }

  void _loadImageDimensions() {
    final List<dynamic> images = widget.product['images'] ?? [];
    if (images.isNotEmpty && images[0] is String) {
      final ImageProvider imageProvider = NetworkImage(images[0]);
      _imageStream = imageProvider.resolve(const ImageConfiguration());
      _imageListener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (mounted) {
            setState(() {
              _imageDimensions = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }
        },
        onError: (Object exception, StackTrace? stackTrace) {
          print('Error loading image for dimensions: $exception');
          if (mounted) {
            setState(() {
              _imageDimensions = null;
            });
          }
        },
      );
      _imageStream!.addListener(_imageListener!);
    } else {
      setState(() {
        _imageDimensions = null;
      });
    }
  }

  bool useWhiteForeground(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      print('Error parsing hex color $hexColor: $e');
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.product['name'] ?? 'No Name';
    final String categoryName = widget.product['categoryName'] ?? 'Uncategorized';
    final String price = widget.product['price'] ?? 'Price N/A';
    final List<dynamic> images = widget.product['images'] ?? [];
    final List<dynamic> colors = widget.product['colors'] ?? [];
    final String description = widget.product['description'] ?? 'No description provided.';
    final String size = widget.product['size'] ?? 'N/A';
    final num quantity = widget.product['quantity'] ?? 0;

    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _showProductDetails(context, widget.product),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Center(
                      child: images.isNotEmpty && images[0] is String
                          ? Image.network(
                              images[0],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                            )
                          : const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  description,
                  style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Size: $size',
                  style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Qty: $quantity',
                  style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8.0),
                if (colors.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: colors.map((colorHex) {
                      final color = _getColorFromHex(colorHex.toString());
                      final bool requiresBorder = color == Colors.white || color.alpha < 255;
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: requiresBorder ? Border.all(color: Colors.grey, width: 1.0) : null,
                        ),
                        child: Tooltip(message: colorHex.toString(), child: Container()),
                      );
                    }).toList(),
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: OutlinedButton(
                    onPressed: () {
                      _showProductDetails(context, widget.product);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    final String name = product['name'] ?? 'Product Details';
    final String categoryName = product['categoryName'] ?? 'N/A';
    final String price = product['price'] ?? 'N/A';
    final String description = product['description'] ?? 'No description provided.';
    final List<dynamic> images = product['images'] ?? [];
    final String size = product['size'] ?? 'N/A';
    final num quantity = product['quantity'] ?? 0;
    final List<dynamic> colors = product['colors'] ?? [];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(name),
          scrollable: true,
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.8,
            child: ListBody(
              children: <Widget>[
                if (images.isNotEmpty) ProductCarouselView(images: images),
                const SizedBox(height: 16.0),
                _detailRow('Category', categoryName),
                _detailRow('Price', price),
                _detailRow('Description', description),
                _detailRow('Size', size),
                _detailRow('Quantity Available', quantity.toString()),
                if (colors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Colors: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: colors
                                .map((colorHex) {
                              final color = _getColorFromHex(colorHex.toString());
                              final bool requiresBorder = color == Colors.white || color.alpha < 255;
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: requiresBorder ? Border.all(color: Colors.grey, width: 1.0) : null,
                                ),
                                child: Tooltip(message: colorHex.toString(), child: Container()),
                              );
                            })
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ProductCarouselView (No changes needed for this widget)
class ProductCarouselView extends StatefulWidget {
  final List<dynamic> images;

  const ProductCarouselView({super.key, required this.images});

  @override
  State<ProductCarouselView> createState() => _ProductCarouselViewState();
}

class _ProductCarouselViewState extends State<ProductCarouselView> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  final Map<String, Size> _imageDimensionsMap = {};
  final Map<String, ImageStreamListener> _imageListeners = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    if (widget.images.length > 1) {
      _startAutoPlay();
    }

    _pageController.addListener(() {
      int newPage = _pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });
    _loadAllImageDimensions();
  }

  @override
  void didUpdateWidget(covariant ProductCarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      _removeAllImageListeners();
      _imageDimensionsMap.clear();
      _loadAllImageDimensions();
    }
  }

  void _loadAllImageDimensions() {
    for (String imageUrl in widget.images.whereType<String>()) {
      _loadImageDimensions(imageUrl);
    }
  }

  void _loadImageDimensions(String imageUrl) {
    final ImageProvider imageProvider = NetworkImage(imageUrl);
    final ImageStream imageStream = imageProvider.resolve(const ImageConfiguration());
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _imageDimensionsMap[imageUrl] = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      },
      onError: (Object exception, StackTrace? stackTrace) {
        print('Error loading image for dimensions: $exception');
        if (mounted) {
          setState(() {
            _imageDimensionsMap[imageUrl] = Size.zero;
          });
        }
      },
    );
    imageStream.addListener(listener);
    _imageListeners[imageUrl] = listener;
  }

  void _removeAllImageListeners() {
    _imageListeners.forEach((imageUrl, listener) {
      NetworkImage(imageUrl).resolve(const ImageConfiguration()).removeListener(listener);
    });
    _imageListeners.clear();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.images.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    _removeAllImageListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final imageUrl = widget.images[index];
                  if (imageUrl is! String) {
                    return const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey));
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                      ),
                    ),
                  );
                },
                onPageChanged: (index) {
                  _stopAutoPlay();
                },
              ),
            ),
            if (widget.images.length > 1)
              Positioned.fill(
                left: 8.0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                    onPressed: _currentPage > 0 ? () {
                      _stopAutoPlay();
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } : null,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            if (widget.images.length > 1)
              Positioned.fill(
                right: 8.0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                    onPressed: _currentPage < widget.images.length - 1 ? () {
                      _stopAutoPlay();
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } : null,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (widget.images.length > 1)
          DotsIndicator(
            dotsCount: widget.images.length,
            position: _currentPage.toDouble(),
            decorator: DotsDecorator(
              size: const Size.square(9.0),
              activeSize: const Size(18.0, 9.0),
              activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
              activeColor: Theme.of(context).primaryColor,
              color: Colors.grey[400]!,
            ),
            onTap: (position) {
              _stopAutoPlay();
              _pageController.animateToPage(
                position.toInt(),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
          ),
      ],
    );
  }
}