class Product {
  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });

  final String? id;
  final String name;
  final double price;
  final int soluong;
  final String image;

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? soluong,
    String? image,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    soluong: soluong ?? this.soluong,
    image: image ?? this.image,
  );

  Map<String, Object> toMap() => {
    'name': name,
    'price': price,
    'soluong': soluong,
    'image': image,
  };

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
    id: id,
    name: map['name']?.toString() ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0,
    soluong: (map['soluong'] as num?)?.toInt() ?? 0,
    image: map['image']?.toString() ?? '',
  );
}
