import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';

/// Visual preview of the bill — matches the printed output layout.
class BillPreview extends StatelessWidget {
  final Bill bill;

  const BillPreview({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat('#,###', 'vi_VN');
    final timeFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shop name
          Text(
            bill.shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (bill.shopAddress != null && bill.shopAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                bill.shopAddress!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          if (bill.shopPhone != null && bill.shopPhone!.isNotEmpty)
            Text(
              'ĐT: ${bill.shopPhone!}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 4),
          // Title
          const Text(
            'HÓA ĐƠN BÁN HÀNG',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            'In lúc: ${timeFmt.format(bill.printTime)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const Divider(thickness: 1.5),
          // Info rows
          _infoRow('Nhân viên:', bill.staffName),
          _infoRow('Khách hàng:', bill.customerName),
          _infoRow('Bàn:', bill.tableNumber),
          const Divider(thickness: 1.5),
          // Table header
          _tableHeader(),
          const Divider(thickness: 0.5),
          // Items
          ...bill.items.map(
            (item) => _tableRow(
              item.displayName,
              '${item.quantity}',
              numFmt.format(item.total.toInt()),
            ),
          ),
          const Divider(thickness: 1.5),
          // Note
          if (bill.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Ghi chú: ${bill.note}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          // Adjustment
          if (bill.adjustment != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    bill.adjustNote.isNotEmpty
                        ? bill.adjustNote
                        : (bill.adjustment > 0 ? 'Phụ thu' : 'Giảm giá'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${bill.adjustment > 0 ? '+' : ''}${numFmt.format(bill.adjustment.toInt())}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          // Total
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Tổng:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  numFmt.format(bill.finalTotal.toInt()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1.5),
          const SizedBox(height: 8),
          Text(
            bill.footer,
            textAlign: TextAlign.center,
            style: const TextStyle(fontStyle: FontStyle.italic),
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
            'Mặt hàng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            'SL',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            'T. Tiền',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _tableRow(String name, String qty, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(name, style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 30,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
