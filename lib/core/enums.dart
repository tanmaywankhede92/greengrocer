enum ProductUnit {
  kg('kg'),
  pcs('pcs'),
  bundle('bundle'),
  box('box'),
  dozen('dozen'),
  quintal('quintal'),
  bag('bag'),
  crate('crate');

  final String value;
  const ProductUnit(this.value);

  static ProductUnit fromString(String s) =>
      ProductUnit.values.firstWhere((e) => e.value == s, orElse: () => kg);
}

enum PaymentMode {
  cash('cash'),
  upi('upi'),
  bankTransfer('bank_transfer'),
  cheque('cheque');

  final String value;
  const PaymentMode(this.value);

  static PaymentMode fromString(String s) =>
      PaymentMode.values.firstWhere((e) => e.value == s, orElse: () => cash);

  String get displayName {
    switch (this) {
      case cash: return 'Cash';
      case upi: return 'UPI';
      case bankTransfer: return 'Bank Transfer';
      case cheque: return 'Cheque';
    }
  }
}

enum BillStatus {
  active('active'),
  cancelled('cancelled');

  final String value;
  const BillStatus(this.value);

  static BillStatus fromString(String s) =>
      BillStatus.values.firstWhere((e) => e.value == s, orElse: () => active);
}

enum LedgerEntryType {
  openingBalance('opening_balance'),
  bill('bill'),
  payment('payment'),
  adjustment('adjustment');

  final String value;
  const LedgerEntryType(this.value);

  static LedgerEntryType fromString(String s) =>
      LedgerEntryType.values.firstWhere((e) => e.value == s, orElse: () => bill);
}

enum UserRole {
  admin('admin'),
  staff('staff');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String s) =>
      UserRole.values.firstWhere((e) => e.value == s, orElse: () => staff);
}
