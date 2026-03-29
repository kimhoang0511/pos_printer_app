import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kitchen_ticket_model.dart';

/// Visual preview of the kitchen ticket — matches the printed output layout.
class KitchenTicketPreview extends StatelessWidget {
  final KitchenTicket ticket;

  const KitchenTicketPreview({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('dd/MM/yyyy\n(HH:mm)');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          const Text(
            'CHẾ BIẾN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            '(Bếp)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          // Order ID + datetime
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order:  #${ticket.orderId}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Ngày: ${timeFmt.format(ticket.orderTime)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _infoRow('Bàn:', ticket.tableNumber),
          if (ticket.staffName.isNotEmpty)
            _infoRow('Nhân viên:', ticket.staffName),
          const SizedBox(height: 6),
          const Divider(thickness: 1.5),
          // Table header
          _tableHeader(),
          const Divider(thickness: 0.5),
          // Items
          ...ticket.items.map((item) => _itemRow(item)),
          const Divider(thickness: 1.5),
          // Note
          if (ticket.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ghi chú: ${ticket.note}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 5,
          child: Text(
            'Món',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            'ĐVT',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            'SL',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(KitchenItem item) {
    final label = item.isTakeaway ? '${item.name} [Mang về]' : item.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 60,
            child: Text(
              item.sizeName ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
