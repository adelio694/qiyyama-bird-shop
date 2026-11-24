
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final String token;
  final int userId;

  const HomePage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String baseUrl = 'http://localhost:3000';

  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> cart = [];

  bool isLoading = true;
  String selectedCategory = 'Semua';

  final List<String> categories = [
    'Semua',
    'Voer',
    'Pakan & Voer',
    'Tangkringan',
    'Kerodong',
    'Cepuk',
    'Aksesoris',
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          products = result['data'] ?? [];
          filterProducts();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error mengambil produk: $e');
    }
  }

  void filterProducts() {
    if (selectedCategory == 'Semua') {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) {
        final category =
            (product['category_name'] ?? '').toString().toLowerCase();

        return category == selectedCategory.toLowerCase();
      }).toList();
    }
  }

  String getProductName(dynamic product) {
    return product['name']?.toString() ?? 'Produk';
  }

  double getProductPrice(dynamic product) {
    return double.tryParse(product['price'].toString()) ?? 0;
  }

  int getProductStock(dynamic product) {
    return int.tryParse(product['stock'].toString()) ?? 0;
  }

  String formatRupiah(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  void addToCart(dynamic product) {
    final id = product['id'];

    final index = cart.indexWhere(
      (item) => item['id'] == id,
    );

    if (getProductStock(product) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok produk habis')),
      );
      return;
    }

    if (index != -1) {
      if (cart[index]['quantity'] >= getProductStock(product)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah melebihi stok')),
        );
        return;
      }

      setState(() {
        cart[index]['quantity']++;
      });
    } else {
      setState(() {
        cart.add({
          'id': id,
          'name': getProductName(product),
          'price': getProductPrice(product),
          'stock': getProductStock(product),
          'quantity': 1,
        });
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${getProductName(product)} masuk keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void increaseQuantity(int index) {
    if (cart[index]['quantity'] < cart[index]['stock']) {
      setState(() {
        cart[index]['quantity']++;
      });
    }
  }

  void decreaseQuantity(int index) {
    setState(() {
      cart[index]['quantity']--;

      if (cart[index]['quantity'] <= 0) {
        cart.removeAt(index);
      }
    });
  }

  double get totalPrice {
    double total = 0;

    for (var item in cart) {
      total += item['price'] * item['quantity'];
    }

    return total;
  }

  int get totalItems {
    int total = 0;

    for (var item in cart) {
      total += item['quantity'] as int;
    }

    return total;
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/transactions/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'items': cart.map((item) {
            return {
              'product_id': item['id'],
              'quantity': item['quantity'],
            };
          }).toList(),
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        setState(() {
          cart.clear();
        });

        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Checkout berhasil',
            ),
            backgroundColor: Colors.green,
          ),
        );

        fetchProducts();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Checkout gagal',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
    }
  }

  void showCart() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Keranjang Belanja'),
              content: SizedBox(
                width: double.maxFinite,
                child: cart.isEmpty
                    ? const Text('Keranjang masih kosong')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: cart.length,
                              itemBuilder: (context, index) {
                                final item = cart[index];

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item['name']),
                                  subtitle: Text(
                                    formatRupiah(item['price']),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            decreaseQuantity(index);
                                          });
                                        },
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text('${item['quantity']}'),
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            increaseQuantity(index);
                                          });
                                        },
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          Text(
                            'Total: ${formatRupiah(totalPrice)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tutup'),
                ),
                ElevatedButton(
                  onPressed: cart.isEmpty ? null : checkout,
                  child: const Text('Checkout'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildProductImage(dynamic product) {
    final image = product['image']?.toString() ?? '';

    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: 130,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.shopping_bag,
          size: 65,
          color: Colors.green,
        ),
      );
    }

    return const Icon(
      Icons.shopping_bag,
      size: 65,
      color: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'Qiyyama Bird Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: showCart,
                icon: const Icon(Icons.shopping_cart),
              ),
              if (totalItems > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$totalItems',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.green.shade700,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Temukan kebutuhan burung kesayanganmu',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'Kategori Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    selectedColor: Colors.green.shade200,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                        filterProducts();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text(
              'Daftar Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(
                        child: Text('Belum ada produk pada kategori ini'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          return Card(
                            elevation: 3,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.green.shade50,
                                    child: buildProductImage(product),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getProductName(product),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        formatRupiah(
                                          getProductPrice(product),
                                        ),
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stok: ${getProductStock(product)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed:
                                              getProductStock(product) > 0
                                                  ? () => addToCart(product)
                                                  : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Tambah'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
