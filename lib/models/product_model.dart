class ProductModel {
  final String name;
  final double price;
  final int soluong;
  final String image;

  ProductModel({
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });

  // Chuyển đổi sang Map để lưu trữ trên Firebase Firestore / JSON
  // Chú ý: Chỉ bao gồm đúng 4 trường: name, price, soluong, image
  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'price': price,
      'soluong': soluong,
      'image': image.trim(),
    };
  }

  // Khởi tạo từ Map (Firestore / JSON)
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      name: map['name']?.toString() ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : (double.tryParse(map['price']?.toString() ?? '') ?? 0.0),
      soluong: (map['soluong'] is num)
          ? (map['soluong'] as num).toInt()
          : (int.tryParse(map['soluong']?.toString() ?? '') ?? 0),
      image: map['image']?.toString() ?? '',
    );
  }

  ProductModel copyWith({
    String? name,
    double? price,
    int? soluong,
    String? image,
  }) {
    return ProductModel(
      name: name ?? this.name,
      price: price ?? this.price,
      soluong: soluong ?? this.soluong,
      image: image ?? this.image,
    );
  }
}
