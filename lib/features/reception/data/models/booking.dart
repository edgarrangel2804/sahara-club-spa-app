class Booking {
  final String id;
  final String clientId;
  final String clientName;
  final String? therapistId;
  final String? therapistName;
  final String? serviceId;
  final String serviceName;
  final DateTime date;
  final String time;
  final int durationMin;
  final BookingStatus status;
  final String? cabin;
  final double price;
  final String? clientNotes;
  final String? sessionNotes;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.therapistId,
    this.therapistName,
    this.serviceId,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.durationMin,
    required this.status,
    this.cabin,
    required this.price,
    this.clientNotes,
    this.sessionNotes,
    required this.createdAt,
  });

  factory Booking.fromMap(Map<String, dynamic> m) {
    return Booking(
      id: m['id'] as String,
      clientId: m['client_id'] as String,
      clientName: (m['clients'] as Map?)?['full_name'] as String? ?? '—',
      therapistId: m['therapist_id'] as String?,
      therapistName: (m['therapists'] as Map?)?['full_name'] as String?,
      serviceId: m['service_id'] as String?,
      serviceName: (m['services'] as Map?)?['name'] as String? ?? m['service_name'] as String? ?? '—',
      date: DateTime.parse(m['booking_date'] as String),
      time: m['booking_time'] as String,
      durationMin: m['duration_min'] as int? ?? 60,
      status: BookingStatus.fromString(m['status'] as String?),
      cabin: m['cabin'] as String?,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      clientNotes: m['client_notes'] as String?,
      sessionNotes: m['session_notes'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

enum BookingStatus {
  scheduled,
  pending,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  awaitingPayment,
  paid,
  cancelled,
  rescheduled,
  noShow;

  static BookingStatus fromString(String? s) {
    return switch (s) {
      'pending'    => pending,
      'confirmed'  => confirmed,
      'checked_in' => checkedIn,
      'in_progress' => inProgress,
      'completed'  => completed,
      'awaiting_payment' => awaitingPayment,
      'paid'       => paid,
      'cancelled'  => cancelled,
      'rescheduled' => rescheduled,
      'no_show'    => noShow,
      _            => scheduled,
    };
  }

  String get value => switch (this) {
    scheduled  => 'scheduled',
    pending    => 'pending',
    confirmed  => 'confirmed',
    checkedIn  => 'checked_in',
    inProgress => 'in_progress',
    completed  => 'completed',
    awaitingPayment => 'awaiting_payment',
    paid       => 'paid',
    cancelled  => 'cancelled',
    rescheduled => 'rescheduled',
    noShow     => 'no_show',
  };

  String get label => switch (this) {
    scheduled  => 'Agendada',
    pending    => 'Pendiente',
    confirmed  => 'Confirmada',
    checkedIn  => 'Check-in',
    inProgress => 'En proceso',
    completed  => 'Completada',
    awaitingPayment => 'Pendiente de cobro',
    paid       => 'Pagada',
    cancelled  => 'Cancelada',
    rescheduled => 'Reagendada',
    noShow     => 'No asistió',
  };
}
