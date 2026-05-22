// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_dao.dart';

// ignore_for_file: type=lint
mixin _$SalesDaoMixin on DatabaseAccessor<PosDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $UsersTable get users => attachedDatabase.users;
  $CashSessionsTable get cashSessions => attachedDatabase.cashSessions;
  $CustomersTable get customers => attachedDatabase.customers;
  $SalesTable get sales => attachedDatabase.sales;
  $CategoriesTable get categories => attachedDatabase.categories;
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $ProductsTable get products => attachedDatabase.products;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  $PaymentsTable get payments => attachedDatabase.payments;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  SalesDaoManager get managers => SalesDaoManager(this);
}

class SalesDaoManager {
  final _$SalesDaoMixin _db;
  SalesDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$CashSessionsTableTableManager get cashSessions =>
      $$CashSessionsTableTableManager(_db.attachedDatabase, _db.cashSessions);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
        _db.attachedDatabase,
        _db.stockMovements,
      );
}
