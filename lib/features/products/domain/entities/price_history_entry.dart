import 'package:equatable/equatable.dart';

class PriceHistoryEntry extends Equatable {
  final String id;
  final String productId;
  final double price;
  final DateTime checkedAt;

  const PriceHistoryEntry({
    required this.id,
    required this.productId,
    required this.price,
    required this.checkedAt,
  });

  @override
  List<Object?> get props => [id, productId, price, checkedAt];
}
