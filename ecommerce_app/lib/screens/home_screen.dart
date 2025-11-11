// Part 1: Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart'; // 1. ADD THIS IMPORT
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/cart_screen.dart'; // 2. ADD THIS
import 'package:provider/provider.dart'; // 3. ADD THIS
import 'package:ecommerce_app/screens/order_history_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/profile_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/widgets/notification_icon.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'admin';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. --- THIS IS THE CHANGE ---
        //    DELETE your old title:
        /*
        title: Text(_currentUser != null ? 'Welcome!' : 'Home'),
        */

        // 2. ADD this new title:
        title: Image.asset(
          'assets/images/app_logo.png', // 3. The path to your logo
          height: 40, // 4. Set a fixed height
        ),
        // 5. 'centerTitle' is now handled by our global AppBarTheme

        // --- END OF CHANGE ---

        actions: [
          // 1. Cart Icon (Unchanged)
          Consumer<CartProvider>(
            // 2. The "builder" function rebuilds *only* the icon
            builder: (context, cart, child) {
              // 3. The "Badge" widget adds a small label
              return Badge(
                // 4. Get the count from the provider
                label: Text(cart.itemCount.toString()),
                // 5. Only show the badge if the count is > 0
                isLabelVisible: cart.itemCount > 0,
                // 6. This is the child (our icon button)
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // 7. Navigate to the CartScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 2. --- ADD OUR NEW WIDGET ---
          const NotificationIcon(),
          // --- END OF NEW WIDGET ---

          // 3. "My Orders" Icon (Unchanged)
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),

          // 4. Admin Icon (Unchanged)
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // 5. --- THIS IS THE CHANGE ---
          //    DELETE the old "Logout" IconButton
          /*
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut, // We are deleting this
          ),
          */

          // 6. ADD this new "Profile" IconButton
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              // 1. Get the whole document
              final productDoc = products[index];
              // 2. Get the data map
              final productData = productDoc.data() as Map<String, dynamic>;

              // 3. Find your old ProductCard
              return ProductCard(
                productName: productData['name'],
                price: productData['price'],
                imageUrl: productData['imageUrl'],

                // 4. --- THIS IS THE NEW PART ---
                //    Add the onTap property
                onTap: () {
                  // 5. Navigate to the new screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        // 6. Pass the data to the new screen
                        productData: productData,
                        productId: productDoc.id, // 7. Pass the unique ID!
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // 1. --- REPLACE YOUR 'floatingActionButton:' ---
      floatingActionButton: _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
              // 2. A new StreamBuilder
              // 3. Listen to *this user's* chat document
              stream: _firestore
                  .collection('chats')
                  .doc(_currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                // 4. Check if the doc exists and has our count field
                if (snapshot.hasData && snapshot.data!.exists) {
                  // Ensure data is not null before casting
                  final data = snapshot.data!.data();
                  if (data != null) {
                    unreadCount =
                        (data as Map<String, dynamic>)['unreadByUserCount'] ??
                            0;
                  }
                }

                // 5. --- THE FIX for "trailing not defined" ---
                //    We wrap the FAB in the Badge widget
                return Badge(
                  // 6. Show the count in the badge
                  label: Text('$unreadCount'),
                  // 7. Only show the badge if the count is > 0
                  isLabelVisible: unreadCount > 0,
                  // 8. The FAB is now the *child* of the Badge
                  child: FloatingActionButton.extended(
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Admin'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: _currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  ),
                );
                // --- END OF FIX ---
              },
            )
          : null, // 9. If admin, don't show the FAB
    );
  }
}
