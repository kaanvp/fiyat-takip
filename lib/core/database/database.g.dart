// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductGroupsTable extends ProductGroups
    with TableInfo<$ProductGroupsTable, ProductGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $ProductGroupsTable createAlias(String alias) {
    return $ProductGroupsTable(attachedDatabase, alias);
  }
}

class ProductGroup extends DataClass implements Insertable<ProductGroup> {
  final String id;
  final String name;
  const ProductGroup({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  ProductGroupsCompanion toCompanion(bool nullToAbsent) {
    return ProductGroupsCompanion(id: Value(id), name: Value(name));
  }

  factory ProductGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  ProductGroup copyWith({String? id, String? name}) =>
      ProductGroup(id: id ?? this.id, name: name ?? this.name);
  ProductGroup copyWithCompanion(ProductGroupsCompanion data) {
    return ProductGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductGroup(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductGroup && other.id == this.id && other.name == this.name);
}

class ProductGroupsCompanion extends UpdateCompanion<ProductGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const ProductGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductGroupsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ProductGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return ProductGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productUrlMeta = const VerificationMeta(
    'productUrl',
  );
  @override
  late final GeneratedColumn<String> productUrl = GeneratedColumn<String>(
    'product_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteHostMeta = const VerificationMeta(
    'siteHost',
  );
  @override
  late final GeneratedColumn<String> siteHost = GeneratedColumn<String>(
    'site_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteDisplayNameMeta = const VerificationMeta(
    'siteDisplayName',
  );
  @override
  late final GeneratedColumn<String> siteDisplayName = GeneratedColumn<String>(
    'site_display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialPriceMeta = const VerificationMeta(
    'initialPrice',
  );
  @override
  late final GeneratedColumn<double> initialPrice = GeneratedColumn<double>(
    'initial_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<double> currentPrice = GeneratedColumn<double>(
    'current_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('TRY'),
  );
  static const VerificationMeta _targetPriceMeta = const VerificationMeta(
    'targetPrice',
  );
  @override
  late final GeneratedColumn<double> targetPrice = GeneratedColumn<double>(
    'target_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>(
        'last_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<CheckStatus, String>
  lastCheckStatus = GeneratedColumn<String>(
    'last_check_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CheckStatus>($ProductsTable.$converterlastCheckStatus);
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ProductsTable.$convertertags);
  static const VerificationMeta _notifyThresholdPercentMeta =
      const VerificationMeta('notifyThresholdPercent');
  @override
  late final GeneratedColumn<int> notifyThresholdPercent = GeneratedColumn<int>(
    'notify_threshold_percent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES product_groups (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    imageUrl,
    productUrl,
    siteHost,
    siteDisplayName,
    initialPrice,
    currentPrice,
    currency,
    targetPrice,
    addedAt,
    lastCheckedAt,
    lastCheckStatus,
    isArchived,
    notes,
    tags,
    notifyThresholdPercent,
    groupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('product_url')) {
      context.handle(
        _productUrlMeta,
        productUrl.isAcceptableOrUnknown(data['product_url']!, _productUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_productUrlMeta);
    }
    if (data.containsKey('site_host')) {
      context.handle(
        _siteHostMeta,
        siteHost.isAcceptableOrUnknown(data['site_host']!, _siteHostMeta),
      );
    } else if (isInserting) {
      context.missing(_siteHostMeta);
    }
    if (data.containsKey('site_display_name')) {
      context.handle(
        _siteDisplayNameMeta,
        siteDisplayName.isAcceptableOrUnknown(
          data['site_display_name']!,
          _siteDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_siteDisplayNameMeta);
    }
    if (data.containsKey('initial_price')) {
      context.handle(
        _initialPriceMeta,
        initialPrice.isAcceptableOrUnknown(
          data['initial_price']!,
          _initialPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialPriceMeta);
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentPriceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('target_price')) {
      context.handle(
        _targetPriceMeta,
        targetPrice.isAcceptableOrUnknown(
          data['target_price']!,
          _targetPriceMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('notify_threshold_percent')) {
      context.handle(
        _notifyThresholdPercentMeta,
        notifyThresholdPercent.isAcceptableOrUnknown(
          data['notify_threshold_percent']!,
          _notifyThresholdPercentMeta,
        ),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      productUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_url'],
      )!,
      siteHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_host'],
      )!,
      siteDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_display_name'],
      )!,
      initialPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_price'],
      )!,
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_price'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      targetPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_price'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      ),
      lastCheckStatus: $ProductsTable.$converterlastCheckStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_check_status'],
        )!,
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      tags: $ProductsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      notifyThresholdPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notify_threshold_percent'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }

  static TypeConverter<CheckStatus, String> $converterlastCheckStatus =
      const CheckStatusConverter();
  static TypeConverter<List<String>, String> $convertertags =
      const TagsConverter();
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String name;
  final String? imageUrl;
  final String productUrl;
  final String siteHost;
  final String siteDisplayName;
  final double initialPrice;
  final double currentPrice;
  final String currency;
  final double? targetPrice;
  final DateTime addedAt;
  final DateTime? lastCheckedAt;
  final CheckStatus lastCheckStatus;
  final bool isArchived;
  final String? notes;
  final List<String> tags;
  final int? notifyThresholdPercent;
  final String? groupId;
  const Product({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.productUrl,
    required this.siteHost,
    required this.siteDisplayName,
    required this.initialPrice,
    required this.currentPrice,
    required this.currency,
    this.targetPrice,
    required this.addedAt,
    this.lastCheckedAt,
    required this.lastCheckStatus,
    required this.isArchived,
    this.notes,
    required this.tags,
    this.notifyThresholdPercent,
    this.groupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['product_url'] = Variable<String>(productUrl);
    map['site_host'] = Variable<String>(siteHost);
    map['site_display_name'] = Variable<String>(siteDisplayName);
    map['initial_price'] = Variable<double>(initialPrice);
    map['current_price'] = Variable<double>(currentPrice);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || targetPrice != null) {
      map['target_price'] = Variable<double>(targetPrice);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    {
      map['last_check_status'] = Variable<String>(
        $ProductsTable.$converterlastCheckStatus.toSql(lastCheckStatus),
      );
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['tags'] = Variable<String>($ProductsTable.$convertertags.toSql(tags));
    }
    if (!nullToAbsent || notifyThresholdPercent != null) {
      map['notify_threshold_percent'] = Variable<int>(notifyThresholdPercent);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      productUrl: Value(productUrl),
      siteHost: Value(siteHost),
      siteDisplayName: Value(siteDisplayName),
      initialPrice: Value(initialPrice),
      currentPrice: Value(currentPrice),
      currency: Value(currency),
      targetPrice: targetPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPrice),
      addedAt: Value(addedAt),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      lastCheckStatus: Value(lastCheckStatus),
      isArchived: Value(isArchived),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      tags: Value(tags),
      notifyThresholdPercent: notifyThresholdPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(notifyThresholdPercent),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      productUrl: serializer.fromJson<String>(json['productUrl']),
      siteHost: serializer.fromJson<String>(json['siteHost']),
      siteDisplayName: serializer.fromJson<String>(json['siteDisplayName']),
      initialPrice: serializer.fromJson<double>(json['initialPrice']),
      currentPrice: serializer.fromJson<double>(json['currentPrice']),
      currency: serializer.fromJson<String>(json['currency']),
      targetPrice: serializer.fromJson<double?>(json['targetPrice']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
      lastCheckStatus: serializer.fromJson<CheckStatus>(
        json['lastCheckStatus'],
      ),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      notes: serializer.fromJson<String?>(json['notes']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      notifyThresholdPercent: serializer.fromJson<int?>(
        json['notifyThresholdPercent'],
      ),
      groupId: serializer.fromJson<String?>(json['groupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'productUrl': serializer.toJson<String>(productUrl),
      'siteHost': serializer.toJson<String>(siteHost),
      'siteDisplayName': serializer.toJson<String>(siteDisplayName),
      'initialPrice': serializer.toJson<double>(initialPrice),
      'currentPrice': serializer.toJson<double>(currentPrice),
      'currency': serializer.toJson<String>(currency),
      'targetPrice': serializer.toJson<double?>(targetPrice),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
      'lastCheckStatus': serializer.toJson<CheckStatus>(lastCheckStatus),
      'isArchived': serializer.toJson<bool>(isArchived),
      'notes': serializer.toJson<String?>(notes),
      'tags': serializer.toJson<List<String>>(tags),
      'notifyThresholdPercent': serializer.toJson<int?>(notifyThresholdPercent),
      'groupId': serializer.toJson<String?>(groupId),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    String? productUrl,
    String? siteHost,
    String? siteDisplayName,
    double? initialPrice,
    double? currentPrice,
    String? currency,
    Value<double?> targetPrice = const Value.absent(),
    DateTime? addedAt,
    Value<DateTime?> lastCheckedAt = const Value.absent(),
    CheckStatus? lastCheckStatus,
    bool? isArchived,
    Value<String?> notes = const Value.absent(),
    List<String>? tags,
    Value<int?> notifyThresholdPercent = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    productUrl: productUrl ?? this.productUrl,
    siteHost: siteHost ?? this.siteHost,
    siteDisplayName: siteDisplayName ?? this.siteDisplayName,
    initialPrice: initialPrice ?? this.initialPrice,
    currentPrice: currentPrice ?? this.currentPrice,
    currency: currency ?? this.currency,
    targetPrice: targetPrice.present ? targetPrice.value : this.targetPrice,
    addedAt: addedAt ?? this.addedAt,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
    lastCheckStatus: lastCheckStatus ?? this.lastCheckStatus,
    isArchived: isArchived ?? this.isArchived,
    notes: notes.present ? notes.value : this.notes,
    tags: tags ?? this.tags,
    notifyThresholdPercent: notifyThresholdPercent.present
        ? notifyThresholdPercent.value
        : this.notifyThresholdPercent,
    groupId: groupId.present ? groupId.value : this.groupId,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      productUrl: data.productUrl.present
          ? data.productUrl.value
          : this.productUrl,
      siteHost: data.siteHost.present ? data.siteHost.value : this.siteHost,
      siteDisplayName: data.siteDisplayName.present
          ? data.siteDisplayName.value
          : this.siteDisplayName,
      initialPrice: data.initialPrice.present
          ? data.initialPrice.value
          : this.initialPrice,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      currency: data.currency.present ? data.currency.value : this.currency,
      targetPrice: data.targetPrice.present
          ? data.targetPrice.value
          : this.targetPrice,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      lastCheckStatus: data.lastCheckStatus.present
          ? data.lastCheckStatus.value
          : this.lastCheckStatus,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      notes: data.notes.present ? data.notes.value : this.notes,
      tags: data.tags.present ? data.tags.value : this.tags,
      notifyThresholdPercent: data.notifyThresholdPercent.present
          ? data.notifyThresholdPercent.value
          : this.notifyThresholdPercent,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('productUrl: $productUrl, ')
          ..write('siteHost: $siteHost, ')
          ..write('siteDisplayName: $siteDisplayName, ')
          ..write('initialPrice: $initialPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('currency: $currency, ')
          ..write('targetPrice: $targetPrice, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('lastCheckStatus: $lastCheckStatus, ')
          ..write('isArchived: $isArchived, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('notifyThresholdPercent: $notifyThresholdPercent, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    imageUrl,
    productUrl,
    siteHost,
    siteDisplayName,
    initialPrice,
    currentPrice,
    currency,
    targetPrice,
    addedAt,
    lastCheckedAt,
    lastCheckStatus,
    isArchived,
    notes,
    tags,
    notifyThresholdPercent,
    groupId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.productUrl == this.productUrl &&
          other.siteHost == this.siteHost &&
          other.siteDisplayName == this.siteDisplayName &&
          other.initialPrice == this.initialPrice &&
          other.currentPrice == this.currentPrice &&
          other.currency == this.currency &&
          other.targetPrice == this.targetPrice &&
          other.addedAt == this.addedAt &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.lastCheckStatus == this.lastCheckStatus &&
          other.isArchived == this.isArchived &&
          other.notes == this.notes &&
          other.tags == this.tags &&
          other.notifyThresholdPercent == this.notifyThresholdPercent &&
          other.groupId == this.groupId);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<String> productUrl;
  final Value<String> siteHost;
  final Value<String> siteDisplayName;
  final Value<double> initialPrice;
  final Value<double> currentPrice;
  final Value<String> currency;
  final Value<double?> targetPrice;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastCheckedAt;
  final Value<CheckStatus> lastCheckStatus;
  final Value<bool> isArchived;
  final Value<String?> notes;
  final Value<List<String>> tags;
  final Value<int?> notifyThresholdPercent;
  final Value<String?> groupId;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.productUrl = const Value.absent(),
    this.siteHost = const Value.absent(),
    this.siteDisplayName = const Value.absent(),
    this.initialPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.targetPrice = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.lastCheckStatus = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.notes = const Value.absent(),
    this.tags = const Value.absent(),
    this.notifyThresholdPercent = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.imageUrl = const Value.absent(),
    required String productUrl,
    required String siteHost,
    required String siteDisplayName,
    required double initialPrice,
    required double currentPrice,
    this.currency = const Value.absent(),
    this.targetPrice = const Value.absent(),
    required DateTime addedAt,
    this.lastCheckedAt = const Value.absent(),
    required CheckStatus lastCheckStatus,
    this.isArchived = const Value.absent(),
    this.notes = const Value.absent(),
    required List<String> tags,
    this.notifyThresholdPercent = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       productUrl = Value(productUrl),
       siteHost = Value(siteHost),
       siteDisplayName = Value(siteDisplayName),
       initialPrice = Value(initialPrice),
       currentPrice = Value(currentPrice),
       addedAt = Value(addedAt),
       lastCheckStatus = Value(lastCheckStatus),
       tags = Value(tags);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<String>? productUrl,
    Expression<String>? siteHost,
    Expression<String>? siteDisplayName,
    Expression<double>? initialPrice,
    Expression<double>? currentPrice,
    Expression<String>? currency,
    Expression<double>? targetPrice,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastCheckedAt,
    Expression<String>? lastCheckStatus,
    Expression<bool>? isArchived,
    Expression<String>? notes,
    Expression<String>? tags,
    Expression<int>? notifyThresholdPercent,
    Expression<String>? groupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (productUrl != null) 'product_url': productUrl,
      if (siteHost != null) 'site_host': siteHost,
      if (siteDisplayName != null) 'site_display_name': siteDisplayName,
      if (initialPrice != null) 'initial_price': initialPrice,
      if (currentPrice != null) 'current_price': currentPrice,
      if (currency != null) 'currency': currency,
      if (targetPrice != null) 'target_price': targetPrice,
      if (addedAt != null) 'added_at': addedAt,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (lastCheckStatus != null) 'last_check_status': lastCheckStatus,
      if (isArchived != null) 'is_archived': isArchived,
      if (notes != null) 'notes': notes,
      if (tags != null) 'tags': tags,
      if (notifyThresholdPercent != null)
        'notify_threshold_percent': notifyThresholdPercent,
      if (groupId != null) 'group_id': groupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<String>? productUrl,
    Value<String>? siteHost,
    Value<String>? siteDisplayName,
    Value<double>? initialPrice,
    Value<double>? currentPrice,
    Value<String>? currency,
    Value<double?>? targetPrice,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastCheckedAt,
    Value<CheckStatus>? lastCheckStatus,
    Value<bool>? isArchived,
    Value<String?>? notes,
    Value<List<String>>? tags,
    Value<int?>? notifyThresholdPercent,
    Value<String?>? groupId,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      productUrl: productUrl ?? this.productUrl,
      siteHost: siteHost ?? this.siteHost,
      siteDisplayName: siteDisplayName ?? this.siteDisplayName,
      initialPrice: initialPrice ?? this.initialPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      currency: currency ?? this.currency,
      targetPrice: targetPrice ?? this.targetPrice,
      addedAt: addedAt ?? this.addedAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastCheckStatus: lastCheckStatus ?? this.lastCheckStatus,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      notifyThresholdPercent:
          notifyThresholdPercent ?? this.notifyThresholdPercent,
      groupId: groupId ?? this.groupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (productUrl.present) {
      map['product_url'] = Variable<String>(productUrl.value);
    }
    if (siteHost.present) {
      map['site_host'] = Variable<String>(siteHost.value);
    }
    if (siteDisplayName.present) {
      map['site_display_name'] = Variable<String>(siteDisplayName.value);
    }
    if (initialPrice.present) {
      map['initial_price'] = Variable<double>(initialPrice.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<double>(currentPrice.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (targetPrice.present) {
      map['target_price'] = Variable<double>(targetPrice.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    if (lastCheckStatus.present) {
      map['last_check_status'] = Variable<String>(
        $ProductsTable.$converterlastCheckStatus.toSql(lastCheckStatus.value),
      );
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $ProductsTable.$convertertags.toSql(tags.value),
      );
    }
    if (notifyThresholdPercent.present) {
      map['notify_threshold_percent'] = Variable<int>(
        notifyThresholdPercent.value,
      );
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('productUrl: $productUrl, ')
          ..write('siteHost: $siteHost, ')
          ..write('siteDisplayName: $siteDisplayName, ')
          ..write('initialPrice: $initialPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('currency: $currency, ')
          ..write('targetPrice: $targetPrice, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('lastCheckStatus: $lastCheckStatus, ')
          ..write('isArchived: $isArchived, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('notifyThresholdPercent: $notifyThresholdPercent, ')
          ..write('groupId: $groupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceHistoryEntriesTable extends PriceHistoryEntries
    with TableInfo<$PriceHistoryEntriesTable, PriceHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkedAt = GeneratedColumn<DateTime>(
    'checked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, productId, price, checkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_checkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_at'],
      )!,
    );
  }

  @override
  $PriceHistoryEntriesTable createAlias(String alias) {
    return $PriceHistoryEntriesTable(attachedDatabase, alias);
  }
}

class PriceHistoryEntry extends DataClass
    implements Insertable<PriceHistoryEntry> {
  final String id;
  final String productId;
  final double price;
  final DateTime checkedAt;
  const PriceHistoryEntry({
    required this.id,
    required this.productId,
    required this.price,
    required this.checkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['price'] = Variable<double>(price);
    map['checked_at'] = Variable<DateTime>(checkedAt);
    return map;
  }

  PriceHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return PriceHistoryEntriesCompanion(
      id: Value(id),
      productId: Value(productId),
      price: Value(price),
      checkedAt: Value(checkedAt),
    );
  }

  factory PriceHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceHistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      price: serializer.fromJson<double>(json['price']),
      checkedAt: serializer.fromJson<DateTime>(json['checkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'price': serializer.toJson<double>(price),
      'checkedAt': serializer.toJson<DateTime>(checkedAt),
    };
  }

  PriceHistoryEntry copyWith({
    String? id,
    String? productId,
    double? price,
    DateTime? checkedAt,
  }) => PriceHistoryEntry(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    price: price ?? this.price,
    checkedAt: checkedAt ?? this.checkedAt,
  );
  PriceHistoryEntry copyWithCompanion(PriceHistoryEntriesCompanion data) {
    return PriceHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      price: data.price.present ? data.price.value : this.price,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryEntry(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('price: $price, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, price, checkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceHistoryEntry &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.price == this.price &&
          other.checkedAt == this.checkedAt);
}

class PriceHistoryEntriesCompanion extends UpdateCompanion<PriceHistoryEntry> {
  final Value<String> id;
  final Value<String> productId;
  final Value<double> price;
  final Value<DateTime> checkedAt;
  final Value<int> rowid;
  const PriceHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.price = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceHistoryEntriesCompanion.insert({
    required String id,
    required String productId,
    required double price,
    required DateTime checkedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       price = Value(price),
       checkedAt = Value(checkedAt);
  static Insertable<PriceHistoryEntry> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<double>? price,
    Expression<DateTime>? checkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (price != null) 'price': price,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceHistoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<double>? price,
    Value<DateTime>? checkedAt,
    Value<int>? rowid,
  }) {
    return PriceHistoryEntriesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      price: price ?? this.price,
      checkedAt: checkedAt ?? this.checkedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<DateTime>(checkedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('price: $price, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductGroupsTable productGroups = $ProductGroupsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $PriceHistoryEntriesTable priceHistoryEntries =
      $PriceHistoryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productGroups,
    products,
    priceHistoryEntries,
  ];
}

typedef $$ProductGroupsTableCreateCompanionBuilder =
    ProductGroupsCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$ProductGroupsTableUpdateCompanionBuilder =
    ProductGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$ProductGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductGroupsTable, ProductGroup> {
  $$ProductGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProductsTable, List<Product>> _productsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: $_aliasNameGenerator(db.productGroups.id, db.products.groupId),
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductGroupsTable> {
  $$ProductGroupsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductGroupsTable> {
  $$ProductGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductGroupsTable> {
  $$ProductGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductGroupsTable,
          ProductGroup,
          $$ProductGroupsTableFilterComposer,
          $$ProductGroupsTableOrderingComposer,
          $$ProductGroupsTableAnnotationComposer,
          $$ProductGroupsTableCreateCompanionBuilder,
          $$ProductGroupsTableUpdateCompanionBuilder,
          (ProductGroup, $$ProductGroupsTableReferences),
          ProductGroup,
          PrefetchHooks Function({bool productsRefs})
        > {
  $$ProductGroupsTableTableManager(_$AppDatabase db, $ProductGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductGroupsCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => ProductGroupsCompanion.insert(
                id: id,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<
                      ProductGroup,
                      $ProductGroupsTable,
                      Product
                    >(
                      currentTable: table,
                      referencedTable: $$ProductGroupsTableReferences
                          ._productsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProductGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).productsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductGroupsTable,
      ProductGroup,
      $$ProductGroupsTableFilterComposer,
      $$ProductGroupsTableOrderingComposer,
      $$ProductGroupsTableAnnotationComposer,
      $$ProductGroupsTableCreateCompanionBuilder,
      $$ProductGroupsTableUpdateCompanionBuilder,
      (ProductGroup, $$ProductGroupsTableReferences),
      ProductGroup,
      PrefetchHooks Function({bool productsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> imageUrl,
      required String productUrl,
      required String siteHost,
      required String siteDisplayName,
      required double initialPrice,
      required double currentPrice,
      Value<String> currency,
      Value<double?> targetPrice,
      required DateTime addedAt,
      Value<DateTime?> lastCheckedAt,
      required CheckStatus lastCheckStatus,
      Value<bool> isArchived,
      Value<String?> notes,
      required List<String> tags,
      Value<int?> notifyThresholdPercent,
      Value<String?> groupId,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> imageUrl,
      Value<String> productUrl,
      Value<String> siteHost,
      Value<String> siteDisplayName,
      Value<double> initialPrice,
      Value<double> currentPrice,
      Value<String> currency,
      Value<double?> targetPrice,
      Value<DateTime> addedAt,
      Value<DateTime?> lastCheckedAt,
      Value<CheckStatus> lastCheckStatus,
      Value<bool> isArchived,
      Value<String?> notes,
      Value<List<String>> tags,
      Value<int?> notifyThresholdPercent,
      Value<String?> groupId,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductGroupsTable _groupIdTable(_$AppDatabase db) =>
      db.productGroups.createAlias(
        $_aliasNameGenerator(db.products.groupId, db.productGroups.id),
      );

  $$ProductGroupsTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<String>('group_id');
    if ($_column == null) return null;
    final manager = $$ProductGroupsTableTableManager(
      $_db,
      $_db.productGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PriceHistoryEntriesTable, List<PriceHistoryEntry>>
  _priceHistoryEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.priceHistoryEntries,
        aliasName: $_aliasNameGenerator(
          db.products.id,
          db.priceHistoryEntries.productId,
        ),
      );

  $$PriceHistoryEntriesTableProcessedTableManager get priceHistoryEntriesRefs {
    final manager = $$PriceHistoryEntriesTableTableManager(
      $_db,
      $_db.priceHistoryEntries,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _priceHistoryEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productUrl => $composableBuilder(
    column: $table.productUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteHost => $composableBuilder(
    column: $table.siteHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteDisplayName => $composableBuilder(
    column: $table.siteDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialPrice => $composableBuilder(
    column: $table.initialPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CheckStatus, CheckStatus, String>
  get lastCheckStatus => $composableBuilder(
    column: $table.lastCheckStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get notifyThresholdPercent => $composableBuilder(
    column: $table.notifyThresholdPercent,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductGroupsTableFilterComposer get groupId {
    final $$ProductGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.productGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductGroupsTableFilterComposer(
            $db: $db,
            $table: $db.productGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> priceHistoryEntriesRefs(
    Expression<bool> Function($$PriceHistoryEntriesTableFilterComposer f) f,
  ) {
    final $$PriceHistoryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistoryEntries,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.priceHistoryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productUrl => $composableBuilder(
    column: $table.productUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteHost => $composableBuilder(
    column: $table.siteHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteDisplayName => $composableBuilder(
    column: $table.siteDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialPrice => $composableBuilder(
    column: $table.initialPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCheckStatus => $composableBuilder(
    column: $table.lastCheckStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notifyThresholdPercent => $composableBuilder(
    column: $table.notifyThresholdPercent,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductGroupsTableOrderingComposer get groupId {
    final $$ProductGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.productGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.productGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get productUrl => $composableBuilder(
    column: $table.productUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siteHost =>
      $composableBuilder(column: $table.siteHost, builder: (column) => column);

  GeneratedColumn<String> get siteDisplayName => $composableBuilder(
    column: $table.siteDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialPrice => $composableBuilder(
    column: $table.initialPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CheckStatus, String> get lastCheckStatus =>
      $composableBuilder(
        column: $table.lastCheckStatus,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get notifyThresholdPercent => $composableBuilder(
    column: $table.notifyThresholdPercent,
    builder: (column) => column,
  );

  $$ProductGroupsTableAnnotationComposer get groupId {
    final $$ProductGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.productGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.productGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> priceHistoryEntriesRefs<T extends Object>(
    Expression<T> Function($$PriceHistoryEntriesTableAnnotationComposer a) f,
  ) {
    final $$PriceHistoryEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.priceHistoryEntries,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PriceHistoryEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.priceHistoryEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool groupId, bool priceHistoryEntriesRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> productUrl = const Value.absent(),
                Value<String> siteHost = const Value.absent(),
                Value<String> siteDisplayName = const Value.absent(),
                Value<double> initialPrice = const Value.absent(),
                Value<double> currentPrice = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double?> targetPrice = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<CheckStatus> lastCheckStatus = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<int?> notifyThresholdPercent = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                imageUrl: imageUrl,
                productUrl: productUrl,
                siteHost: siteHost,
                siteDisplayName: siteDisplayName,
                initialPrice: initialPrice,
                currentPrice: currentPrice,
                currency: currency,
                targetPrice: targetPrice,
                addedAt: addedAt,
                lastCheckedAt: lastCheckedAt,
                lastCheckStatus: lastCheckStatus,
                isArchived: isArchived,
                notes: notes,
                tags: tags,
                notifyThresholdPercent: notifyThresholdPercent,
                groupId: groupId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                required String productUrl,
                required String siteHost,
                required String siteDisplayName,
                required double initialPrice,
                required double currentPrice,
                Value<String> currency = const Value.absent(),
                Value<double?> targetPrice = const Value.absent(),
                required DateTime addedAt,
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                required CheckStatus lastCheckStatus,
                Value<bool> isArchived = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required List<String> tags,
                Value<int?> notifyThresholdPercent = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                imageUrl: imageUrl,
                productUrl: productUrl,
                siteHost: siteHost,
                siteDisplayName: siteDisplayName,
                initialPrice: initialPrice,
                currentPrice: currentPrice,
                currency: currency,
                targetPrice: targetPrice,
                addedAt: addedAt,
                lastCheckedAt: lastCheckedAt,
                lastCheckStatus: lastCheckStatus,
                isArchived: isArchived,
                notes: notes,
                tags: tags,
                notifyThresholdPercent: notifyThresholdPercent,
                groupId: groupId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, priceHistoryEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (priceHistoryEntriesRefs) db.priceHistoryEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$ProductsTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$ProductsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (priceHistoryEntriesRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          PriceHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._priceHistoryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceHistoryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool groupId, bool priceHistoryEntriesRefs})
    >;
typedef $$PriceHistoryEntriesTableCreateCompanionBuilder =
    PriceHistoryEntriesCompanion Function({
      required String id,
      required String productId,
      required double price,
      required DateTime checkedAt,
      Value<int> rowid,
    });
typedef $$PriceHistoryEntriesTableUpdateCompanionBuilder =
    PriceHistoryEntriesCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<double> price,
      Value<DateTime> checkedAt,
      Value<int> rowid,
    });

final class $$PriceHistoryEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PriceHistoryEntriesTable,
          PriceHistoryEntry
        > {
  $$PriceHistoryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.priceHistoryEntries.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PriceHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PriceHistoryEntriesTable> {
  $$PriceHistoryEntriesTableFilterComposer({
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

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceHistoryEntriesTable> {
  $$PriceHistoryEntriesTableOrderingComposer({
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

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceHistoryEntriesTable> {
  $$PriceHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<DateTime> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceHistoryEntriesTable,
          PriceHistoryEntry,
          $$PriceHistoryEntriesTableFilterComposer,
          $$PriceHistoryEntriesTableOrderingComposer,
          $$PriceHistoryEntriesTableAnnotationComposer,
          $$PriceHistoryEntriesTableCreateCompanionBuilder,
          $$PriceHistoryEntriesTableUpdateCompanionBuilder,
          (PriceHistoryEntry, $$PriceHistoryEntriesTableReferences),
          PriceHistoryEntry,
          PrefetchHooks Function({bool productId})
        > {
  $$PriceHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $PriceHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PriceHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<DateTime> checkedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryEntriesCompanion(
                id: id,
                productId: productId,
                price: price,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required double price,
                required DateTime checkedAt,
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryEntriesCompanion.insert(
                id: id,
                productId: productId,
                price: price,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PriceHistoryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$PriceHistoryEntriesTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$PriceHistoryEntriesTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PriceHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceHistoryEntriesTable,
      PriceHistoryEntry,
      $$PriceHistoryEntriesTableFilterComposer,
      $$PriceHistoryEntriesTableOrderingComposer,
      $$PriceHistoryEntriesTableAnnotationComposer,
      $$PriceHistoryEntriesTableCreateCompanionBuilder,
      $$PriceHistoryEntriesTableUpdateCompanionBuilder,
      (PriceHistoryEntry, $$PriceHistoryEntriesTableReferences),
      PriceHistoryEntry,
      PrefetchHooks Function({bool productId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductGroupsTableTableManager get productGroups =>
      $$ProductGroupsTableTableManager(_db, _db.productGroups);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$PriceHistoryEntriesTableTableManager get priceHistoryEntries =>
      $$PriceHistoryEntriesTableTableManager(_db, _db.priceHistoryEntries);
}
