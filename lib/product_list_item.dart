import 'package:flutter/material.dart';
import 'package:pos_system/core/theme/app_theme.dart';
import 'package:pos_system/data/database/pos_database.dart';
import 'dart:io'; // For File

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAddToCart;

  const ProductListItem({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = product.isLowStock;
    final bool isOutOfStock = product.isOutOfStock;
    final bool isActive = product.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Adjust horizontal margin if needed by parent
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image
              _buildProductImage(product.imagePath),
              const SizedBox(width: 16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // Semi-bold for prominence
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.barcode != null && product.barcode!.isNotEmpty
                          ? 'Code: ${product.barcode}'
                          : 'ID: ${product.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        Text(
                          '${product.priceTtc.toStringAsFixed(0)} F', // Assuming 'F' is the currency symbol
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Stock Status
                        _buildStockStatus(isOutOfStock, isLowStock, product.stockQty),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Actions (Edit / Add to Cart)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Modifier le produit',
                    ),
                  if (onAddToCart != null && isActive)
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart_outlined, color: AppColors.accent, size: 20),
                      onPressed: onAddToCart,
                      tooltip: 'Ajouter au panier',
                    ),
                  if (!isActive)
                    const Icon(Icons.visibility_off_outlined, color: AppColors.textMuted, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 30),
    );
  }

  Widget _buildStockStatus(bool isOutOfStock, bool isLowStock, int stockQty) {
    Color color;
    String text;
    IconData icon;

    if (isOutOfStock) {
      color = AppColors.danger;
      text = 'Rupture';
      icon = Icons.cancel_outlined;
    } else if (isLowStock) {
      color = AppColors.warning;
      text = 'Faible';
      icon = Icons.warning_amber_outlined;
    } else {
      color = AppColors.success;
      text = 'En stock';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$text ($stockQty)',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}