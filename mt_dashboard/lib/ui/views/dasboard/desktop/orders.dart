import 'package:flutter/material.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'All',
    'Accepted',
    'Completed',
    'Unconfirmed',
    'Rejected'
  ];
  final List<IconData> _icons = [
    Icons.list_alt,
    Icons.check_circle_outline,
    Icons.done_all,
    Icons.help_outline,
    Icons.cancel_outlined,
  ];

  Widget _buildTabContent(int index) {
    // Replace with your actual content widgets for each tab
    return Center(
      child: Text(
        'Content for ${_tabs[index]} Orders',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with title and search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const Text(
                'All Orders',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search orders...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                    foregroundColor: isSelected
                        ? Colors.white
                        : Colors.black87,
                    elevation: isSelected ? 2 : 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  icon: Icon(_icons[index]),
                  label: Text(_tabs[index]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        // Content area
        Expanded(
          child: _buildTabContent(_selectedIndex),
        ),
      ],
    );
  }
}