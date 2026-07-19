import 'package:equatable/equatable.dart';

class ProductGroup extends Equatable {
  final String id;
  final String name;

  const ProductGroup({
    required this.id,
    required this.name,
  });

  ProductGroup copyWith({
    String? id,
    String? name,
  }) {
    return ProductGroup(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
