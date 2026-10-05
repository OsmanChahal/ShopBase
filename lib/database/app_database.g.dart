// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPriceUsdMeta = const VerificationMeta(
    'costPriceUsd',
  );
  @override
  late final GeneratedColumn<double> costPriceUsd = GeneratedColumn<double>(
    'cost_price_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellPriceUsdMeta = const VerificationMeta(
    'sellPriceUsd',
  );
  @override
  late final GeneratedColumn<double> sellPriceUsd = GeneratedColumn<double>(
    'sell_price_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowStockThresholdMeta = const VerificationMeta(
    'lowStockThreshold',
  );
  @override
  late final GeneratedColumn<int> lowStockThreshold = GeneratedColumn<int>(
    'low_stock_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    sku,
    category,
    costPriceUsd,
    sellPriceUsd,
    quantity,
    lowStockThreshold,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('cost_price_usd')) {
      context.handle(
        _costPriceUsdMeta,
        costPriceUsd.isAcceptableOrUnknown(
          data['cost_price_usd']!,
          _costPriceUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costPriceUsdMeta);
    }
    if (data.containsKey('sell_price_usd')) {
      context.handle(
        _sellPriceUsdMeta,
        sellPriceUsd.isAcceptableOrUnknown(
          data['sell_price_usd']!,
          _sellPriceUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellPriceUsdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
        _lowStockThresholdMeta,
        lowStockThreshold.isAcceptableOrUnknown(
          data['low_stock_threshold']!,
          _lowStockThresholdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      costPriceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price_usd'],
      )!,
      sellPriceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price_usd'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      lowStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_threshold'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final String id;
  final String businessId;
  final String name;
  final String? sku;
  final String? category;
  final double costPriceUsd;
  final double sellPriceUsd;
  final int quantity;
  final int lowStockThreshold;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;
  const LocalProduct({
    required this.id,
    required this.businessId,
    required this.name,
    this.sku,
    this.category,
    required this.costPriceUsd,
    required this.sellPriceUsd,
    required this.quantity,
    required this.lowStockThreshold,
    this.updatedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['cost_price_usd'] = Variable<double>(costPriceUsd);
    map['sell_price_usd'] = Variable<double>(sellPriceUsd);
    map['quantity'] = Variable<int>(quantity);
    map['low_stock_threshold'] = Variable<int>(lowStockThreshold);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      costPriceUsd: Value(costPriceUsd),
      sellPriceUsd: Value(sellPriceUsd),
      quantity: Value(quantity),
      lowStockThreshold: Value(lowStockThreshold),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LocalProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      category: serializer.fromJson<String?>(json['category']),
      costPriceUsd: serializer.fromJson<double>(json['costPriceUsd']),
      sellPriceUsd: serializer.fromJson<double>(json['sellPriceUsd']),
      quantity: serializer.fromJson<int>(json['quantity']),
      lowStockThreshold: serializer.fromJson<int>(json['lowStockThreshold']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'category': serializer.toJson<String?>(category),
      'costPriceUsd': serializer.toJson<double>(costPriceUsd),
      'sellPriceUsd': serializer.toJson<double>(sellPriceUsd),
      'quantity': serializer.toJson<int>(quantity),
      'lowStockThreshold': serializer.toJson<int>(lowStockThreshold),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  LocalProduct copyWith({
    String? id,
    String? businessId,
    String? name,
    Value<String?> sku = const Value.absent(),
    Value<String?> category = const Value.absent(),
    double? costPriceUsd,
    double? sellPriceUsd,
    int? quantity,
    int? lowStockThreshold,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => LocalProduct(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    category: category.present ? category.value : this.category,
    costPriceUsd: costPriceUsd ?? this.costPriceUsd,
    sellPriceUsd: sellPriceUsd ?? this.sellPriceUsd,
    quantity: quantity ?? this.quantity,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      category: data.category.present ? data.category.value : this.category,
      costPriceUsd: data.costPriceUsd.present
          ? data.costPriceUsd.value
          : this.costPriceUsd,
      sellPriceUsd: data.sellPriceUsd.present
          ? data.sellPriceUsd.value
          : this.sellPriceUsd,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('category: $category, ')
          ..write('costPriceUsd: $costPriceUsd, ')
          ..write('sellPriceUsd: $sellPriceUsd, ')
          ..write('quantity: $quantity, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    sku,
    category,
    costPriceUsd,
    sellPriceUsd,
    quantity,
    lowStockThreshold,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.category == this.category &&
          other.costPriceUsd == this.costPriceUsd &&
          other.sellPriceUsd == this.sellPriceUsd &&
          other.quantity == this.quantity &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> category;
  final Value<double> costPriceUsd;
  final Value<double> sellPriceUsd;
  final Value<int> quantity;
  final Value<int> lowStockThreshold;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.category = const Value.absent(),
    this.costPriceUsd = const Value.absent(),
    this.sellPriceUsd = const Value.absent(),
    this.quantity = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.sku = const Value.absent(),
    this.category = const Value.absent(),
    required double costPriceUsd,
    required double sellPriceUsd,
    required int quantity,
    this.lowStockThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       costPriceUsd = Value(costPriceUsd),
       sellPriceUsd = Value(sellPriceUsd),
       quantity = Value(quantity);
  static Insertable<LocalProduct> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? category,
    Expression<double>? costPriceUsd,
    Expression<double>? sellPriceUsd,
    Expression<int>? quantity,
    Expression<int>? lowStockThreshold,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (category != null) 'category': category,
      if (costPriceUsd != null) 'cost_price_usd': costPriceUsd,
      if (sellPriceUsd != null) 'sell_price_usd': sellPriceUsd,
      if (quantity != null) 'quantity': quantity,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? sku,
    Value<String?>? category,
    Value<double>? costPriceUsd,
    Value<double>? sellPriceUsd,
    Value<int>? quantity,
    Value<int>? lowStockThreshold,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      costPriceUsd: costPriceUsd ?? this.costPriceUsd,
      sellPriceUsd: sellPriceUsd ?? this.sellPriceUsd,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (costPriceUsd.present) {
      map['cost_price_usd'] = Variable<double>(costPriceUsd.value);
    }
    if (sellPriceUsd.present) {
      map['sell_price_usd'] = Variable<double>(sellPriceUsd.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<int>(lowStockThreshold.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('category: $category, ')
          ..write('costPriceUsd: $costPriceUsd, ')
          ..write('sellPriceUsd: $sellPriceUsd, ')
          ..write('quantity: $quantity, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCustomersTable extends LocalCustomers
    with TableInfo<$LocalCustomersTable, LocalCustomer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    phone,
    createdAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCustomer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCustomer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCustomer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $LocalCustomersTable createAlias(String alias) {
    return $LocalCustomersTable(attachedDatabase, alias);
  }
}

class LocalCustomer extends DataClass implements Insertable<LocalCustomer> {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;
  const LocalCustomer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    required this.createdAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  LocalCustomersCompanion toCompanion(bool nullToAbsent) {
    return LocalCustomersCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      createdAt: Value(createdAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LocalCustomer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCustomer(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  LocalCustomer copyWith({
    String? id,
    String? businessId,
    String? name,
    Value<String?> phone = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => LocalCustomer(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    createdAt: createdAt ?? this.createdAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LocalCustomer copyWithCompanion(LocalCustomersCompanion data) {
    return LocalCustomer(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomer(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, businessId, name, phone, createdAt, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCustomer &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.createdAt == this.createdAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LocalCustomersCompanion extends UpdateCompanion<LocalCustomer> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const LocalCustomersCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCustomersCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.phone = const Value.absent(),
    required DateTime createdAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<LocalCustomer> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? phone,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return LocalCustomersCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomersCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSalesTable extends LocalSales
    with TableInfo<$LocalSalesTable, LocalSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalUsdMeta = const VerificationMeta(
    'totalUsd',
  );
  @override
  late final GeneratedColumn<double> totalUsd = GeneratedColumn<double>(
    'total_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalLbpMeta = const VerificationMeta(
    'totalLbp',
  );
  @override
  late final GeneratedColumn<double> totalLbp = GeneratedColumn<double>(
    'total_lbp',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exchangeRateUsedMeta = const VerificationMeta(
    'exchangeRateUsed',
  );
  @override
  late final GeneratedColumn<double> exchangeRateUsed = GeneratedColumn<double>(
    'exchange_rate_used',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentTypeMeta = const VerificationMeta(
    'paymentType',
  );
  @override
  late final GeneratedColumn<String> paymentType = GeneratedColumn<String>(
    'payment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    customerId,
    totalUsd,
    totalLbp,
    exchangeRateUsed,
    paymentType,
    createdAt,
    synced,
    inventoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('total_usd')) {
      context.handle(
        _totalUsdMeta,
        totalUsd.isAcceptableOrUnknown(data['total_usd']!, _totalUsdMeta),
      );
    } else if (isInserting) {
      context.missing(_totalUsdMeta);
    }
    if (data.containsKey('total_lbp')) {
      context.handle(
        _totalLbpMeta,
        totalLbp.isAcceptableOrUnknown(data['total_lbp']!, _totalLbpMeta),
      );
    } else if (isInserting) {
      context.missing(_totalLbpMeta);
    }
    if (data.containsKey('exchange_rate_used')) {
      context.handle(
        _exchangeRateUsedMeta,
        exchangeRateUsed.isAcceptableOrUnknown(
          data['exchange_rate_used']!,
          _exchangeRateUsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exchangeRateUsedMeta);
    }
    if (data.containsKey('payment_type')) {
      context.handle(
        _paymentTypeMeta,
        paymentType.isAcceptableOrUnknown(
          data['payment_type']!,
          _paymentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      totalUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_usd'],
      )!,
      totalLbp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_lbp'],
      )!,
      exchangeRateUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate_used'],
      )!,
      paymentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      ),
    );
  }

  @override
  $LocalSalesTable createAlias(String alias) {
    return $LocalSalesTable(attachedDatabase, alias);
  }
}

class LocalSale extends DataClass implements Insertable<LocalSale> {
  final String id;
  final String businessId;
  final String? customerId;
  final double totalUsd;
  final double totalLbp;
  final double exchangeRateUsed;
  final String paymentType;
  final DateTime createdAt;
  final bool synced;
  final String? inventoryId;
  const LocalSale({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.totalUsd,
    required this.totalLbp,
    required this.exchangeRateUsed,
    required this.paymentType,
    required this.createdAt,
    required this.synced,
    this.inventoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['total_usd'] = Variable<double>(totalUsd);
    map['total_lbp'] = Variable<double>(totalLbp);
    map['exchange_rate_used'] = Variable<double>(exchangeRateUsed);
    map['payment_type'] = Variable<String>(paymentType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || inventoryId != null) {
      map['inventory_id'] = Variable<String>(inventoryId);
    }
    return map;
  }

  LocalSalesCompanion toCompanion(bool nullToAbsent) {
    return LocalSalesCompanion(
      id: Value(id),
      businessId: Value(businessId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      totalUsd: Value(totalUsd),
      totalLbp: Value(totalLbp),
      exchangeRateUsed: Value(exchangeRateUsed),
      paymentType: Value(paymentType),
      createdAt: Value(createdAt),
      synced: Value(synced),
      inventoryId: inventoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(inventoryId),
    );
  }

  factory LocalSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSale(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      totalUsd: serializer.fromJson<double>(json['totalUsd']),
      totalLbp: serializer.fromJson<double>(json['totalLbp']),
      exchangeRateUsed: serializer.fromJson<double>(json['exchangeRateUsed']),
      paymentType: serializer.fromJson<String>(json['paymentType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      inventoryId: serializer.fromJson<String?>(json['inventoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'customerId': serializer.toJson<String?>(customerId),
      'totalUsd': serializer.toJson<double>(totalUsd),
      'totalLbp': serializer.toJson<double>(totalLbp),
      'exchangeRateUsed': serializer.toJson<double>(exchangeRateUsed),
      'paymentType': serializer.toJson<String>(paymentType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
      'inventoryId': serializer.toJson<String?>(inventoryId),
    };
  }

  LocalSale copyWith({
    String? id,
    String? businessId,
    Value<String?> customerId = const Value.absent(),
    double? totalUsd,
    double? totalLbp,
    double? exchangeRateUsed,
    String? paymentType,
    DateTime? createdAt,
    bool? synced,
    Value<String?> inventoryId = const Value.absent(),
  }) => LocalSale(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    customerId: customerId.present ? customerId.value : this.customerId,
    totalUsd: totalUsd ?? this.totalUsd,
    totalLbp: totalLbp ?? this.totalLbp,
    exchangeRateUsed: exchangeRateUsed ?? this.exchangeRateUsed,
    paymentType: paymentType ?? this.paymentType,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
    inventoryId: inventoryId.present ? inventoryId.value : this.inventoryId,
  );
  LocalSale copyWithCompanion(LocalSalesCompanion data) {
    return LocalSale(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      totalUsd: data.totalUsd.present ? data.totalUsd.value : this.totalUsd,
      totalLbp: data.totalLbp.present ? data.totalLbp.value : this.totalLbp,
      exchangeRateUsed: data.exchangeRateUsed.present
          ? data.exchangeRateUsed.value
          : this.exchangeRateUsed,
      paymentType: data.paymentType.present
          ? data.paymentType.value
          : this.paymentType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSale(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerId: $customerId, ')
          ..write('totalUsd: $totalUsd, ')
          ..write('totalLbp: $totalLbp, ')
          ..write('exchangeRateUsed: $exchangeRateUsed, ')
          ..write('paymentType: $paymentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('inventoryId: $inventoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    customerId,
    totalUsd,
    totalLbp,
    exchangeRateUsed,
    paymentType,
    createdAt,
    synced,
    inventoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSale &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.customerId == this.customerId &&
          other.totalUsd == this.totalUsd &&
          other.totalLbp == this.totalLbp &&
          other.exchangeRateUsed == this.exchangeRateUsed &&
          other.paymentType == this.paymentType &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced &&
          other.inventoryId == this.inventoryId);
}

class LocalSalesCompanion extends UpdateCompanion<LocalSale> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String?> customerId;
  final Value<double> totalUsd;
  final Value<double> totalLbp;
  final Value<double> exchangeRateUsed;
  final Value<String> paymentType;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<String?> inventoryId;
  final Value<int> rowid;
  const LocalSalesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.totalUsd = const Value.absent(),
    this.totalLbp = const Value.absent(),
    this.exchangeRateUsed = const Value.absent(),
    this.paymentType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSalesCompanion.insert({
    required String id,
    required String businessId,
    this.customerId = const Value.absent(),
    required double totalUsd,
    required double totalLbp,
    required double exchangeRateUsed,
    required String paymentType,
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       totalUsd = Value(totalUsd),
       totalLbp = Value(totalLbp),
       exchangeRateUsed = Value(exchangeRateUsed),
       paymentType = Value(paymentType),
       createdAt = Value(createdAt);
  static Insertable<LocalSale> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? customerId,
    Expression<double>? totalUsd,
    Expression<double>? totalLbp,
    Expression<double>? exchangeRateUsed,
    Expression<String>? paymentType,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<String>? inventoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (customerId != null) 'customer_id': customerId,
      if (totalUsd != null) 'total_usd': totalUsd,
      if (totalLbp != null) 'total_lbp': totalLbp,
      if (exchangeRateUsed != null) 'exchange_rate_used': exchangeRateUsed,
      if (paymentType != null) 'payment_type': paymentType,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSalesCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String?>? customerId,
    Value<double>? totalUsd,
    Value<double>? totalLbp,
    Value<double>? exchangeRateUsed,
    Value<String>? paymentType,
    Value<DateTime>? createdAt,
    Value<bool>? synced,
    Value<String?>? inventoryId,
    Value<int>? rowid,
  }) {
    return LocalSalesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      totalUsd: totalUsd ?? this.totalUsd,
      totalLbp: totalLbp ?? this.totalLbp,
      exchangeRateUsed: exchangeRateUsed ?? this.exchangeRateUsed,
      paymentType: paymentType ?? this.paymentType,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      inventoryId: inventoryId ?? this.inventoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (totalUsd.present) {
      map['total_usd'] = Variable<double>(totalUsd.value);
    }
    if (totalLbp.present) {
      map['total_lbp'] = Variable<double>(totalLbp.value);
    }
    if (exchangeRateUsed.present) {
      map['exchange_rate_used'] = Variable<double>(exchangeRateUsed.value);
    }
    if (paymentType.present) {
      map['payment_type'] = Variable<String>(paymentType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSalesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerId: $customerId, ')
          ..write('totalUsd: $totalUsd, ')
          ..write('totalLbp: $totalLbp, ')
          ..write('exchangeRateUsed: $exchangeRateUsed, ')
          ..write('paymentType: $paymentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSaleItemsTable extends LocalSaleItems
    with TableInfo<$LocalSaleItemsTable, LocalSaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceUsdMeta = const VerificationMeta(
    'unitPriceUsd',
  );
  @override
  late final GeneratedColumn<double> unitPriceUsd = GeneratedColumn<double>(
    'unit_price_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalUsdMeta = const VerificationMeta(
    'subtotalUsd',
  );
  @override
  late final GeneratedColumn<double> subtotalUsd = GeneratedColumn<double>(
    'subtotal_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceUsdSnapshotMeta =
      const VerificationMeta('costPriceUsdSnapshot');
  @override
  late final GeneratedColumn<double> costPriceUsdSnapshot =
      GeneratedColumn<double>(
        'cost_price_usd_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    productNameSnapshot,
    quantity,
    unitPriceUsd,
    subtotalUsd,
    costPriceUsdSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSaleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price_usd')) {
      context.handle(
        _unitPriceUsdMeta,
        unitPriceUsd.isAcceptableOrUnknown(
          data['unit_price_usd']!,
          _unitPriceUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceUsdMeta);
    }
    if (data.containsKey('subtotal_usd')) {
      context.handle(
        _subtotalUsdMeta,
        subtotalUsd.isAcceptableOrUnknown(
          data['subtotal_usd']!,
          _subtotalUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalUsdMeta);
    }
    if (data.containsKey('cost_price_usd_snapshot')) {
      context.handle(
        _costPriceUsdSnapshotMeta,
        costPriceUsdSnapshot.isAcceptableOrUnknown(
          data['cost_price_usd_snapshot']!,
          _costPriceUsdSnapshotMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSaleItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPriceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price_usd'],
      )!,
      subtotalUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal_usd'],
      )!,
      costPriceUsdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price_usd_snapshot'],
      ),
    );
  }

  @override
  $LocalSaleItemsTable createAlias(String alias) {
    return $LocalSaleItemsTable(attachedDatabase, alias);
  }
}

class LocalSaleItem extends DataClass implements Insertable<LocalSaleItem> {
  final String id;
  final String saleId;
  final String productId;
  final String productNameSnapshot;
  final int quantity;
  final double unitPriceUsd;
  final double subtotalUsd;
  final double? costPriceUsdSnapshot;
  const LocalSaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPriceUsd,
    required this.subtotalUsd,
    this.costPriceUsdSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price_usd'] = Variable<double>(unitPriceUsd);
    map['subtotal_usd'] = Variable<double>(subtotalUsd);
    if (!nullToAbsent || costPriceUsdSnapshot != null) {
      map['cost_price_usd_snapshot'] = Variable<double>(costPriceUsdSnapshot);
    }
    return map;
  }

  LocalSaleItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalSaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productNameSnapshot: Value(productNameSnapshot),
      quantity: Value(quantity),
      unitPriceUsd: Value(unitPriceUsd),
      subtotalUsd: Value(subtotalUsd),
      costPriceUsdSnapshot: costPriceUsdSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(costPriceUsdSnapshot),
    );
  }

  factory LocalSaleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSaleItem(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      productNameSnapshot: serializer.fromJson<String>(
        json['productNameSnapshot'],
      ),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPriceUsd: serializer.fromJson<double>(json['unitPriceUsd']),
      subtotalUsd: serializer.fromJson<double>(json['subtotalUsd']),
      costPriceUsdSnapshot: serializer.fromJson<double?>(
        json['costPriceUsdSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
      'quantity': serializer.toJson<int>(quantity),
      'unitPriceUsd': serializer.toJson<double>(unitPriceUsd),
      'subtotalUsd': serializer.toJson<double>(subtotalUsd),
      'costPriceUsdSnapshot': serializer.toJson<double?>(costPriceUsdSnapshot),
    };
  }

  LocalSaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productNameSnapshot,
    int? quantity,
    double? unitPriceUsd,
    double? subtotalUsd,
    Value<double?> costPriceUsdSnapshot = const Value.absent(),
  }) => LocalSaleItem(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
    quantity: quantity ?? this.quantity,
    unitPriceUsd: unitPriceUsd ?? this.unitPriceUsd,
    subtotalUsd: subtotalUsd ?? this.subtotalUsd,
    costPriceUsdSnapshot: costPriceUsdSnapshot.present
        ? costPriceUsdSnapshot.value
        : this.costPriceUsdSnapshot,
  );
  LocalSaleItem copyWithCompanion(LocalSaleItemsCompanion data) {
    return LocalSaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPriceUsd: data.unitPriceUsd.present
          ? data.unitPriceUsd.value
          : this.unitPriceUsd,
      subtotalUsd: data.subtotalUsd.present
          ? data.subtotalUsd.value
          : this.subtotalUsd,
      costPriceUsdSnapshot: data.costPriceUsdSnapshot.present
          ? data.costPriceUsdSnapshot.value
          : this.costPriceUsdSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceUsd: $unitPriceUsd, ')
          ..write('subtotalUsd: $subtotalUsd, ')
          ..write('costPriceUsdSnapshot: $costPriceUsdSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    productId,
    productNameSnapshot,
    quantity,
    unitPriceUsd,
    subtotalUsd,
    costPriceUsdSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.quantity == this.quantity &&
          other.unitPriceUsd == this.unitPriceUsd &&
          other.subtotalUsd == this.subtotalUsd &&
          other.costPriceUsdSnapshot == this.costPriceUsdSnapshot);
}

class LocalSaleItemsCompanion extends UpdateCompanion<LocalSaleItem> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<String> productNameSnapshot;
  final Value<int> quantity;
  final Value<double> unitPriceUsd;
  final Value<double> subtotalUsd;
  final Value<double?> costPriceUsdSnapshot;
  final Value<int> rowid;
  const LocalSaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPriceUsd = const Value.absent(),
    this.subtotalUsd = const Value.absent(),
    this.costPriceUsdSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSaleItemsCompanion.insert({
    required String id,
    required String saleId,
    required String productId,
    required String productNameSnapshot,
    required int quantity,
    required double unitPriceUsd,
    required double subtotalUsd,
    this.costPriceUsdSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       productId = Value(productId),
       productNameSnapshot = Value(productNameSnapshot),
       quantity = Value(quantity),
       unitPriceUsd = Value(unitPriceUsd),
       subtotalUsd = Value(subtotalUsd);
  static Insertable<LocalSaleItem> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<String>? productNameSnapshot,
    Expression<int>? quantity,
    Expression<double>? unitPriceUsd,
    Expression<double>? subtotalUsd,
    Expression<double>? costPriceUsdSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (quantity != null) 'quantity': quantity,
      if (unitPriceUsd != null) 'unit_price_usd': unitPriceUsd,
      if (subtotalUsd != null) 'subtotal_usd': subtotalUsd,
      if (costPriceUsdSnapshot != null)
        'cost_price_usd_snapshot': costPriceUsdSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSaleItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? productId,
    Value<String>? productNameSnapshot,
    Value<int>? quantity,
    Value<double>? unitPriceUsd,
    Value<double>? subtotalUsd,
    Value<double?>? costPriceUsdSnapshot,
    Value<int>? rowid,
  }) {
    return LocalSaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      quantity: quantity ?? this.quantity,
      unitPriceUsd: unitPriceUsd ?? this.unitPriceUsd,
      subtotalUsd: subtotalUsd ?? this.subtotalUsd,
      costPriceUsdSnapshot: costPriceUsdSnapshot ?? this.costPriceUsdSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPriceUsd.present) {
      map['unit_price_usd'] = Variable<double>(unitPriceUsd.value);
    }
    if (subtotalUsd.present) {
      map['subtotal_usd'] = Variable<double>(subtotalUsd.value);
    }
    if (costPriceUsdSnapshot.present) {
      map['cost_price_usd_snapshot'] = Variable<double>(
        costPriceUsdSnapshot.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceUsd: $unitPriceUsd, ')
          ..write('subtotalUsd: $subtotalUsd, ')
          ..write('costPriceUsdSnapshot: $costPriceUsdSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoriesTable extends LocalInventories
    with TableInfo<$LocalInventoriesTable, LocalInventory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInventory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalInventoriesTable createAlias(String alias) {
    return $LocalInventoriesTable(attachedDatabase, alias);
  }
}

class LocalInventory extends DataClass implements Insertable<LocalInventory> {
  final String id;
  final String businessId;
  final String name;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const LocalInventory({
    required this.id,
    required this.businessId,
    required this.name,
    required this.isArchived,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalInventoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoriesCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalInventory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventory(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalInventory copyWith({
    String? id,
    String? businessId,
    String? name,
    bool? isArchived,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalInventory(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalInventory copyWithCompanion(LocalInventoriesCompanion data) {
    return LocalInventory(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventory(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, businessId, name, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventory &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalInventoriesCompanion extends UpdateCompanion<LocalInventory> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalInventoriesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoriesCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<LocalInventory> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalInventoriesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoriesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryStockTable extends LocalInventoryStock
    with TableInfo<$LocalInventoryStockTable, LocalStockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryStockTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellPriceUsdMeta = const VerificationMeta(
    'sellPriceUsd',
  );
  @override
  late final GeneratedColumn<double> sellPriceUsd = GeneratedColumn<double>(
    'sell_price_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceUsdMeta = const VerificationMeta(
    'costPriceUsd',
  );
  @override
  late final GeneratedColumn<double> costPriceUsd = GeneratedColumn<double>(
    'cost_price_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowStockThresholdMeta = const VerificationMeta(
    'lowStockThreshold',
  );
  @override
  late final GeneratedColumn<int> lowStockThreshold = GeneratedColumn<int>(
    'low_stock_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    inventoryId,
    quantity,
    sellPriceUsd,
    costPriceUsd,
    lowStockThreshold,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_stock';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('sell_price_usd')) {
      context.handle(
        _sellPriceUsdMeta,
        sellPriceUsd.isAcceptableOrUnknown(
          data['sell_price_usd']!,
          _sellPriceUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellPriceUsdMeta);
    }
    if (data.containsKey('cost_price_usd')) {
      context.handle(
        _costPriceUsdMeta,
        costPriceUsd.isAcceptableOrUnknown(
          data['cost_price_usd']!,
          _costPriceUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costPriceUsdMeta);
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
        _lowStockThresholdMeta,
        lowStockThreshold.isAcceptableOrUnknown(
          data['low_stock_threshold']!,
          _lowStockThresholdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, inventoryId};
  @override
  LocalStockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      sellPriceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price_usd'],
      )!,
      costPriceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price_usd'],
      )!,
      lowStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_threshold'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalInventoryStockTable createAlias(String alias) {
    return $LocalInventoryStockTable(attachedDatabase, alias);
  }
}

class LocalStockRow extends DataClass implements Insertable<LocalStockRow> {
  final String productId;
  final String inventoryId;
  final int quantity;
  final double sellPriceUsd;
  final double costPriceUsd;
  final int lowStockThreshold;
  final DateTime? updatedAt;
  const LocalStockRow({
    required this.productId,
    required this.inventoryId,
    required this.quantity,
    required this.sellPriceUsd,
    required this.costPriceUsd,
    required this.lowStockThreshold,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['inventory_id'] = Variable<String>(inventoryId);
    map['quantity'] = Variable<int>(quantity);
    map['sell_price_usd'] = Variable<double>(sellPriceUsd);
    map['cost_price_usd'] = Variable<double>(costPriceUsd);
    map['low_stock_threshold'] = Variable<int>(lowStockThreshold);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalInventoryStockCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryStockCompanion(
      productId: Value(productId),
      inventoryId: Value(inventoryId),
      quantity: Value(quantity),
      sellPriceUsd: Value(sellPriceUsd),
      costPriceUsd: Value(costPriceUsd),
      lowStockThreshold: Value(lowStockThreshold),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalStockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockRow(
      productId: serializer.fromJson<String>(json['productId']),
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      sellPriceUsd: serializer.fromJson<double>(json['sellPriceUsd']),
      costPriceUsd: serializer.fromJson<double>(json['costPriceUsd']),
      lowStockThreshold: serializer.fromJson<int>(json['lowStockThreshold']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'inventoryId': serializer.toJson<String>(inventoryId),
      'quantity': serializer.toJson<int>(quantity),
      'sellPriceUsd': serializer.toJson<double>(sellPriceUsd),
      'costPriceUsd': serializer.toJson<double>(costPriceUsd),
      'lowStockThreshold': serializer.toJson<int>(lowStockThreshold),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalStockRow copyWith({
    String? productId,
    String? inventoryId,
    int? quantity,
    double? sellPriceUsd,
    double? costPriceUsd,
    int? lowStockThreshold,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalStockRow(
    productId: productId ?? this.productId,
    inventoryId: inventoryId ?? this.inventoryId,
    quantity: quantity ?? this.quantity,
    sellPriceUsd: sellPriceUsd ?? this.sellPriceUsd,
    costPriceUsd: costPriceUsd ?? this.costPriceUsd,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalStockRow copyWithCompanion(LocalInventoryStockCompanion data) {
    return LocalStockRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      sellPriceUsd: data.sellPriceUsd.present
          ? data.sellPriceUsd.value
          : this.sellPriceUsd,
      costPriceUsd: data.costPriceUsd.present
          ? data.costPriceUsd.value
          : this.costPriceUsd,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockRow(')
          ..write('productId: $productId, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('quantity: $quantity, ')
          ..write('sellPriceUsd: $sellPriceUsd, ')
          ..write('costPriceUsd: $costPriceUsd, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    productId,
    inventoryId,
    quantity,
    sellPriceUsd,
    costPriceUsd,
    lowStockThreshold,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockRow &&
          other.productId == this.productId &&
          other.inventoryId == this.inventoryId &&
          other.quantity == this.quantity &&
          other.sellPriceUsd == this.sellPriceUsd &&
          other.costPriceUsd == this.costPriceUsd &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.updatedAt == this.updatedAt);
}

class LocalInventoryStockCompanion extends UpdateCompanion<LocalStockRow> {
  final Value<String> productId;
  final Value<String> inventoryId;
  final Value<int> quantity;
  final Value<double> sellPriceUsd;
  final Value<double> costPriceUsd;
  final Value<int> lowStockThreshold;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalInventoryStockCompanion({
    this.productId = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.sellPriceUsd = const Value.absent(),
    this.costPriceUsd = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryStockCompanion.insert({
    required String productId,
    required String inventoryId,
    this.quantity = const Value.absent(),
    required double sellPriceUsd,
    required double costPriceUsd,
    this.lowStockThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       inventoryId = Value(inventoryId),
       sellPriceUsd = Value(sellPriceUsd),
       costPriceUsd = Value(costPriceUsd);
  static Insertable<LocalStockRow> custom({
    Expression<String>? productId,
    Expression<String>? inventoryId,
    Expression<int>? quantity,
    Expression<double>? sellPriceUsd,
    Expression<double>? costPriceUsd,
    Expression<int>? lowStockThreshold,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (quantity != null) 'quantity': quantity,
      if (sellPriceUsd != null) 'sell_price_usd': sellPriceUsd,
      if (costPriceUsd != null) 'cost_price_usd': costPriceUsd,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryStockCompanion copyWith({
    Value<String>? productId,
    Value<String>? inventoryId,
    Value<int>? quantity,
    Value<double>? sellPriceUsd,
    Value<double>? costPriceUsd,
    Value<int>? lowStockThreshold,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalInventoryStockCompanion(
      productId: productId ?? this.productId,
      inventoryId: inventoryId ?? this.inventoryId,
      quantity: quantity ?? this.quantity,
      sellPriceUsd: sellPriceUsd ?? this.sellPriceUsd,
      costPriceUsd: costPriceUsd ?? this.costPriceUsd,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (sellPriceUsd.present) {
      map['sell_price_usd'] = Variable<double>(sellPriceUsd.value);
    }
    if (costPriceUsd.present) {
      map['cost_price_usd'] = Variable<double>(costPriceUsd.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<int>(lowStockThreshold.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryStockCompanion(')
          ..write('productId: $productId, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('quantity: $quantity, ')
          ..write('sellPriceUsd: $sellPriceUsd, ')
          ..write('costPriceUsd: $costPriceUsd, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryAccessTable extends LocalInventoryAccess
    with TableInfo<$LocalInventoryAccessTable, LocalInventoryAccessRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryAccessTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canPosMeta = const VerificationMeta('canPos');
  @override
  late final GeneratedColumn<bool> canPos = GeneratedColumn<bool>(
    'can_pos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_pos" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _canViewMeta = const VerificationMeta(
    'canView',
  );
  @override
  late final GeneratedColumn<bool> canView = GeneratedColumn<bool>(
    'can_view',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_view" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _canEditMeta = const VerificationMeta(
    'canEdit',
  );
  @override
  late final GeneratedColumn<bool> canEdit = GeneratedColumn<bool>(
    'can_edit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_edit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    inventoryId,
    userId,
    canPos,
    canView,
    canEdit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_access';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventoryAccessRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('can_pos')) {
      context.handle(
        _canPosMeta,
        canPos.isAcceptableOrUnknown(data['can_pos']!, _canPosMeta),
      );
    }
    if (data.containsKey('can_view')) {
      context.handle(
        _canViewMeta,
        canView.isAcceptableOrUnknown(data['can_view']!, _canViewMeta),
      );
    }
    if (data.containsKey('can_edit')) {
      context.handle(
        _canEditMeta,
        canEdit.isAcceptableOrUnknown(data['can_edit']!, _canEditMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {inventoryId, userId};
  @override
  LocalInventoryAccessRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventoryAccessRow(
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      canPos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_pos'],
      )!,
      canView: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_view'],
      )!,
      canEdit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_edit'],
      )!,
    );
  }

  @override
  $LocalInventoryAccessTable createAlias(String alias) {
    return $LocalInventoryAccessTable(attachedDatabase, alias);
  }
}

class LocalInventoryAccessRow extends DataClass
    implements Insertable<LocalInventoryAccessRow> {
  final String inventoryId;
  final String userId;
  final bool canPos;
  final bool canView;
  final bool canEdit;
  const LocalInventoryAccessRow({
    required this.inventoryId,
    required this.userId,
    required this.canPos,
    required this.canView,
    required this.canEdit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['inventory_id'] = Variable<String>(inventoryId);
    map['user_id'] = Variable<String>(userId);
    map['can_pos'] = Variable<bool>(canPos);
    map['can_view'] = Variable<bool>(canView);
    map['can_edit'] = Variable<bool>(canEdit);
    return map;
  }

  LocalInventoryAccessCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryAccessCompanion(
      inventoryId: Value(inventoryId),
      userId: Value(userId),
      canPos: Value(canPos),
      canView: Value(canView),
      canEdit: Value(canEdit),
    );
  }

  factory LocalInventoryAccessRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventoryAccessRow(
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      userId: serializer.fromJson<String>(json['userId']),
      canPos: serializer.fromJson<bool>(json['canPos']),
      canView: serializer.fromJson<bool>(json['canView']),
      canEdit: serializer.fromJson<bool>(json['canEdit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'inventoryId': serializer.toJson<String>(inventoryId),
      'userId': serializer.toJson<String>(userId),
      'canPos': serializer.toJson<bool>(canPos),
      'canView': serializer.toJson<bool>(canView),
      'canEdit': serializer.toJson<bool>(canEdit),
    };
  }

  LocalInventoryAccessRow copyWith({
    String? inventoryId,
    String? userId,
    bool? canPos,
    bool? canView,
    bool? canEdit,
  }) => LocalInventoryAccessRow(
    inventoryId: inventoryId ?? this.inventoryId,
    userId: userId ?? this.userId,
    canPos: canPos ?? this.canPos,
    canView: canView ?? this.canView,
    canEdit: canEdit ?? this.canEdit,
  );
  LocalInventoryAccessRow copyWithCompanion(
    LocalInventoryAccessCompanion data,
  ) {
    return LocalInventoryAccessRow(
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      userId: data.userId.present ? data.userId.value : this.userId,
      canPos: data.canPos.present ? data.canPos.value : this.canPos,
      canView: data.canView.present ? data.canView.value : this.canView,
      canEdit: data.canEdit.present ? data.canEdit.value : this.canEdit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryAccessRow(')
          ..write('inventoryId: $inventoryId, ')
          ..write('userId: $userId, ')
          ..write('canPos: $canPos, ')
          ..write('canView: $canView, ')
          ..write('canEdit: $canEdit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(inventoryId, userId, canPos, canView, canEdit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventoryAccessRow &&
          other.inventoryId == this.inventoryId &&
          other.userId == this.userId &&
          other.canPos == this.canPos &&
          other.canView == this.canView &&
          other.canEdit == this.canEdit);
}

class LocalInventoryAccessCompanion
    extends UpdateCompanion<LocalInventoryAccessRow> {
  final Value<String> inventoryId;
  final Value<String> userId;
  final Value<bool> canPos;
  final Value<bool> canView;
  final Value<bool> canEdit;
  final Value<int> rowid;
  const LocalInventoryAccessCompanion({
    this.inventoryId = const Value.absent(),
    this.userId = const Value.absent(),
    this.canPos = const Value.absent(),
    this.canView = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryAccessCompanion.insert({
    required String inventoryId,
    required String userId,
    this.canPos = const Value.absent(),
    this.canView = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : inventoryId = Value(inventoryId),
       userId = Value(userId);
  static Insertable<LocalInventoryAccessRow> custom({
    Expression<String>? inventoryId,
    Expression<String>? userId,
    Expression<bool>? canPos,
    Expression<bool>? canView,
    Expression<bool>? canEdit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (userId != null) 'user_id': userId,
      if (canPos != null) 'can_pos': canPos,
      if (canView != null) 'can_view': canView,
      if (canEdit != null) 'can_edit': canEdit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryAccessCompanion copyWith({
    Value<String>? inventoryId,
    Value<String>? userId,
    Value<bool>? canPos,
    Value<bool>? canView,
    Value<bool>? canEdit,
    Value<int>? rowid,
  }) {
    return LocalInventoryAccessCompanion(
      inventoryId: inventoryId ?? this.inventoryId,
      userId: userId ?? this.userId,
      canPos: canPos ?? this.canPos,
      canView: canView ?? this.canView,
      canEdit: canEdit ?? this.canEdit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (canPos.present) {
      map['can_pos'] = Variable<bool>(canPos.value);
    }
    if (canView.present) {
      map['can_view'] = Variable<bool>(canView.value);
    }
    if (canEdit.present) {
      map['can_edit'] = Variable<bool>(canEdit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryAccessCompanion(')
          ..write('inventoryId: $inventoryId, ')
          ..write('userId: $userId, ')
          ..write('canPos: $canPos, ')
          ..write('canView: $canView, ')
          ..write('canEdit: $canEdit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockTransfersTable extends LocalStockTransfers
    with TableInfo<$LocalStockTransfersTable, LocalStockTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromInventoryIdMeta = const VerificationMeta(
    'fromInventoryId',
  );
  @override
  late final GeneratedColumn<String> fromInventoryId = GeneratedColumn<String>(
    'from_inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toInventoryIdMeta = const VerificationMeta(
    'toInventoryId',
  );
  @override
  late final GeneratedColumn<String> toInventoryId = GeneratedColumn<String>(
    'to_inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    fromInventoryId,
    toInventoryId,
    createdBy,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockTransfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('from_inventory_id')) {
      context.handle(
        _fromInventoryIdMeta,
        fromInventoryId.isAcceptableOrUnknown(
          data['from_inventory_id']!,
          _fromInventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromInventoryIdMeta);
    }
    if (data.containsKey('to_inventory_id')) {
      context.handle(
        _toInventoryIdMeta,
        toInventoryId.isAcceptableOrUnknown(
          data['to_inventory_id']!,
          _toInventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toInventoryIdMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockTransfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      fromInventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_inventory_id'],
      )!,
      toInventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_inventory_id'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalStockTransfersTable createAlias(String alias) {
    return $LocalStockTransfersTable(attachedDatabase, alias);
  }
}

class LocalStockTransfer extends DataClass
    implements Insertable<LocalStockTransfer> {
  final String id;
  final String businessId;
  final String fromInventoryId;
  final String toInventoryId;
  final String? createdBy;
  final DateTime createdAt;
  const LocalStockTransfer({
    required this.id,
    required this.businessId,
    required this.fromInventoryId,
    required this.toInventoryId,
    this.createdBy,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['from_inventory_id'] = Variable<String>(fromInventoryId);
    map['to_inventory_id'] = Variable<String>(toInventoryId);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalStockTransfersCompanion toCompanion(bool nullToAbsent) {
    return LocalStockTransfersCompanion(
      id: Value(id),
      businessId: Value(businessId),
      fromInventoryId: Value(fromInventoryId),
      toInventoryId: Value(toInventoryId),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
    );
  }

  factory LocalStockTransfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockTransfer(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      fromInventoryId: serializer.fromJson<String>(json['fromInventoryId']),
      toInventoryId: serializer.fromJson<String>(json['toInventoryId']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'fromInventoryId': serializer.toJson<String>(fromInventoryId),
      'toInventoryId': serializer.toJson<String>(toInventoryId),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalStockTransfer copyWith({
    String? id,
    String? businessId,
    String? fromInventoryId,
    String? toInventoryId,
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
  }) => LocalStockTransfer(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    fromInventoryId: fromInventoryId ?? this.fromInventoryId,
    toInventoryId: toInventoryId ?? this.toInventoryId,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalStockTransfer copyWithCompanion(LocalStockTransfersCompanion data) {
    return LocalStockTransfer(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      fromInventoryId: data.fromInventoryId.present
          ? data.fromInventoryId.value
          : this.fromInventoryId,
      toInventoryId: data.toInventoryId.present
          ? data.toInventoryId.value
          : this.toInventoryId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransfer(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('fromInventoryId: $fromInventoryId, ')
          ..write('toInventoryId: $toInventoryId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    fromInventoryId,
    toInventoryId,
    createdBy,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockTransfer &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.fromInventoryId == this.fromInventoryId &&
          other.toInventoryId == this.toInventoryId &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt);
}

class LocalStockTransfersCompanion extends UpdateCompanion<LocalStockTransfer> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> fromInventoryId;
  final Value<String> toInventoryId;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalStockTransfersCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.fromInventoryId = const Value.absent(),
    this.toInventoryId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockTransfersCompanion.insert({
    required String id,
    required String businessId,
    required String fromInventoryId,
    required String toInventoryId,
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       fromInventoryId = Value(fromInventoryId),
       toInventoryId = Value(toInventoryId),
       createdAt = Value(createdAt);
  static Insertable<LocalStockTransfer> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? fromInventoryId,
    Expression<String>? toInventoryId,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (fromInventoryId != null) 'from_inventory_id': fromInventoryId,
      if (toInventoryId != null) 'to_inventory_id': toInventoryId,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockTransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? fromInventoryId,
    Value<String>? toInventoryId,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalStockTransfersCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      fromInventoryId: fromInventoryId ?? this.fromInventoryId,
      toInventoryId: toInventoryId ?? this.toInventoryId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (fromInventoryId.present) {
      map['from_inventory_id'] = Variable<String>(fromInventoryId.value);
    }
    if (toInventoryId.present) {
      map['to_inventory_id'] = Variable<String>(toInventoryId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransfersCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('fromInventoryId: $fromInventoryId, ')
          ..write('toInventoryId: $toInventoryId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockTransferItemsTable extends LocalStockTransferItems
    with TableInfo<$LocalStockTransferItemsTable, LocalStockTransferItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockTransferItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transferId,
    productId,
    quantity,
    productNameSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock_transfer_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockTransferItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockTransferItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockTransferItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      )!,
    );
  }

  @override
  $LocalStockTransferItemsTable createAlias(String alias) {
    return $LocalStockTransferItemsTable(attachedDatabase, alias);
  }
}

class LocalStockTransferItem extends DataClass
    implements Insertable<LocalStockTransferItem> {
  final String id;
  final String transferId;
  final String? productId;
  final int quantity;
  final String productNameSnapshot;
  const LocalStockTransferItem({
    required this.id,
    required this.transferId,
    this.productId,
    required this.quantity,
    required this.productNameSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transfer_id'] = Variable<String>(transferId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['quantity'] = Variable<int>(quantity);
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    return map;
  }

  LocalStockTransferItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalStockTransferItemsCompanion(
      id: Value(id),
      transferId: Value(transferId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      quantity: Value(quantity),
      productNameSnapshot: Value(productNameSnapshot),
    );
  }

  factory LocalStockTransferItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockTransferItem(
      id: serializer.fromJson<String>(json['id']),
      transferId: serializer.fromJson<String>(json['transferId']),
      productId: serializer.fromJson<String?>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      productNameSnapshot: serializer.fromJson<String>(
        json['productNameSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transferId': serializer.toJson<String>(transferId),
      'productId': serializer.toJson<String?>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
    };
  }

  LocalStockTransferItem copyWith({
    String? id,
    String? transferId,
    Value<String?> productId = const Value.absent(),
    int? quantity,
    String? productNameSnapshot,
  }) => LocalStockTransferItem(
    id: id ?? this.id,
    transferId: transferId ?? this.transferId,
    productId: productId.present ? productId.value : this.productId,
    quantity: quantity ?? this.quantity,
    productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
  );
  LocalStockTransferItem copyWithCompanion(
    LocalStockTransferItemsCompanion data,
  ) {
    return LocalStockTransferItem(
      id: data.id.present ? data.id.value : this.id,
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransferItem(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('productNameSnapshot: $productNameSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transferId, productId, quantity, productNameSnapshot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockTransferItem &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.productNameSnapshot == this.productNameSnapshot);
}

class LocalStockTransferItemsCompanion
    extends UpdateCompanion<LocalStockTransferItem> {
  final Value<String> id;
  final Value<String> transferId;
  final Value<String?> productId;
  final Value<int> quantity;
  final Value<String> productNameSnapshot;
  final Value<int> rowid;
  const LocalStockTransferItemsCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockTransferItemsCompanion.insert({
    required String id,
    required String transferId,
    this.productId = const Value.absent(),
    required int quantity,
    required String productNameSnapshot,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transferId = Value(transferId),
       quantity = Value(quantity),
       productNameSnapshot = Value(productNameSnapshot);
  static Insertable<LocalStockTransferItem> custom({
    Expression<String>? id,
    Expression<String>? transferId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<String>? productNameSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockTransferItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? transferId,
    Value<String?>? productId,
    Value<int>? quantity,
    Value<String>? productNameSnapshot,
    Value<int>? rowid,
  }) {
    return LocalStockTransferItemsCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransferItemsCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueEntriesTable extends SyncQueueEntries
    with TableInfo<$SyncQueueEntriesTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    payloadJson,
    status,
    createdAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueEntriesTable createAlias(String alias) {
    return $SyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final String id;
  final String operationType;
  final String payloadJson;
  final String status;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  const SyncQueueEntry({
    required this.id,
    required this.operationType,
    required this.payloadJson,
    required this.status,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueEntriesCompanion(
      id: Value(id),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<String>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueEntry copyWith({
    String? id,
    String? operationType,
    String? payloadJson,
    String? status,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueEntry(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueEntriesCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    payloadJson,
    status,
    createdAt,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncQueueEntriesCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<String> id;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueEntriesCompanion.insert({
    required String id,
    required String operationType,
    required String payloadJson,
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<String>? id,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncQueueEntriesCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataEntriesTable extends SyncMetadataEntries
    with TableInfo<$SyncMetadataEntriesTable, SyncMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [businessId, lastPullAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPullAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId};
  @override
  SyncMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataEntry(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      )!,
    );
  }

  @override
  $SyncMetadataEntriesTable createAlias(String alias) {
    return $SyncMetadataEntriesTable(attachedDatabase, alias);
  }
}

class SyncMetadataEntry extends DataClass
    implements Insertable<SyncMetadataEntry> {
  final String businessId;
  final DateTime lastPullAt;
  const SyncMetadataEntry({required this.businessId, required this.lastPullAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    return map;
  }

  SyncMetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataEntriesCompanion(
      businessId: Value(businessId),
      lastPullAt: Value(lastPullAt),
    );
  }

  factory SyncMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataEntry(
      businessId: serializer.fromJson<String>(json['businessId']),
      lastPullAt: serializer.fromJson<DateTime>(json['lastPullAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'businessId': serializer.toJson<String>(businessId),
      'lastPullAt': serializer.toJson<DateTime>(lastPullAt),
    };
  }

  SyncMetadataEntry copyWith({String? businessId, DateTime? lastPullAt}) =>
      SyncMetadataEntry(
        businessId: businessId ?? this.businessId,
        lastPullAt: lastPullAt ?? this.lastPullAt,
      );
  SyncMetadataEntry copyWithCompanion(SyncMetadataEntriesCompanion data) {
    return SyncMetadataEntry(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntry(')
          ..write('businessId: $businessId, ')
          ..write('lastPullAt: $lastPullAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(businessId, lastPullAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataEntry &&
          other.businessId == this.businessId &&
          other.lastPullAt == this.lastPullAt);
}

class SyncMetadataEntriesCompanion extends UpdateCompanion<SyncMetadataEntry> {
  final Value<String> businessId;
  final Value<DateTime> lastPullAt;
  final Value<int> rowid;
  const SyncMetadataEntriesCompanion({
    this.businessId = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataEntriesCompanion.insert({
    required String businessId,
    required DateTime lastPullAt,
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       lastPullAt = Value(lastPullAt);
  static Insertable<SyncMetadataEntry> custom({
    Expression<String>? businessId,
    Expression<DateTime>? lastPullAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataEntriesCompanion copyWith({
    Value<String>? businessId,
    Value<DateTime>? lastPullAt,
    Value<int>? rowid,
  }) {
    return SyncMetadataEntriesCompanion(
      businessId: businessId ?? this.businessId,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntriesCompanion(')
          ..write('businessId: $businessId, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalCustomersTable localCustomers = $LocalCustomersTable(this);
  late final $LocalSalesTable localSales = $LocalSalesTable(this);
  late final $LocalSaleItemsTable localSaleItems = $LocalSaleItemsTable(this);
  late final $LocalInventoriesTable localInventories = $LocalInventoriesTable(
    this,
  );
  late final $LocalInventoryStockTable localInventoryStock =
      $LocalInventoryStockTable(this);
  late final $LocalInventoryAccessTable localInventoryAccess =
      $LocalInventoryAccessTable(this);
  late final $LocalStockTransfersTable localStockTransfers =
      $LocalStockTransfersTable(this);
  late final $LocalStockTransferItemsTable localStockTransferItems =
      $LocalStockTransferItemsTable(this);
  late final $SyncQueueEntriesTable syncQueueEntries = $SyncQueueEntriesTable(
    this,
  );
  late final $SyncMetadataEntriesTable syncMetadataEntries =
      $SyncMetadataEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProducts,
    localCustomers,
    localSales,
    localSaleItems,
    localInventories,
    localInventoryStock,
    localInventoryAccess,
    localStockTransfers,
    localStockTransferItems,
    syncQueueEntries,
    syncMetadataEntries,
  ];
}

typedef $$LocalProductsTableCreateCompanionBuilder =
    LocalProductsCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String?> sku,
      Value<String?> category,
      required double costPriceUsd,
      required double sellPriceUsd,
      required int quantity,
      Value<int> lowStockThreshold,
      Value<DateTime?> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$LocalProductsTableUpdateCompanionBuilder =
    LocalProductsCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String?> sku,
      Value<String?> category,
      Value<double> costPriceUsd,
      Value<double> sellPriceUsd,
      Value<int> quantity,
      Value<int> lowStockThreshold,
      Value<DateTime?> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$LocalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPriceUsd => $composableBuilder(
    column: $table.costPriceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPriceUsd => $composableBuilder(
    column: $table.sellPriceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPriceUsd => $composableBuilder(
    column: $table.costPriceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPriceUsd => $composableBuilder(
    column: $table.sellPriceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get costPriceUsd => $composableBuilder(
    column: $table.costPriceUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sellPriceUsd => $composableBuilder(
    column: $table.sellPriceUsd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$LocalProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductsTable,
          LocalProduct,
          $$LocalProductsTableFilterComposer,
          $$LocalProductsTableOrderingComposer,
          $$LocalProductsTableAnnotationComposer,
          $$LocalProductsTableCreateCompanionBuilder,
          $$LocalProductsTableUpdateCompanionBuilder,
          (
            LocalProduct,
            BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>,
          ),
          LocalProduct,
          PrefetchHooks Function()
        > {
  $$LocalProductsTableTableManager(_$AppDatabase db, $LocalProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double> costPriceUsd = const Value.absent(),
                Value<double> sellPriceUsd = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> lowStockThreshold = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion(
                id: id,
                businessId: businessId,
                name: name,
                sku: sku,
                category: category,
                costPriceUsd: costPriceUsd,
                sellPriceUsd: sellPriceUsd,
                quantity: quantity,
                lowStockThreshold: lowStockThreshold,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required double costPriceUsd,
                required double sellPriceUsd,
                required int quantity,
                Value<int> lowStockThreshold = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                sku: sku,
                category: category,
                costPriceUsd: costPriceUsd,
                sellPriceUsd: sellPriceUsd,
                quantity: quantity,
                lowStockThreshold: lowStockThreshold,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalProductsTable, LocalProduct>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalProductsTable,
                    LocalProduct
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductsTable,
      LocalProduct,
      $$LocalProductsTableFilterComposer,
      $$LocalProductsTableOrderingComposer,
      $$LocalProductsTableAnnotationComposer,
      $$LocalProductsTableCreateCompanionBuilder,
      $$LocalProductsTableUpdateCompanionBuilder,
      (
        LocalProduct,
        BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>,
      ),
      LocalProduct,
      PrefetchHooks Function()
    >;
typedef $$LocalCustomersTableCreateCompanionBuilder =
    LocalCustomersCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String?> phone,
      required DateTime createdAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$LocalCustomersTableUpdateCompanionBuilder =
    LocalCustomersCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String?> phone,
      Value<DateTime> createdAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$LocalCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$LocalCustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCustomersTable,
          LocalCustomer,
          $$LocalCustomersTableFilterComposer,
          $$LocalCustomersTableOrderingComposer,
          $$LocalCustomersTableAnnotationComposer,
          $$LocalCustomersTableCreateCompanionBuilder,
          $$LocalCustomersTableUpdateCompanionBuilder,
          (
            LocalCustomer,
            BaseReferences<_$AppDatabase, $LocalCustomersTable, LocalCustomer>,
          ),
          LocalCustomer,
          PrefetchHooks Function()
        > {
  $$LocalCustomersTableTableManager(
    _$AppDatabase db,
    $LocalCustomersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                createdAt: createdAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String?> phone = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                createdAt: createdAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCustomersTable, LocalCustomer>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCustomersTable,
                    LocalCustomer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCustomersTable,
      LocalCustomer,
      $$LocalCustomersTableFilterComposer,
      $$LocalCustomersTableOrderingComposer,
      $$LocalCustomersTableAnnotationComposer,
      $$LocalCustomersTableCreateCompanionBuilder,
      $$LocalCustomersTableUpdateCompanionBuilder,
      (
        LocalCustomer,
        BaseReferences<_$AppDatabase, $LocalCustomersTable, LocalCustomer>,
      ),
      LocalCustomer,
      PrefetchHooks Function()
    >;
typedef $$LocalSalesTableCreateCompanionBuilder =
    LocalSalesCompanion Function({
      required String id,
      required String businessId,
      Value<String?> customerId,
      required double totalUsd,
      required double totalLbp,
      required double exchangeRateUsed,
      required String paymentType,
      required DateTime createdAt,
      Value<bool> synced,
      Value<String?> inventoryId,
      Value<int> rowid,
    });
typedef $$LocalSalesTableUpdateCompanionBuilder =
    LocalSalesCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String?> customerId,
      Value<double> totalUsd,
      Value<double> totalLbp,
      Value<double> exchangeRateUsed,
      Value<String> paymentType,
      Value<DateTime> createdAt,
      Value<bool> synced,
      Value<String?> inventoryId,
      Value<int> rowid,
    });

class $$LocalSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalUsd => $composableBuilder(
    column: $table.totalUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalLbp => $composableBuilder(
    column: $table.totalLbp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRateUsed => $composableBuilder(
    column: $table.exchangeRateUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalUsd => $composableBuilder(
    column: $table.totalUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalLbp => $composableBuilder(
    column: $table.totalLbp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRateUsed => $composableBuilder(
    column: $table.exchangeRateUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalUsd =>
      $composableBuilder(column: $table.totalUsd, builder: (column) => column);

  GeneratedColumn<double> get totalLbp =>
      $composableBuilder(column: $table.totalLbp, builder: (column) => column);

  GeneratedColumn<double> get exchangeRateUsed => $composableBuilder(
    column: $table.exchangeRateUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => column,
  );
}

class $$LocalSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSalesTable,
          LocalSale,
          $$LocalSalesTableFilterComposer,
          $$LocalSalesTableOrderingComposer,
          $$LocalSalesTableAnnotationComposer,
          $$LocalSalesTableCreateCompanionBuilder,
          $$LocalSalesTableUpdateCompanionBuilder,
          (
            LocalSale,
            BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>,
          ),
          LocalSale,
          PrefetchHooks Function()
        > {
  $$LocalSalesTableTableManager(_$AppDatabase db, $LocalSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<double> totalUsd = const Value.absent(),
                Value<double> totalLbp = const Value.absent(),
                Value<double> exchangeRateUsed = const Value.absent(),
                Value<String> paymentType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> inventoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion(
                id: id,
                businessId: businessId,
                customerId: customerId,
                totalUsd: totalUsd,
                totalLbp: totalLbp,
                exchangeRateUsed: exchangeRateUsed,
                paymentType: paymentType,
                createdAt: createdAt,
                synced: synced,
                inventoryId: inventoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String?> customerId = const Value.absent(),
                required double totalUsd,
                required double totalLbp,
                required double exchangeRateUsed,
                required String paymentType,
                required DateTime createdAt,
                Value<bool> synced = const Value.absent(),
                Value<String?> inventoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion.insert(
                id: id,
                businessId: businessId,
                customerId: customerId,
                totalUsd: totalUsd,
                totalLbp: totalLbp,
                exchangeRateUsed: exchangeRateUsed,
                paymentType: paymentType,
                createdAt: createdAt,
                synced: synced,
                inventoryId: inventoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSalesTable, LocalSale>(table),
                  BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSalesTable,
      LocalSale,
      $$LocalSalesTableFilterComposer,
      $$LocalSalesTableOrderingComposer,
      $$LocalSalesTableAnnotationComposer,
      $$LocalSalesTableCreateCompanionBuilder,
      $$LocalSalesTableUpdateCompanionBuilder,
      (LocalSale, BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>),
      LocalSale,
      PrefetchHooks Function()
    >;
typedef $$LocalSaleItemsTableCreateCompanionBuilder =
    LocalSaleItemsCompanion Function({
      required String id,
      required String saleId,
      required String productId,
      required String productNameSnapshot,
      required int quantity,
      required double unitPriceUsd,
      required double subtotalUsd,
      Value<double?> costPriceUsdSnapshot,
      Value<int> rowid,
    });
typedef $$LocalSaleItemsTableUpdateCompanionBuilder =
    LocalSaleItemsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> productId,
      Value<String> productNameSnapshot,
      Value<int> quantity,
      Value<double> unitPriceUsd,
      Value<double> subtotalUsd,
      Value<double?> costPriceUsdSnapshot,
      Value<int> rowid,
    });

class $$LocalSaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPriceUsd => $composableBuilder(
    column: $table.unitPriceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotalUsd => $composableBuilder(
    column: $table.subtotalUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPriceUsdSnapshot => $composableBuilder(
    column: $table.costPriceUsdSnapshot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPriceUsd => $composableBuilder(
    column: $table.unitPriceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotalUsd => $composableBuilder(
    column: $table.subtotalUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPriceUsdSnapshot => $composableBuilder(
    column: $table.costPriceUsdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPriceUsd => $composableBuilder(
    column: $table.unitPriceUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotalUsd => $composableBuilder(
    column: $table.subtotalUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costPriceUsdSnapshot => $composableBuilder(
    column: $table.costPriceUsdSnapshot,
    builder: (column) => column,
  );
}

class $$LocalSaleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSaleItemsTable,
          LocalSaleItem,
          $$LocalSaleItemsTableFilterComposer,
          $$LocalSaleItemsTableOrderingComposer,
          $$LocalSaleItemsTableAnnotationComposer,
          $$LocalSaleItemsTableCreateCompanionBuilder,
          $$LocalSaleItemsTableUpdateCompanionBuilder,
          (
            LocalSaleItem,
            BaseReferences<_$AppDatabase, $LocalSaleItemsTable, LocalSaleItem>,
          ),
          LocalSaleItem,
          PrefetchHooks Function()
        > {
  $$LocalSaleItemsTableTableManager(
    _$AppDatabase db,
    $LocalSaleItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productNameSnapshot = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitPriceUsd = const Value.absent(),
                Value<double> subtotalUsd = const Value.absent(),
                Value<double?> costPriceUsdSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSaleItemsCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                quantity: quantity,
                unitPriceUsd: unitPriceUsd,
                subtotalUsd: subtotalUsd,
                costPriceUsdSnapshot: costPriceUsdSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String productId,
                required String productNameSnapshot,
                required int quantity,
                required double unitPriceUsd,
                required double subtotalUsd,
                Value<double?> costPriceUsdSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSaleItemsCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                quantity: quantity,
                unitPriceUsd: unitPriceUsd,
                subtotalUsd: subtotalUsd,
                costPriceUsdSnapshot: costPriceUsdSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSaleItemsTable, LocalSaleItem>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSaleItemsTable,
                    LocalSaleItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSaleItemsTable,
      LocalSaleItem,
      $$LocalSaleItemsTableFilterComposer,
      $$LocalSaleItemsTableOrderingComposer,
      $$LocalSaleItemsTableAnnotationComposer,
      $$LocalSaleItemsTableCreateCompanionBuilder,
      $$LocalSaleItemsTableUpdateCompanionBuilder,
      (
        LocalSaleItem,
        BaseReferences<_$AppDatabase, $LocalSaleItemsTable, LocalSaleItem>,
      ),
      LocalSaleItem,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoriesTableCreateCompanionBuilder =
    LocalInventoriesCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<bool> isArchived,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalInventoriesTableUpdateCompanionBuilder =
    LocalInventoriesCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalInventoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoriesTable> {
  $$LocalInventoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoriesTable> {
  $$LocalInventoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoriesTable> {
  $$LocalInventoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalInventoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoriesTable,
          LocalInventory,
          $$LocalInventoriesTableFilterComposer,
          $$LocalInventoriesTableOrderingComposer,
          $$LocalInventoriesTableAnnotationComposer,
          $$LocalInventoriesTableCreateCompanionBuilder,
          $$LocalInventoriesTableUpdateCompanionBuilder,
          (
            LocalInventory,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoriesTable,
              LocalInventory
            >,
          ),
          LocalInventory,
          PrefetchHooks Function()
        > {
  $$LocalInventoriesTableTableManager(
    _$AppDatabase db,
    $LocalInventoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalInventoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoriesCompanion(
                id: id,
                businessId: businessId,
                name: name,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoriesCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalInventoriesTable, LocalInventory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalInventoriesTable,
                    LocalInventory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoriesTable,
      LocalInventory,
      $$LocalInventoriesTableFilterComposer,
      $$LocalInventoriesTableOrderingComposer,
      $$LocalInventoriesTableAnnotationComposer,
      $$LocalInventoriesTableCreateCompanionBuilder,
      $$LocalInventoriesTableUpdateCompanionBuilder,
      (
        LocalInventory,
        BaseReferences<_$AppDatabase, $LocalInventoriesTable, LocalInventory>,
      ),
      LocalInventory,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryStockTableCreateCompanionBuilder =
    LocalInventoryStockCompanion Function({
      required String productId,
      required String inventoryId,
      Value<int> quantity,
      required double sellPriceUsd,
      required double costPriceUsd,
      Value<int> lowStockThreshold,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalInventoryStockTableUpdateCompanionBuilder =
    LocalInventoryStockCompanion Function({
      Value<String> productId,
      Value<String> inventoryId,
      Value<int> quantity,
      Value<double> sellPriceUsd,
      Value<double> costPriceUsd,
      Value<int> lowStockThreshold,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalInventoryStockTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoryStockTable> {
  $$LocalInventoryStockTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPriceUsd => $composableBuilder(
    column: $table.sellPriceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPriceUsd => $composableBuilder(
    column: $table.costPriceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryStockTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoryStockTable> {
  $$LocalInventoryStockTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPriceUsd => $composableBuilder(
    column: $table.sellPriceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPriceUsd => $composableBuilder(
    column: $table.costPriceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryStockTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoryStockTable> {
  $$LocalInventoryStockTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get sellPriceUsd => $composableBuilder(
    column: $table.sellPriceUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costPriceUsd => $composableBuilder(
    column: $table.costPriceUsd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalInventoryStockTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoryStockTable,
          LocalStockRow,
          $$LocalInventoryStockTableFilterComposer,
          $$LocalInventoryStockTableOrderingComposer,
          $$LocalInventoryStockTableAnnotationComposer,
          $$LocalInventoryStockTableCreateCompanionBuilder,
          $$LocalInventoryStockTableUpdateCompanionBuilder,
          (
            LocalStockRow,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoryStockTable,
              LocalStockRow
            >,
          ),
          LocalStockRow,
          PrefetchHooks Function()
        > {
  $$LocalInventoryStockTableTableManager(
    _$AppDatabase db,
    $LocalInventoryStockTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryStockTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoryStockTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryStockTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> inventoryId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> sellPriceUsd = const Value.absent(),
                Value<double> costPriceUsd = const Value.absent(),
                Value<int> lowStockThreshold = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryStockCompanion(
                productId: productId,
                inventoryId: inventoryId,
                quantity: quantity,
                sellPriceUsd: sellPriceUsd,
                costPriceUsd: costPriceUsd,
                lowStockThreshold: lowStockThreshold,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String inventoryId,
                Value<int> quantity = const Value.absent(),
                required double sellPriceUsd,
                required double costPriceUsd,
                Value<int> lowStockThreshold = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryStockCompanion.insert(
                productId: productId,
                inventoryId: inventoryId,
                quantity: quantity,
                sellPriceUsd: sellPriceUsd,
                costPriceUsd: costPriceUsd,
                lowStockThreshold: lowStockThreshold,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalInventoryStockTable, LocalStockRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalInventoryStockTable,
                    LocalStockRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryStockTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoryStockTable,
      LocalStockRow,
      $$LocalInventoryStockTableFilterComposer,
      $$LocalInventoryStockTableOrderingComposer,
      $$LocalInventoryStockTableAnnotationComposer,
      $$LocalInventoryStockTableCreateCompanionBuilder,
      $$LocalInventoryStockTableUpdateCompanionBuilder,
      (
        LocalStockRow,
        BaseReferences<_$AppDatabase, $LocalInventoryStockTable, LocalStockRow>,
      ),
      LocalStockRow,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryAccessTableCreateCompanionBuilder =
    LocalInventoryAccessCompanion Function({
      required String inventoryId,
      required String userId,
      Value<bool> canPos,
      Value<bool> canView,
      Value<bool> canEdit,
      Value<int> rowid,
    });
typedef $$LocalInventoryAccessTableUpdateCompanionBuilder =
    LocalInventoryAccessCompanion Function({
      Value<String> inventoryId,
      Value<String> userId,
      Value<bool> canPos,
      Value<bool> canView,
      Value<bool> canEdit,
      Value<int> rowid,
    });

class $$LocalInventoryAccessTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoryAccessTable> {
  $$LocalInventoryAccessTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canPos => $composableBuilder(
    column: $table.canPos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canView => $composableBuilder(
    column: $table.canView,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryAccessTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoryAccessTable> {
  $$LocalInventoryAccessTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canPos => $composableBuilder(
    column: $table.canPos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canView => $composableBuilder(
    column: $table.canView,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryAccessTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoryAccessTable> {
  $$LocalInventoryAccessTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get canPos =>
      $composableBuilder(column: $table.canPos, builder: (column) => column);

  GeneratedColumn<bool> get canView =>
      $composableBuilder(column: $table.canView, builder: (column) => column);

  GeneratedColumn<bool> get canEdit =>
      $composableBuilder(column: $table.canEdit, builder: (column) => column);
}

class $$LocalInventoryAccessTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoryAccessTable,
          LocalInventoryAccessRow,
          $$LocalInventoryAccessTableFilterComposer,
          $$LocalInventoryAccessTableOrderingComposer,
          $$LocalInventoryAccessTableAnnotationComposer,
          $$LocalInventoryAccessTableCreateCompanionBuilder,
          $$LocalInventoryAccessTableUpdateCompanionBuilder,
          (
            LocalInventoryAccessRow,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoryAccessTable,
              LocalInventoryAccessRow
            >,
          ),
          LocalInventoryAccessRow,
          PrefetchHooks Function()
        > {
  $$LocalInventoryAccessTableTableManager(
    _$AppDatabase db,
    $LocalInventoryAccessTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryAccessTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoryAccessTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryAccessTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> inventoryId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<bool> canPos = const Value.absent(),
                Value<bool> canView = const Value.absent(),
                Value<bool> canEdit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryAccessCompanion(
                inventoryId: inventoryId,
                userId: userId,
                canPos: canPos,
                canView: canView,
                canEdit: canEdit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String inventoryId,
                required String userId,
                Value<bool> canPos = const Value.absent(),
                Value<bool> canView = const Value.absent(),
                Value<bool> canEdit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryAccessCompanion.insert(
                inventoryId: inventoryId,
                userId: userId,
                canPos: canPos,
                canView: canView,
                canEdit: canEdit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalInventoryAccessTable,
                    LocalInventoryAccessRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalInventoryAccessTable,
                    LocalInventoryAccessRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryAccessTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoryAccessTable,
      LocalInventoryAccessRow,
      $$LocalInventoryAccessTableFilterComposer,
      $$LocalInventoryAccessTableOrderingComposer,
      $$LocalInventoryAccessTableAnnotationComposer,
      $$LocalInventoryAccessTableCreateCompanionBuilder,
      $$LocalInventoryAccessTableUpdateCompanionBuilder,
      (
        LocalInventoryAccessRow,
        BaseReferences<
          _$AppDatabase,
          $LocalInventoryAccessTable,
          LocalInventoryAccessRow
        >,
      ),
      LocalInventoryAccessRow,
      PrefetchHooks Function()
    >;
typedef $$LocalStockTransfersTableCreateCompanionBuilder =
    LocalStockTransfersCompanion Function({
      required String id,
      required String businessId,
      required String fromInventoryId,
      required String toInventoryId,
      Value<String?> createdBy,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalStockTransfersTableUpdateCompanionBuilder =
    LocalStockTransfersCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> fromInventoryId,
      Value<String> toInventoryId,
      Value<String?> createdBy,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalStockTransfersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockTransfersTable> {
  $$LocalStockTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromInventoryId => $composableBuilder(
    column: $table.fromInventoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toInventoryId => $composableBuilder(
    column: $table.toInventoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockTransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockTransfersTable> {
  $$LocalStockTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromInventoryId => $composableBuilder(
    column: $table.fromInventoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toInventoryId => $composableBuilder(
    column: $table.toInventoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockTransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockTransfersTable> {
  $$LocalStockTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromInventoryId => $composableBuilder(
    column: $table.fromInventoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toInventoryId => $composableBuilder(
    column: $table.toInventoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalStockTransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockTransfersTable,
          LocalStockTransfer,
          $$LocalStockTransfersTableFilterComposer,
          $$LocalStockTransfersTableOrderingComposer,
          $$LocalStockTransfersTableAnnotationComposer,
          $$LocalStockTransfersTableCreateCompanionBuilder,
          $$LocalStockTransfersTableUpdateCompanionBuilder,
          (
            LocalStockTransfer,
            BaseReferences<
              _$AppDatabase,
              $LocalStockTransfersTable,
              LocalStockTransfer
            >,
          ),
          LocalStockTransfer,
          PrefetchHooks Function()
        > {
  $$LocalStockTransfersTableTableManager(
    _$AppDatabase db,
    $LocalStockTransfersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStockTransfersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalStockTransfersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> fromInventoryId = const Value.absent(),
                Value<String> toInventoryId = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransfersCompanion(
                id: id,
                businessId: businessId,
                fromInventoryId: fromInventoryId,
                toInventoryId: toInventoryId,
                createdBy: createdBy,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String fromInventoryId,
                required String toInventoryId,
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransfersCompanion.insert(
                id: id,
                businessId: businessId,
                fromInventoryId: fromInventoryId,
                toInventoryId: toInventoryId,
                createdBy: createdBy,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalStockTransfersTable, LocalStockTransfer>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStockTransfersTable,
                    LocalStockTransfer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockTransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockTransfersTable,
      LocalStockTransfer,
      $$LocalStockTransfersTableFilterComposer,
      $$LocalStockTransfersTableOrderingComposer,
      $$LocalStockTransfersTableAnnotationComposer,
      $$LocalStockTransfersTableCreateCompanionBuilder,
      $$LocalStockTransfersTableUpdateCompanionBuilder,
      (
        LocalStockTransfer,
        BaseReferences<
          _$AppDatabase,
          $LocalStockTransfersTable,
          LocalStockTransfer
        >,
      ),
      LocalStockTransfer,
      PrefetchHooks Function()
    >;
typedef $$LocalStockTransferItemsTableCreateCompanionBuilder =
    LocalStockTransferItemsCompanion Function({
      required String id,
      required String transferId,
      Value<String?> productId,
      required int quantity,
      required String productNameSnapshot,
      Value<int> rowid,
    });
typedef $$LocalStockTransferItemsTableUpdateCompanionBuilder =
    LocalStockTransferItemsCompanion Function({
      Value<String> id,
      Value<String> transferId,
      Value<String?> productId,
      Value<int> quantity,
      Value<String> productNameSnapshot,
      Value<int> rowid,
    });

class $$LocalStockTransferItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockTransferItemsTable> {
  $$LocalStockTransferItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockTransferItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockTransferItemsTable> {
  $$LocalStockTransferItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockTransferItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockTransferItemsTable> {
  $$LocalStockTransferItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );
}

class $$LocalStockTransferItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockTransferItemsTable,
          LocalStockTransferItem,
          $$LocalStockTransferItemsTableFilterComposer,
          $$LocalStockTransferItemsTableOrderingComposer,
          $$LocalStockTransferItemsTableAnnotationComposer,
          $$LocalStockTransferItemsTableCreateCompanionBuilder,
          $$LocalStockTransferItemsTableUpdateCompanionBuilder,
          (
            LocalStockTransferItem,
            BaseReferences<
              _$AppDatabase,
              $LocalStockTransferItemsTable,
              LocalStockTransferItem
            >,
          ),
          LocalStockTransferItem,
          PrefetchHooks Function()
        > {
  $$LocalStockTransferItemsTableTableManager(
    _$AppDatabase db,
    $LocalStockTransferItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockTransferItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalStockTransferItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalStockTransferItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transferId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> productNameSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransferItemsCompanion(
                id: id,
                transferId: transferId,
                productId: productId,
                quantity: quantity,
                productNameSnapshot: productNameSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transferId,
                Value<String?> productId = const Value.absent(),
                required int quantity,
                required String productNameSnapshot,
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransferItemsCompanion.insert(
                id: id,
                transferId: transferId,
                productId: productId,
                quantity: quantity,
                productNameSnapshot: productNameSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalStockTransferItemsTable,
                    LocalStockTransferItem
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStockTransferItemsTable,
                    LocalStockTransferItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockTransferItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockTransferItemsTable,
      LocalStockTransferItem,
      $$LocalStockTransferItemsTableFilterComposer,
      $$LocalStockTransferItemsTableOrderingComposer,
      $$LocalStockTransferItemsTableAnnotationComposer,
      $$LocalStockTransferItemsTableCreateCompanionBuilder,
      $$LocalStockTransferItemsTableUpdateCompanionBuilder,
      (
        LocalStockTransferItem,
        BaseReferences<
          _$AppDatabase,
          $LocalStockTransferItemsTable,
          LocalStockTransferItem
        >,
      ),
      LocalStockTransferItem,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueEntriesTableCreateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      required String id,
      required String operationType,
      required String payloadJson,
      Value<String> status,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncQueueEntriesTableUpdateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      Value<String> id,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueEntriesTable,
          SyncQueueEntry,
          $$SyncQueueEntriesTableFilterComposer,
          $$SyncQueueEntriesTableOrderingComposer,
          $$SyncQueueEntriesTableAnnotationComposer,
          $$SyncQueueEntriesTableCreateCompanionBuilder,
          $$SyncQueueEntriesTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueEntriesTable,
              SyncQueueEntry
            >,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueEntriesTableTableManager(
    _$AppDatabase db,
    $SyncQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueEntriesCompanion(
                id: id,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationType,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueEntriesCompanion.insert(
                id: id,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueEntriesTable, SyncQueueEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueEntriesTable,
                    SyncQueueEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueEntriesTable,
      SyncQueueEntry,
      $$SyncQueueEntriesTableFilterComposer,
      $$SyncQueueEntriesTableOrderingComposer,
      $$SyncQueueEntriesTableAnnotationComposer,
      $$SyncQueueEntriesTableCreateCompanionBuilder,
      $$SyncQueueEntriesTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueEntriesTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataEntriesTableCreateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      required String businessId,
      required DateTime lastPullAt,
      Value<int> rowid,
    });
typedef $$SyncMetadataEntriesTableUpdateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      Value<String> businessId,
      Value<DateTime> lastPullAt,
      Value<int> rowid,
    });

class $$SyncMetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );
}

class $$SyncMetadataEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry,
          $$SyncMetadataEntriesTableFilterComposer,
          $$SyncMetadataEntriesTableOrderingComposer,
          $$SyncMetadataEntriesTableAnnotationComposer,
          $$SyncMetadataEntriesTableCreateCompanionBuilder,
          $$SyncMetadataEntriesTableUpdateCompanionBuilder,
          (
            SyncMetadataEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataEntriesTable,
              SyncMetadataEntry
            >,
          ),
          SyncMetadataEntry,
          PrefetchHooks Function()
        > {
  $$SyncMetadataEntriesTableTableManager(
    _$AppDatabase db,
    $SyncMetadataEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncMetadataEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<DateTime> lastPullAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion(
                businessId: businessId,
                lastPullAt: lastPullAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required DateTime lastPullAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion.insert(
                businessId: businessId,
                lastPullAt: lastPullAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetadataEntriesTable, SyncMetadataEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncMetadataEntriesTable,
                    SyncMetadataEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataEntriesTable,
      SyncMetadataEntry,
      $$SyncMetadataEntriesTableFilterComposer,
      $$SyncMetadataEntriesTableOrderingComposer,
      $$SyncMetadataEntriesTableAnnotationComposer,
      $$SyncMetadataEntriesTableCreateCompanionBuilder,
      $$SyncMetadataEntriesTableUpdateCompanionBuilder,
      (
        SyncMetadataEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry
        >,
      ),
      SyncMetadataEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalCustomersTableTableManager get localCustomers =>
      $$LocalCustomersTableTableManager(_db, _db.localCustomers);
  $$LocalSalesTableTableManager get localSales =>
      $$LocalSalesTableTableManager(_db, _db.localSales);
  $$LocalSaleItemsTableTableManager get localSaleItems =>
      $$LocalSaleItemsTableTableManager(_db, _db.localSaleItems);
  $$LocalInventoriesTableTableManager get localInventories =>
      $$LocalInventoriesTableTableManager(_db, _db.localInventories);
  $$LocalInventoryStockTableTableManager get localInventoryStock =>
      $$LocalInventoryStockTableTableManager(_db, _db.localInventoryStock);
  $$LocalInventoryAccessTableTableManager get localInventoryAccess =>
      $$LocalInventoryAccessTableTableManager(_db, _db.localInventoryAccess);
  $$LocalStockTransfersTableTableManager get localStockTransfers =>
      $$LocalStockTransfersTableTableManager(_db, _db.localStockTransfers);
  $$LocalStockTransferItemsTableTableManager get localStockTransferItems =>
      $$LocalStockTransferItemsTableTableManager(
        _db,
        _db.localStockTransferItems,
      );
  $$SyncQueueEntriesTableTableManager get syncQueueEntries =>
      $$SyncQueueEntriesTableTableManager(_db, _db.syncQueueEntries);
  $$SyncMetadataEntriesTableTableManager get syncMetadataEntries =>
      $$SyncMetadataEntriesTableTableManager(_db, _db.syncMetadataEntries);
}
