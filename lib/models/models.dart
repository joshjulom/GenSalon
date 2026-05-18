class Client {
  final int? id;
  final String name;
  final String? phone;
  final String? photoPath;
  final DateTime createdAt;
  Client({this.id, required this.name, this.phone, this.photoPath, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
      };
  factory Client.fromMap(Map<String, Object?> m) => Client(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        photoPath: m['photo_path'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class Staff {
  final int? id;
  final String name;
  final String role;
  final String? phone;
  final String? photoPath;
  final bool active;
  Staff({this.id, required this.name, this.role = 'Stylist', this.phone, this.photoPath, this.active = true});
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
        'photo_path': photoPath,
        'active': active ? 1 : 0,
      };
  factory Staff.fromMap(Map<String, Object?> m) => Staff(
        id: m['id'] as int?,
        name: m['name'] as String,
        role: (m['role'] as String?) ?? 'Stylist',
        phone: m['phone'] as String?,
        photoPath: m['photo_path'] as String?,
        active: ((m['active'] as int?) ?? 1) == 1,
      );
}

class Service {
  final int? id;
  final String name;
  final double price;
  final int durationMin;
  final bool active;
  Service({this.id, required this.name, required this.price, this.durationMin = 30, this.active = true});
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'duration_min': durationMin,
        'active': active ? 1 : 0,
      };
  factory Service.fromMap(Map<String, Object?> m) => Service(
        id: m['id'] as int?,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        durationMin: (m['duration_min'] as int?) ?? 30,
        active: ((m['active'] as int?) ?? 1) == 1,
      );
}

class Item {
  final int? id;
  final String name;
  final String? sku;
  final double price;
  final int stock;
  final String? photoPath;
  final int lowStockThreshold;
  Item({this.id, required this.name, this.sku, required this.price, this.stock = 0, this.photoPath, this.lowStockThreshold = 5});
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'sku': sku,
        'price': price,
        'stock': stock,
        'photo_path': photoPath,
        'low_stock_threshold': lowStockThreshold,
      };
  factory Item.fromMap(Map<String, Object?> m) => Item(
        id: m['id'] as int?,
        name: m['name'] as String,
        sku: m['sku'] as String?,
        price: (m['price'] as num).toDouble(),
        stock: (m['stock'] as int?) ?? 0,
        photoPath: m['photo_path'] as String?,
        lowStockThreshold: (m['low_stock_threshold'] as int?) ?? 5,
      );
}

enum AppointmentStatus { scheduled, completed, cancelled, noShow }

AppointmentStatus statusFromString(String s) {
  return AppointmentStatus.values.firstWhere((e) => e.name == s,
      orElse: () => AppointmentStatus.scheduled);
}

class Appointment {
  final int? id;
  final int clientId;
  final int staffId;
  final int serviceId;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final String? notes;
  Appointment({
    this.id,
    required this.clientId,
    required this.staffId,
    required this.serviceId,
    required this.startAt,
    required this.endAt,
    this.status = AppointmentStatus.scheduled,
    this.notes,
  });
  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'staff_id': staffId,
        'service_id': serviceId,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'status': status.name,
        'notes': notes,
      };
  factory Appointment.fromMap(Map<String, Object?> m) => Appointment(
        id: m['id'] as int?,
        clientId: m['client_id'] as int,
        staffId: m['staff_id'] as int,
        serviceId: m['service_id'] as int,
        startAt: DateTime.parse(m['start_at'] as String),
        endAt: DateTime.parse(m['end_at'] as String),
        status: statusFromString((m['status'] as String?) ?? 'scheduled'),
        notes: m['notes'] as String?,
      );
}

class Sale {
  final int? id;
  final int? appointmentId;
  final int? staffId;
  final double total;
  final DateTime paidAt;
  final String paymentMethod;
  final String? notes;
  Sale({
    this.id,
    this.appointmentId,
    this.staffId,
    required this.total,
    DateTime? paidAt,
    this.paymentMethod = 'Cash',
    this.notes,
  }) : paidAt = paidAt ?? DateTime.now();
  Map<String, Object?> toMap() => {
        'id': id,
        'appointment_id': appointmentId,
        'staff_id': staffId,
        'total': total,
        'paid_at': paidAt.toIso8601String(),
        'payment_method': paymentMethod,
        'notes': notes,
      };
  factory Sale.fromMap(Map<String, Object?> m) => Sale(
        id: m['id'] as int?,
        appointmentId: m['appointment_id'] as int?,
        staffId: m['staff_id'] as int?,
        total: (m['total'] as num).toDouble(),
        paidAt: DateTime.tryParse(m['paid_at'] as String? ?? '') ?? DateTime.now(),
        paymentMethod: (m['payment_method'] as String?) ?? 'Cash',
        notes: m['notes'] as String?,
      );
}

class SaleLine {
  final int? id;
  final int? saleId;
  final String refType; // 'service' | 'item'
  final int refId;
  final String name;
  final int qty;
  final double unitPrice;
  double get lineTotal => qty * unitPrice;
  SaleLine({
    this.id,
    this.saleId,
    required this.refType,
    required this.refId,
    required this.name,
    this.qty = 1,
    required this.unitPrice,
  });
  Map<String, Object?> toMap() => {
        'id': id,
        'sale_id': saleId,
        'ref_type': refType,
        'ref_id': refId,
        'name': name,
        'qty': qty,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      };
  factory SaleLine.fromMap(Map<String, Object?> m) => SaleLine(
        id: m['id'] as int?,
        saleId: m['sale_id'] as int?,
        refType: m['ref_type'] as String,
        refId: m['ref_id'] as int,
        name: m['name'] as String,
        qty: (m['qty'] as int?) ?? 1,
        unitPrice: (m['unit_price'] as num).toDouble(),
      );
}
