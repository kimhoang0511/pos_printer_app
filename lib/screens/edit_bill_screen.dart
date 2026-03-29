import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bill_model.dart';
import '../services/app_state.dart';

class EditBillScreen extends StatefulWidget {
  const EditBillScreen({super.key});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  late TextEditingController _shopCtrl;
  late TextEditingController _staffCtrl;
  late TextEditingController _customerCtrl;
  late TextEditingController _tableCtrl;
  late TextEditingController _footerCtrl;
  late List<_ItemRow> _itemRows;

  @override
  void initState() {
    super.initState();
    final bill = context.read<AppState>().bill;
    _shopCtrl = TextEditingController(text: bill.shopName);
    _staffCtrl = TextEditingController(text: bill.staffName);
    _customerCtrl = TextEditingController(text: bill.customerName);
    _tableCtrl = TextEditingController(text: bill.tableNumber);
    _footerCtrl = TextEditingController(text: bill.footer);
    _itemRows = bill.items
        .map((i) => _ItemRow(
              name: i.displayName,
              qty: i.quantity.toString(),
              price: i.unitPrice.toInt().toString(),
            ))
        .toList();
  }

  @override
  void dispose() {
    _shopCtrl.dispose();
    _staffCtrl.dispose();
    _customerCtrl.dispose();
    _tableCtrl.dispose();
    _footerCtrl.dispose();
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _itemRows.add(_ItemRow()));
  }

  void _removeItem(int index) {
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
    });
  }

  void _save() {
    final items = _itemRows
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .map((r) => BillItem(
              name: r.nameCtrl.text.trim(),
              quantity: int.tryParse(r.qtyCtrl.text) ?? 1,
              unitPrice: (double.tryParse(r.priceCtrl.text) ?? 0) * 1000,
            ))
        .toList();

    final baseTotal =
        items.fold<double>(0, (sum, i) => sum + i.total);
    final bill = Bill(
      shopName: _shopCtrl.text.trim(),
      staffName: _staffCtrl.text.trim(),
      customerName: _customerCtrl.text.trim(),
      tableNumber: _tableCtrl.text.trim(),
      printTime: DateTime.now(),
      items: items,
      baseTotal: baseTotal,
      finalTotal: baseTotal,
      footer: _footerCtrl.text.trim(),
    );

    context.read<AppState>().updateBill(bill);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hóa đơn'),
        backgroundColor: const Color(0xFF6B3A2A),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('LƯU', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _field(_shopCtrl, 'Tên quán'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(_staffCtrl, 'Nhân viên')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_customerCtrl, 'Khách hàng')),
                  ]),
                  const SizedBox(height: 8),
                  _field(_tableCtrl, 'Bàn số'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Danh sách món',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm'),
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                  // Column labels
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 5,
                            child: Text('Tên món',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey))),
                        SizedBox(
                            width: 40,
                            child: Text('SL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey))),
                        SizedBox(width: 4),
                        SizedBox(
                            width: 70,
                            child: Text('Giá (nghìn)',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey))),
                        SizedBox(width: 32),
                      ],
                    ),
                  ),
                  ...List.generate(
                    _itemRows.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: _itemRows[i].nameCtrl,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 36,
                            child: TextField(
                              controller: _itemRows[i].qtyCtrl,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: _itemRows[i].priceCtrl,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => _removeItem(i),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Footer
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lời chào',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _field(_footerCtrl, 'Nội dung dưới cùng'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B3A2A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('LƯU HÓA ĐƠN',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _ItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _ItemRow({String name = '', String qty = '1', String price = '0'})
      : nameCtrl = TextEditingController(text: name),
        qtyCtrl = TextEditingController(text: qty),
        priceCtrl = TextEditingController(text: price);

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}
