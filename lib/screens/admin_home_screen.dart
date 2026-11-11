import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';
import 'login_screen.dart';
import 'product_detail_dialog.dart';
import 'product_form_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

enum ProductSortOption {
  nameAsc('Tên (A-Z)'),
  nameDesc('Tên (Z-A)'),
  priceAsc('Giá tăng dần'),
  priceDesc('Giá giảm dần'),
  soluongDesc('Số lượng giảm dần');

  final String label;
  const ProductSortOption(this.label);
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSortOption _selectedSort = ProductSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterAndSortProducts(List<ProductModel> products) {
    var result = products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery);
    }).toList();

    switch (_selectedSort) {
      case ProductSortOption.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.soluongDesc:
        result.sort((a, b) => b.soluong.compareTo(a.soluong));
        break;
    }

    return result;
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    final str = intPrice.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  void _openAddProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProductFormDialog(),
    );
  }

  void _openEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProductFormDialog(productToEdit: product),
    );
  }

  void _openDetailDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => ProductDetailDialog(
        product: product,
        onEdit: () => _openEditProductDialog(product),
        onDelete: () => _confirmDeleteProduct(product),
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" khỏi cơ sở dữ liệu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirebaseService.instance.deleteProduct(product.name);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa sản phẩm "${product.name}" thành công!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  void _showExportJsonDialog() async {
    final jsonStr = await FirebaseService.instance.exportToJson();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 550),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.data_object, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Cơ sở dữ liệu JSON (đúng 4 trường)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const Text(
                  'Tập tin JSON đúng theo yêu cầu đề thi: chỉ chứa name, price, soluong, image.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        jsonStr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.lightGreenAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Đóng'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonStr));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép JSON vào Clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Sao chép toàn bộ JSON'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFirebaseSetupGuide() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_done, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Thông tin kết nối Firebase Firestore',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      _buildStepItem(
                        step: '1',
                        title: 'Dự án Firebase đang kết nối',
                        content:
                            'Project ID: giuaki-958ed (Project GiuaKi)\nBộ sưu tập (Collection): products\nCác trường dữ liệu: name, price, soluong, image.',
                      ),
                      _buildStepItem(
                        step: '2',
                        title: 'Kiểm tra quyền truy cập (Security Rules)',
                        content:
                            'Vào Firebase Console > GiuaKi > Firestore Database > tab Rules.\nĐảm bảo có dòng:\nallow read, write: if true;\n(hoặc if request.time < ...)',
                      ),
                      _buildStepItem(
                        step: '3',
                        title: 'Đồng bộ dữ liệu mẫu',
                        content:
                            'Nhấn nút "Nạp mẫu lên Firebase" để đưa ngay 5 sản phẩm mẫu lên Cloud Firestore.\nSau khi nạp, bạn có thể quay lại Firebase Console để xem dữ liệu đồng bộ thời gian thực!',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseService.instance.checkFirestoreConnection();
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(FirebaseService.instance.statusMessage),
                              backgroundColor: Colors.deepPurple,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Kiểm tra lại kết nối'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({required String step, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.deepPurple,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirebaseReady = FirebaseService.instance.isFirebaseReady;
    final projectId = FirebaseService.instance.projectId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 750;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 3,
        title: Row(
          children: [
            const Icon(Icons.storefront, size: 26),
            const SizedBox(width: 10),
            const Text(
              'HỆ THỐNG QUẢN LÝ SẢN PHẨM',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            // Trạng thái kết nối DB
            InkWell(
              onTap: _showFirebaseSetupGuide,
              child: Builder(
                builder: (context) {
                  final state = FirebaseService.instance.connectionState;
                  Color bgColor;
                  IconData icon;
                  String text;

                  switch (state) {
                    case FirestoreConnectionState.connected:
                      bgColor = Colors.green.shade700;
                      icon = Icons.cloud_done;
                      text = 'Firestore: $projectId (Online)';
                      break;
                    case FirestoreConnectionState.databaseNotFound:
                      bgColor = Colors.amber.shade900;
                      icon = Icons.warning_amber_rounded;
                      text = 'Chưa bật Firestore trên Console';
                      break;
                    case FirestoreConnectionState.permissionDenied:
                      bgColor = Colors.deepOrange.shade800;
                      icon = Icons.lock_clock;
                      text = 'Bị chặn quyền Rules';
                      break;
                    case FirestoreConnectionState.notConfigured:
                      bgColor = Colors.orange.shade800;
                      icon = Icons.cloud_off;
                      text = 'Mock Local DB';
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: bgColor.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          text,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông tin kết nối Firebase',
            icon: const Icon(Icons.help_outline),
            onPressed: _showFirebaseSetupGuide,
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: FirebaseService.instance.getProductsStream(),
        builder: (context, snapshot) {
          final allProducts = snapshot.data ?? [];
          final filteredProducts = _filterAndSortProducts(allProducts);

          // Tính toán thống kê KPI kho hàng
          final int totalStock = allProducts.fold(0, (sum, p) => sum + p.soluong);
          final double totalValue = allProducts.fold(0.0, (sum, p) => sum + (p.price * p.soluong));

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28.0 : 14.0,
              vertical: 18.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. CÁC THẺ THỐNG KÊ KHO HÀNG (KPI DASHBOARD)
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        icon: Icons.inventory_2,
                        iconColor: Colors.deepPurple,
                        title: 'Tổng số sản phẩm',
                        value: '${allProducts.length}',
                        subValue: 'mặt hàng',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        icon: Icons.production_quantity_limits,
                        iconColor: Colors.blue.shade700,
                        title: 'Tổng số lượng kho',
                        value: '$totalStock',
                        subValue: 'sản phẩm',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        icon: Icons.monetization_on,
                        iconColor: Colors.green.shade700,
                        title: 'Tổng giá trị hàng',
                        value: _formatPrice(totalValue),
                        subValue: 'toàn kho',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. THANH CÔNG CỤ TÌM KIẾM, SẮP XẾP & NÚT THAO TÁC
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Hàng tìm kiếm và sắp xếp
                        Row(
                          children: [
                            // Ô tìm kiếm
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm theo tên sản phẩm...',
                                  prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => _searchController.clear(),
                                        )
                                      : null,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Dropdown sắp xếp
                            Expanded(
                              flex: isDesktop ? 1 : 2,
                              child: DropdownButtonFormField<ProductSortOption>(
                                value: _selectedSort,
                                isDense: true,
                                decoration: InputDecoration(
                                  labelText: 'Sắp xếp',
                                  prefixIcon: const Icon(Icons.sort, color: Colors.deepPurple),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: ProductSortOption.values.map((option) {
                                  return DropdownMenuItem(
                                    value: option,
                                    child: Text(option.label, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    setState(() => _selectedSort = newVal);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Hàng các nút bấm chức năng
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Đang hiển thị: ${filteredProducts.length} / ${allProducts.length} sản phẩm',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                // Nút xuất file JSON
                                OutlinedButton.icon(
                                  onPressed: _showExportJsonDialog,
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Xuất JSON (Nộp bài)'),
                                ),
                                // Nút nạp dữ liệu mẫu lên Firebase nếu đang kết nối
                                if (isFirebaseReady)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade800,
                                      side: BorderSide(color: Colors.green.shade700),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final count = await FirebaseService.instance
                                            .seedSampleDataToFirestore();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Đã nạp $count sản phẩm mẫu lên Cloud Firestore (giuaki-958ed)!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.cloud_upload, size: 18),
                                    label: const Text('Nạp mẫu lên Firebase'),
                                  ),
                                // Nút thêm sản phẩm
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    elevation: 2,
                                  ),
                                  onPressed: _openAddProductDialog,
                                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                                  label: const Text('Thêm sản phẩm'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. DANH SÁCH HOẶC BẢNG SẢN PHẨM
                filteredProducts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Chưa có sản phẩm nào trong kho.'
                                  : 'Không tìm thấy sản phẩm phù hợp với "$_searchQuery"',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openAddProductDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm sản phẩm mới ngay'),
                            ),
                          ],
                        ),
                      )
                    : (isDesktop
                        ? _buildDesktopTable(filteredProducts)
                        : _buildMobileList(filteredProducts)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Thẻ thống kê KPI
  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subValue,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện bảng cho màn hình rộng (Web / Desktop)
  Widget _buildDesktopTable(List<ProductModel> products) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
            horizontalMargin: 20,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Hình ảnh (image)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tên sản phẩm (name)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Giá (price)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Số lượng (soluong)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  // Cột hình ảnh
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ImageService.buildProductImage(
                          product.image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    onTap: () => _openDetailDialog(product),
                  ),
                  // Cột tên sản phẩm
                  DataCell(
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onTap: () => _openDetailDialog(product),
                  ),
                  // Cột giá
                  DataCell(
                    Text(
                      _formatPrice(product.price),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => _openDetailDialog(product),
                  ),
                  // Cột số lượng
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.soluong > 10
                            ? Colors.green.shade50
                            : (product.soluong > 0 ? Colors.orange.shade50 : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: product.soluong > 10
                              ? Colors.green.shade400
                              : (product.soluong > 0 ? Colors.orange.shade400 : Colors.red.shade400),
                        ),
                      ),
                      child: Text(
                        '${product.soluong} sản phẩm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: product.soluong > 10
                              ? Colors.green.shade800
                              : (product.soluong > 0 ? Colors.orange.shade900 : Colors.red.shade900),
                        ),
                      ),
                    ),
                    onTap: () => _openDetailDialog(product),
                  ),
                  // Cột thao tác (Xem, Sửa, Xóa)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          tooltip: 'Xem chi tiết',
                          onPressed: () => _openDetailDialog(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          tooltip: 'Sửa',
                          onPressed: () => _openEditProductDialog(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Xóa',
                          onPressed: () => _confirmDeleteProduct(product),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Giao diện danh sách Card cho màn hình nhỏ (Mobile Android / iOS)
  Widget _buildMobileList(List<ProductModel> products) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ImageService.buildProductImage(
                product.image,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatPrice(product.price),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.soluong > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: product.soluong > 0 ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Text(
                        'SL: ${product.soluong}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: product.soluong > 0 ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'detail':
                    _openDetailDialog(product);
                    break;
                  case 'edit':
                    _openEditProductDialog(product);
                    break;
                  case 'delete':
                    _confirmDeleteProduct(product);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Xem chi tiết'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _openDetailDialog(product),
          ),
        );
      },
    );
  }
}
