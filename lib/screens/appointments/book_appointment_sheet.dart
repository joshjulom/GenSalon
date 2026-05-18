import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class BookAppointmentSheet extends StatefulWidget {
  const BookAppointmentSheet({super.key});
  @override
  State<BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<BookAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  Client? _client;
  Staff? _staff;
  Service? _service;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  // Quick-add client
  final _newClientCtrl = TextEditingController();
  final _newClientPhoneCtrl = TextEditingController();
  bool _addingClient = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _newClientCtrl.dispose();
    _newClientPhoneCtrl.dispose();
    super.dispose();
  }

  DateTime get _startAt {
    return DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);
  }

  DateTime get _endAt {
    final dur = _service?.durationMin ?? 30;
    return _startAt.add(Duration(minutes: dur));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(c)
              .colorScheme
              .copyWith(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(c)
              .colorScheme
              .copyWith(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_client == null || _staff == null || _service == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select client, staff and service.')));
      return;
    }
    setState(() => _saving = true);
    final appt = Appointment(
      clientId: _client!.id!,
      staffId: _staff!.id!,
      serviceId: _service!.id!,
      startAt: _startAt,
      endAt: _endAt,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final id = await context.read<AppState>().addAppointment(appt);
    await NotificationService.instance.scheduleAppointmentReminder(
      appointmentId: id,
      clientName: _client!.name,
      serviceName: _service!.name,
      startAt: _startAt,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _quickAddClient() async {
    if (_newClientCtrl.text.trim().isEmpty) return;
    final c = Client(
      name: _newClientCtrl.text.trim(),
      phone: _newClientPhoneCtrl.text.trim().isEmpty
          ? null
          : _newClientPhoneCtrl.text.trim(),
    );
    await context.read<AppState>().addClient(c);
    final state = context.read<AppState>();
    setState(() {
      _client = state.clients.lastWhere((x) => x.name == c.name,
          orElse: () => state.clients.last);
      _addingClient = false;
      _newClientCtrl.clear();
      _newClientPhoneCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                    child: Text('Book Appointment',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              // Client picker
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<Client>(
                    value: _client,
                    decoration: const InputDecoration(labelText: 'Client'),
                    dropdownColor: AppColors.surfaceAlt,
                    items: state.clients
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _client = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined,
                      color: AppColors.purple),
                  tooltip: 'Quick-add client',
                  onPressed: () =>
                      setState(() => _addingClient = !_addingClient),
                ),
              ]),

              if (_addingClient) ...[
                const SizedBox(height: 8),
                TextFormField(
                    controller: _newClientCtrl,
                    decoration:
                        const InputDecoration(labelText: 'New Client Name')),
                const SizedBox(height: 8),
                TextFormField(
                    controller: _newClientPhoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone (optional)'),
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: _quickAddClient,
                    child: const Text('Add Client')),
              ],
              const SizedBox(height: 12),

              // Staff picker
              DropdownButtonFormField<Staff>(
                value: _staff,
                decoration: const InputDecoration(labelText: 'Staff'),
                dropdownColor: AppColors.surfaceAlt,
                items: state.staffList
                    .where((s) => s.active)
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => setState(() => _staff = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Service picker
              DropdownButtonFormField<Service>(
                value: _service,
                decoration: const InputDecoration(labelText: 'Service'),
                dropdownColor: AppColors.surfaceAlt,
                items: state.services
                    .where((s) => s.active)
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.name} (${s.durationMin} min)')))
                    .toList(),
                onChanged: (v) => setState(() => _service = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Date & time
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(
                          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text(_time.format(context)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)', alignLabelWithHint: true),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Book Appointment'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
