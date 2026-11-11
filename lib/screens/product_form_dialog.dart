import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormDialog({super.key, this.productToEdit});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _soluongController;
  late TextEditingController _imageController;

  bool _isLoading = false;
  String _currentImage = '';

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _priceController = TextEditingController(
      text: widget.productToEdit != null ? widget.productToEdit!.price.toStringAsFixed(0) : '',
    );
    _soluongController = TextEditingController(
      text: widget.productToEdit != null ? widget.productToEdit!.soluong.toString() : '',
    );
    _imageController = TextEditingController(text: widget.productToEdit?.image ?? '');
    _currentImage = widget.productToEdit?.image ?? '';

    _imageController.addListener(() {
      if (_imageController.text != _currentImage) {
        setState(() {
          _currentImage = _imageController.text.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _soluongController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImageService.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _currentImage = pickedImage;
        _imageController.text = pickedImage;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final int soluong = int.tryParse(_soluongController.text.trim()) ?? 0;

    final newProduct = ProductModel(
      name: _nameController.text.trim(),
      price: price,
      soluong: soluong,
      image: _currentImage.trim(),
    );

    try {
      if (isEditing) {
        await FirebaseService.instance.updateProduct(widget.productToEdit!.name, newProduct);
      } else {
        await FirebaseService.instance.addProduct(newProduct);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Cập nhật sản phẩm thành công!'
                  : 'Thêm sản phẩm mới thành công!',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tiêu đề
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit_note : Icons.add_box_outlined,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Sửa thông tin sản phẩm' : 'Thêm sản phẩm mới',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Xem trước hình ảnh & Nút chọn ảnh
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                              ),
                              child: ImageService.buildProductImage(
                                _currentImage,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.deepPurple,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                padding: EdgeInsets.zero,
                                onPressed: () => _showImageSourceDialog(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Chọn ảnh từ máy'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera, size: 18),
                              label: const Text('Chụp ảnh'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tên sản phẩm (name)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm (name) *',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên sản phẩm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Giá sản phẩm (price)
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá sản phẩm (price) *',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: 'VNĐ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập giá sản phẩm';
                      }
                      final p = double.tryParse(val.trim());
                      if (p == null || p < 0) {
                        return 'Giá sản phẩm phải là số không âm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Số lượng (soluong)
                  TextFormField(
                    controller: _soluongController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng (soluong) *',
                      prefixIcon: Icon(Icons.production_quantity_limits),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      final s = int.tryParse(val.trim());
                      if (s == null || s < 0) {
                        return 'Số lượng phải là số nguyên không âm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Hình ảnh (image)
                  TextFormField(
                    controller: _imageController,
                    decoration: InputDecoration(
                      labelText: 'Đường dẫn ảnh hoặc Base64 (image)',
                      prefixIcon: const Icon(Icons.link),
                      border: const OutlineInputBorder(),
                      helperText: 'Có thể dán URL web hoặc chọn file ảnh ở trên',
                      suffixIcon: _imageController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _imageController.clear();
                                setState(() => _currentImage = '');
                              },
                            )
                          : null,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 24),

                  // Nút Lưu và Hủy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy bỏ'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _isLoading ? null : _saveProduct,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện thiết bị'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh từ Camera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
