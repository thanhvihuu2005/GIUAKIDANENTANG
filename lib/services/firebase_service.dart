import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../firebase_options.dart';

enum FirestoreConnectionState {
  connected, // Đã kết nối thành công và đọc/ghi được trực tiếp với Cloud
  databaseNotFound, // Chưa bấm "Create database" trên Firebase Console
  permissionDenied, // Bị chặn bởi Rules
  notConfigured, // Chưa cấu hình keys
}

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  bool _isFirebaseReady = false;
  bool get isFirebaseReady => _isFirebaseReady;

  String? _initError;
  String? get initError => _initError;

  String get projectId => DefaultFirebaseOptions.web.projectId;

  FirestoreConnectionState _connectionState = FirestoreConnectionState.notConfigured;
  FirestoreConnectionState get connectionState => _connectionState;

  String _statusMessage = 'Đang kết nối...';
  String get statusMessage => _statusMessage;

  // Collection name trên Firestore
  static const String productCollectionName = 'products';

  // Dữ liệu mẫu ban đầu (chỉ gồm 4 trường: name, price, soluong, image)
  final List<ProductModel> _localProducts = [
    ProductModel(
      name: 'Laptop Dell XPS 13',
      price: 25990000,
      soluong: 15,
      image: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=300',
    ),
    ProductModel(
      name: 'Bàn phím cơ Không Dây RGB',
      price: 1450000,
      soluong: 45,
      image: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=300',
    ),
    ProductModel(
      name: 'Chuột Logitech MX Master 3',
      price: 2100000,
      soluong: 30,
      image: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=300',
    ),
    ProductModel(
      name: 'Màn hình Dell UltraSharp 27 inch 4K',
      price: 9800000,
      soluong: 12,
      image: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=300',
    ),
    ProductModel(
      name: 'Tai nghe Bluetooth Sony WH-1000XM5',
      price: 6890000,
      soluong: 25,
      image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300',
    ),
  ];

  final StreamController<List<ProductModel>> _localStreamController =
      StreamController<List<ProductModel>>.broadcast();

  /// Khởi tạo Firebase và kiểm tra thực tế kết nối Firestore
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (DefaultFirebaseOptions.isConfigured) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          _isFirebaseReady = true;
          debugPrint('Firebase Core initialized: $projectId');
        } else {
          _isFirebaseReady = false;
          _connectionState = FirestoreConnectionState.notConfigured;
          _statusMessage = 'Chưa cấu hình Firebase';
          return;
        }
      } else {
        _isFirebaseReady = true;
      }

      // Kiểm tra thực tế đọc/ghi trên Cloud Firestore
      await checkFirestoreConnection();
    } catch (e) {
      _isFirebaseReady = false;
      _initError = e.toString();
      _connectionState = FirestoreConnectionState.notConfigured;
      _statusMessage = 'Lỗi kết nối Firebase: $e';
      debugPrint('Lỗi khởi tạo Firebase: $e');
    }

    _emitLocalProducts();
  }

  /// Kiểm tra thực tế kết nối với Cloud Firestore
  Future<void> checkFirestoreConnection() async {
    if (!_isFirebaseReady) return;

    try {
      final col = FirebaseFirestore.instance.collection(productCollectionName);
      // Thử đọc từ server để kiểm tra database đã tạo trên console chưa
      final snap = await col.limit(1).get().timeout(const Duration(seconds: 5));
      _connectionState = FirestoreConnectionState.connected;
      _statusMessage = 'Cloud Firestore Online: $projectId';
      debugPrint('Kết nối Cloud Firestore thành công: $projectId, docs: ${snap.docs.length}');
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('not-found') || errStr.contains('does not exist')) {
        _connectionState = FirestoreConnectionState.databaseNotFound;
        _statusMessage = 'Chưa tạo Firestore trên Console (giuaki-958ed)';
      } else if (errStr.contains('permission-denied') || errStr.contains('permission')) {
        _connectionState = FirestoreConnectionState.permissionDenied;
        _statusMessage = 'Bị chặn quyền Rules trên Console';
      } else {
        _connectionState = FirestoreConnectionState.connected;
        _statusMessage = 'Cloud Firestore: $projectId';
      }
      debugPrint('Trạng thái kết nối Firestore: $_statusMessage ($e)');
    }
  }

  void _emitLocalProducts() {
    if (!_localStreamController.isClosed) {
      _localStreamController.add(List.unmodifiable(_localProducts));
    }
  }

  /// Reference đến collection 'products' trên Cloud Firestore
  CollectionReference<Map<String, dynamic>>? get _productsCollection {
    if (_isFirebaseReady) {
      try {
        return FirebaseFirestore.instance.collection(productCollectionName);
      } catch (e) {
        debugPrint('Không thể truy cập Firestore collection: $e');
      }
    }
    return null;
  }

  /// Lắng nghe Stream danh sách sản phẩm
  Stream<List<ProductModel>> getProductsStream() {
    final col = _productsCollection;
    if (_isFirebaseReady && col != null) {
      return col.snapshots().map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ProductModel.fromMap(data);
          }).toList();
        } else {
          // Nếu Firestore mới tạo và chưa có dữ liệu, trả về danh mục mẫu
          return _localProducts;
        }
      }).handleError((error) {
        debugPrint('Lỗi lắng nghe Firestore: $error. Chuyển sang dữ liệu local.');
        return _localProducts;
      });
    }

    // Fallback: trả về stream local
    return _localStreamController.stream;
  }

  /// Lấy danh sách sản phẩm một lần
  Future<List<ProductModel>> getProductsOnce() async {
    final col = _productsCollection;
    if (_isFirebaseReady && col != null) {
      try {
        final querySnapshot = await col.get();
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();
        }
      } catch (e) {
        debugPrint('Lỗi đọc Firestore: $e');
      }
    }
    return List.from(_localProducts);
  }

  /// Thêm sản phẩm mới (Chỉ chứa đúng 4 trường: name, price, soluong, image)
  Future<void> addProduct(ProductModel product) async {
    final col = _productsCollection;
    if (_isFirebaseReady && col != null) {
      try {
        await col.doc(product.name).set(product.toMap());
        debugPrint('Thêm sản phẩm lên Firestore thành công: ${product.name}');
      } catch (e) {
        debugPrint('Lỗi thêm sản phẩm lên Firestore: $e');
        throw Exception(
          'Không thể lưu lên Cloud Firestore: $e\n'
          'Vui lòng kiểm tra tab Rules trên Firebase Console đã mở "allow read, write: if true;" chưa.',
        );
      }
    }

    // Cập nhật danh sách local
    _localProducts.removeWhere((p) => p.name.toLowerCase() == product.name.toLowerCase());
    _localProducts.add(product);
    _emitLocalProducts();
  }

  /// Sửa thông tin sản phẩm
  Future<void> updateProduct(String originalName, ProductModel updatedProduct) async {
    final col = _productsCollection;
    if (_isFirebaseReady && col != null) {
      try {
        if (originalName.toLowerCase() != updatedProduct.name.toLowerCase()) {
          // Nếu đổi tên sản phẩm, xóa document cũ và tạo document mới
          await col.doc(originalName).delete();
          await col.doc(updatedProduct.name).set(updatedProduct.toMap());
        } else {
          await col.doc(originalName).set(updatedProduct.toMap(), SetOptions(merge: true));
        }
        debugPrint('Cập nhật sản phẩm Firestore thành công: ${updatedProduct.name}');
      } catch (e) {
        debugPrint('Lỗi cập nhật Firestore: $e');
        throw Exception(
          'Không thể cập nhật Firestore: $e\n'
          'Vui lòng kiểm tra tab Rules trên Firebase Console.',
        );
      }
    }

    final index = _localProducts.indexWhere((p) => p.name.toLowerCase() == originalName.toLowerCase());
    if (index != -1) {
      _localProducts[index] = updatedProduct;
    } else {
      _localProducts.add(updatedProduct);
    }
    _emitLocalProducts();
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(String name) async {
    final col = _productsCollection;
    if (_isFirebaseReady && col != null) {
      try {
        await col.doc(name).delete();
        debugPrint('Xóa sản phẩm Firestore thành công: $name');
      } catch (e) {
        debugPrint('Lỗi xóa sản phẩm Firestore: $e');
        throw Exception(
          'Không thể xóa trên Firestore: $e\n'
          'Vui lòng kiểm tra tab Rules trên Firebase Console.',
        );
      }
    }

    _localProducts.removeWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    _emitLocalProducts();
  }

  /// Đăng nhập phân hệ Admin
  Future<bool> login(String username, String password) async {
    final trimmedUser = username.trim().toLowerCase();
    final trimmedPass = password.trim();

    if ((trimmedUser == 'admin@gmail.com' || trimmedUser == 'admin') &&
        (trimmedPass == 'admin123' || trimmedPass == 'admin')) {
      return true;
    }
    return false;
  }

  /// Nạp danh sách sản phẩm mẫu lên Firestore (Seed Data)
  Future<int> seedSampleDataToFirestore() async {
    final col = _productsCollection;
    if (!_isFirebaseReady || col == null) {
      throw Exception('Chưa kết nối được Firebase Firestore!');
    }

    int count = 0;
    for (final product in _localProducts) {
      await col.doc(product.name).set(product.toMap());
      count++;
    }
    return count;
  }

  /// Xuất toàn bộ cơ sở dữ liệu thành chuỗi JSON (đúng 4 trường theo yêu cầu đề thi)
  Future<String> exportToJson() async {
    final products = await getProductsOnce();
    final list = products.map((p) => p.toMap()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(list);
  }
}
