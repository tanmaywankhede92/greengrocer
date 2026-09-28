import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/models/draft_bill.dart';
import 'package:greengrocer/widgets/bill_item_row.dart';
import 'package:greengrocer/screens/draft_bills_screen.dart';
import 'package:greengrocer/screens/new_bill/new_bill_screen.dart';
import 'package:greengrocer/providers/bill_provider.dart';

void main() {
  group('DraftBill Model Tests', () {
    test('DraftBill.fromJson parses all fields correctly', () {
      final json = {
        '_id': 'draft_mongo_123',
        'draftId': 'DFT-2609-0001',
        'customerId': {
          '_id': 'cust_123',
          'name': 'Ramesh Kumar',
          'mobile': '9876543210',
          'address': 'Main Market',
        },
        'customerName': 'Ramesh Kumar',
        'customerMobile': '9876543210',
        'customerAddress': 'Main Market',
        'billDate': '2026-09-29T10:00:00.000Z',
        'items': [
          {
            'productId': 'prod_1',
            'productName': 'Tomato',
            'productNameHindi': 'टमाटर',
            'unit': 'kg',
            'quantity': 10,
            'defaultRate': 40,
            'appliedRate': 42,
            'amount': 420,
          },
          {
            'productId': 'prod_2',
            'productName': 'Potato',
            'productNameHindi': 'आलू',
            'unit': 'kg',
            'quantity': 25,
            'defaultRate': 20,
            'appliedRate': 20,
            'amount': 500,
          },
        ],
        'subtotal': 920,
        'deliveryCharge': 50,
        'discount': 20,
        'total': 950,
        'notes': 'Deliver before 2 PM',
        'status': 'draft',
        'createdAt': '2026-09-29T10:00:00.000Z',
        'updatedAt': '2026-09-29T10:15:00.000Z',
      };

      final draft = DraftBill.fromJson(json);

      expect(draft.id, 'draft_mongo_123');
      expect(draft.draftId, 'DFT-2609-0001');
      expect(draft.customerId, 'cust_123');
      expect(draft.customerName, 'Ramesh Kumar');
      expect(draft.customerMobile, '9876543210');
      expect(draft.customerAddress, 'Main Market');
      expect(draft.customer, isNotNull);
      expect(draft.customer!.name, 'Ramesh Kumar');
      expect(draft.items.length, 2);
      expect(draft.items[0].productName, 'Tomato');
      expect(draft.items[0].quantity, 10);
      expect(draft.items[0].appliedRate, 42);
      expect(draft.items[0].amount, 420);
      expect(draft.items[1].productName, 'Potato');
      expect(draft.items[1].quantity, 25);
      expect(draft.subtotal, 920);
      expect(draft.deliveryCharge, 50);
      expect(draft.discount, 20);
      expect(draft.total, 950);
      expect(draft.notes, 'Deliver before 2 PM');
      expect(draft.status, 'draft');
    });

    test('DraftBill.toCustomer resolves customer correctly', () {
      final draftWithObj = DraftBill(
        id: '1',
        draftId: 'DFT-2609-0001',
        customerId: 'cust_abc',
        customerName: 'Suresh',
        customerMobile: '9123456780',
        billDate: DateTime.now(),
      );
      final cust = draftWithObj.toCustomer();
      expect(cust, isNotNull);
      expect(cust!.id, 'cust_abc');
      expect(cust.name, 'Suresh');
      expect(cust.mobile, '9123456780');

      final emptyDraft = DraftBill(
        id: '2',
        draftId: 'DFT-2609-0002',
        billDate: DateTime.now(),
      );
      expect(emptyDraft.toCustomer(), isNull);
    });

    test('LineItem.fromJson and toJson work symmetrically', () {
      final original = LineItem(
        productId: 'prod_99',
        productName: 'Onion',
        productNameHindi: 'प्याज',
        unit: 'kg',
        quantity: 15,
        defaultRate: 30,
        appliedRate: 35,
      );

      final json = original.toJson();
      final restored = LineItem.fromJson(json);

      expect(restored.productId, 'prod_99');
      expect(restored.productName, 'Onion');
      expect(restored.productNameHindi, 'प्याज');
      expect(restored.unit, 'kg');
      expect(restored.quantity, 15);
      expect(restored.defaultRate, 30);
      expect(restored.appliedRate, 35);
      expect(restored.amount, 525);
    });
  });

  group('DraftBillsScreen Widget Tests', () {
    testWidgets('Renders empty state when no drafts are present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draftListProvider.overrideWith((ref, search) async => []),
          ],
          child: const MaterialApp(
            home: DraftBillsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Draft Bills'), findsNWidgets(2));
      expect(find.text('No Saved Drafts'), findsOneWidget);
    });

    testWidgets('Renders draft cards when drafts exist', (tester) async {
      final sampleDraft = DraftBill(
        id: 'draft_1',
        draftId: 'DFT-2609-0001',
        customerName: 'Ramesh Patel',
        customerMobile: '9898989898',
        billDate: DateTime.now(),
        items: [
          LineItem(productName: 'Apple', quantity: 5, appliedRate: 120),
          LineItem(productName: 'Banana', quantity: 2, unit: 'dozen', appliedRate: 60),
        ],
        subtotal: 720,
        total: 720,
        status: 'draft',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draftListProvider.overrideWith((ref, search) async => [sampleDraft]),
          ],
          child: const MaterialApp(
            home: DraftBillsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DFT-2609-0001'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('Continue Draft'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });
  });

  group('NewBillScreen Draft Restoration & Intercept Tests', () {
    testWidgets('Populates items and customer when initialDraft is passed', (tester) async {
      final sampleDraft = DraftBill(
        id: 'draft_10',
        draftId: 'DFT-2609-0010',
        customerId: 'cust_10',
        customerName: 'Kailash Veggies',
        customerMobile: '9988776655',
        billDate: DateTime.now(),
        items: [
          LineItem(productName: 'Cauliflower', quantity: 4, appliedRate: 50),
        ],
        deliveryCharge: 30,
        subtotal: 200,
        total: 230,
        status: 'draft',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NewBillScreen(initialDraft: sampleDraft),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check draft ID badge in AppBar
      expect(find.text('Draft: DFT-2609-0010'), findsOneWidget);
      // Check customer section shows restored customer name
      expect(find.text('Kailash Veggies'), findsOneWidget);
      // Check item row is rendered with cauliflower
      expect(find.text('Cauliflower'), findsOneWidget);
      // Check summary card has delivery charge
      expect(find.text('₹230'), findsWidgets);
    });
  });
}
