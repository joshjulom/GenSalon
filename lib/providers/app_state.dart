import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

class AppState extends ChangeNotifier {
  final ClientRepo _clients = ClientRepo();
  final StaffRepo _staff = StaffRepo();
  final ServiceRepo _services = ServiceRepo();
  final ItemRepo _items = ItemRepo();
  final AppointmentRepo _appts = AppointmentRepo();
  final SaleRepo _sales = SaleRepo();

  // ── Counts for dashboard ──
  int clientCount = 0;
  int staffCount = 0;
  int todayAppointments = 0;
  double todaySales = 0;
  List<MapEntry<DateTime, double>> weekSales = [];

  // ── Lists ──
  List<Client> clients = [];
  List<Staff> staffList = [];
  List<Service> services = [];
  List<Item> items = [];
  List<Appointment> appointments = [];
  List<Appointment> historyList = [];

  bool loading = false;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    await Future.wait([
      _loadDashboard(),
      _loadClients(),
      _loadStaff(),
      _loadServices(),
      _loadItems(),
      _loadAppointments(),
    ]);
    loading = false;
    notifyListeners();
  }

  Future<void> _loadDashboard() async {
    clientCount = await _clients.count();
    staffCount = await _staff.count();
    todayAppointments = await _appts.todayCount();
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    todaySales = await _sales.totalInRange(dayStart, dayStart.add(const Duration(days: 1)));
    weekSales = await _sales.last7Days();
  }

  Future<void> refreshDashboard() async {
    await _loadDashboard();
    notifyListeners();
  }

  Future<void> _loadClients() async => clients = await _clients.all();
  Future<void> _loadStaff() async => staffList = await _staff.all();
  Future<void> _loadServices() async => services = await _services.all();
  Future<void> _loadItems() async => items = await _items.all();
  Future<void> _loadAppointments() async {
    appointments = await _appts.upcoming();
    historyList = await _appts.history();
  }

  // ── Client CRUD ──
  Future<void> addClient(Client c) async {
    await _clients.insert(c);
    await Future.wait([_loadClients(), _loadDashboard()]);
    notifyListeners();
  }

  Future<void> updateClient(Client c) async {
    await _clients.update(c);
    await _loadClients();
    notifyListeners();
  }

  Future<void> deleteClient(int id) async {
    await _clients.delete(id);
    await Future.wait([_loadClients(), _loadDashboard()]);
    notifyListeners();
  }

  // ── Staff CRUD ──
  Future<void> addStaff(Staff s) async {
    await _staff.insert(s);
    await Future.wait([_loadStaff(), _loadDashboard()]);
    notifyListeners();
  }

  Future<void> updateStaff(Staff s) async {
    await _staff.update(s);
    await _loadStaff();
    notifyListeners();
  }

  Future<void> deleteStaff(int id) async {
    await _staff.delete(id);
    await Future.wait([_loadStaff(), _loadDashboard()]);
    notifyListeners();
  }

  // ── Service CRUD ──
  Future<void> addService(Service s) async {
    await _services.insert(s);
    await _loadServices();
    notifyListeners();
  }

  Future<void> updateService(Service s) async {
    await _services.update(s);
    await _loadServices();
    notifyListeners();
  }

  Future<void> deleteService(int id) async {
    await _services.delete(id);
    await _loadServices();
    notifyListeners();
  }

  // ── Item CRUD ──
  Future<void> addItem(Item i) async {
    await _items.insert(i);
    await _loadItems();
    notifyListeners();
  }

  Future<void> updateItem(Item i) async {
    await _items.update(i);
    await _loadItems();
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _items.delete(id);
    await _loadItems();
    notifyListeners();
  }

  // ── Appointment CRUD ──
  Future<int> addAppointment(Appointment a) async {
    final id = await _appts.insert(a);
    await Future.wait([_loadAppointments(), _loadDashboard()]);
    notifyListeners();
    return id;
  }

  Future<void> updateAppointment(Appointment a) async {
    await _appts.update(a);
    await Future.wait([_loadAppointments(), _loadDashboard()]);
    notifyListeners();
  }

  Future<void> deleteAppointment(int id) async {
    await _appts.delete(id);
    await Future.wait([_loadAppointments(), _loadDashboard()]);
    notifyListeners();
  }

  // ── Sales ──
  Future<void> recordSale(Sale sale, List<SaleLine> lines) async {
    await _sales.createWithLines(sale, lines);
    await Future.wait([_loadItems(), _loadDashboard()]);
    notifyListeners();
  }

  Future<List<Sale>> salesInRange(DateTime start, DateTime end) =>
      _sales.inRange(start, end);

  Future<List<SaleLine>> linesFor(int saleId) => _sales.linesFor(saleId);

  Future<List<MapEntry<DateTime, double>>> last7Days() => _sales.last7Days();
}
