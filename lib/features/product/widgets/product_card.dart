import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../cart/services/wishlist_service.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final int priceInt;
  final String imageUrl;
  final String categoryId;
  final VoidCallback onTap;

  const ProductCard({
    super.key, 
    required this.id,
    required this.title,
    required this.price,
    required this.priceInt,
    required this.imageUrl,
    required this.categoryId,
    required this.onTap,
  });

  Future<void> _toggleWishlist(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm yêu thích')),
      );
      return;
    }

    final wishlistService = WishlistService();
    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/wishlist/$id');
    final snapshot = await dbRef.get();
    
    if (snapshot.exists) {
        await wishlistService.removeItem(uid: user.uid, productId: id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa khỏi danh sách yêu thích')),
          );
        }
    } else {
        await wishlistService.addItem(
            uid: user.uid,
            productId: id,
            productName: title,
            price: priceInt,
            thumbnail: imageUrl,
            categoryId: categoryId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm vào danh sách yêu thích')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder(
                      stream: user == null ? null : FirebaseDatabase.instance.ref('users/${user.uid}/wishlist/$id').onValue,
                      builder: (context, snapshot) {
                        final exists = snapshot.hasData && 
                                       snapshot.data != null && 
                                       (snapshot.data! as DatabaseEvent).snapshot.exists;
                        
                        return GestureDetector(
                          onTap: () => _toggleWishlist(context),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(
                              exists ? Icons.favorite : Icons.favorite_border,
                              size: 16, 
                              color: exists ? Colors.red : Colors.grey
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text("Brand Name", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}