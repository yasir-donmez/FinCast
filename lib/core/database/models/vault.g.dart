// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVaultCollection on Isar {
  IsarCollection<Vault> get vaults => this.collection();
}

const VaultSchema = CollectionSchema(
  name: r'Vault',
  id: -4342956630933593564,
  properties: {
    r'balance': PropertySchema(
      id: 0,
      name: r'balance',
      type: IsarType.double,
    ),
    r'currency': PropertySchema(
      id: 1,
      name: r'currency',
      type: IsarType.string,
    ),
    r'dashboardLayoutType': PropertySchema(
      id: 2,
      name: r'dashboardLayoutType',
      type: IsarType.long,
    ),
    r'dashboardOrder': PropertySchema(
      id: 3,
      name: r'dashboardOrder',
      type: IsarType.long,
    ),
    r'iconCode': PropertySchema(
      id: 4,
      name: r'iconCode',
      type: IsarType.string,
    ),
    r'isIncludedInTotal': PropertySchema(
      id: 5,
      name: r'isIncludedInTotal',
      type: IsarType.bool,
    ),
    r'maxLimit': PropertySchema(
      id: 6,
      name: r'maxLimit',
      type: IsarType.double,
    ),
    r'minLimit': PropertySchema(
      id: 7,
      name: r'minLimit',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 8,
      name: r'name',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 9,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'showOnDashboard': PropertySchema(
      id: 10,
      name: r'showOnDashboard',
      type: IsarType.bool,
    ),
    r'syncStatus': PropertySchema(
      id: 11,
      name: r'syncStatus',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _vaultEstimateSize,
  serialize: _vaultSerialize,
  deserialize: _vaultDeserialize,
  deserializeProp: _vaultDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteId': IndexSchema(
      id: 6301175856541681032,
      name: r'remoteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'remoteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'syncStatus': IndexSchema(
      id: 8239539375045684509,
      name: r'syncStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncStatus',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _vaultGetId,
  getLinks: _vaultGetLinks,
  attach: _vaultAttach,
  version: '3.1.0+1',
);

int _vaultEstimateSize(
  Vault object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.iconCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _vaultSerialize(
  Vault object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.balance);
  writer.writeString(offsets[1], object.currency);
  writer.writeLong(offsets[2], object.dashboardLayoutType);
  writer.writeLong(offsets[3], object.dashboardOrder);
  writer.writeString(offsets[4], object.iconCode);
  writer.writeBool(offsets[5], object.isIncludedInTotal);
  writer.writeDouble(offsets[6], object.maxLimit);
  writer.writeDouble(offsets[7], object.minLimit);
  writer.writeString(offsets[8], object.name);
  writer.writeString(offsets[9], object.remoteId);
  writer.writeBool(offsets[10], object.showOnDashboard);
  writer.writeLong(offsets[11], object.syncStatus);
  writer.writeDateTime(offsets[12], object.updatedAt);
}

Vault _vaultDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Vault();
  object.balance = reader.readDouble(offsets[0]);
  object.currency = reader.readString(offsets[1]);
  object.dashboardLayoutType = reader.readLong(offsets[2]);
  object.dashboardOrder = reader.readLong(offsets[3]);
  object.iconCode = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.isIncludedInTotal = reader.readBool(offsets[5]);
  object.maxLimit = reader.readDoubleOrNull(offsets[6]);
  object.minLimit = reader.readDoubleOrNull(offsets[7]);
  object.name = reader.readString(offsets[8]);
  object.remoteId = reader.readStringOrNull(offsets[9]);
  object.showOnDashboard = reader.readBool(offsets[10]);
  object.syncStatus = reader.readLong(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  return object;
}

P _vaultDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _vaultGetId(Vault object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _vaultGetLinks(Vault object) {
  return [];
}

void _vaultAttach(IsarCollection<dynamic> col, Id id, Vault object) {
  object.id = id;
}

extension VaultQueryWhereSort on QueryBuilder<Vault, Vault, QWhere> {
  QueryBuilder<Vault, Vault, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhere> anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }
}

extension VaultQueryWhere on QueryBuilder<Vault, Vault, QWhereClause> {
  QueryBuilder<Vault, Vault, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'remoteId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> remoteIdEqualTo(
      String? remoteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'remoteId',
        value: [remoteId],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> remoteIdNotEqualTo(
      String? remoteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> updatedAtEqualTo(
      DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> updatedAtNotEqualTo(
      DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> syncStatusEqualTo(
      int syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncStatus',
        value: [syncStatus],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> syncStatusNotEqualTo(
      int syncStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [],
              upper: [syncStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [syncStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [syncStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [],
              upper: [syncStatus],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> syncStatusGreaterThan(
    int syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [syncStatus],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> syncStatusLessThan(
    int syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [],
        upper: [syncStatus],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterWhereClause> syncStatusBetween(
    int lowerSyncStatus,
    int upperSyncStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [lowerSyncStatus],
        includeLower: includeLower,
        upper: [upperSyncStatus],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VaultQueryFilter on QueryBuilder<Vault, Vault, QFilterCondition> {
  QueryBuilder<Vault, Vault, QAfterFilterCondition> balanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> balanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> balanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> balanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardLayoutTypeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dashboardLayoutType',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition>
      dashboardLayoutTypeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dashboardLayoutType',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardLayoutTypeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dashboardLayoutType',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardLayoutTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dashboardLayoutType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardOrderEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dashboardOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dashboardOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dashboardOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> dashboardOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dashboardOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iconCode',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iconCode',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iconCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iconCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iconCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iconCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> iconCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iconCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> isIncludedInTotalEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isIncludedInTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> maxLimitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maxLimit',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> maxLimitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maxLimit',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> maxLimitEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> maxLimitGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> maxLimitLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> maxLimitBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> minLimitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'minLimit',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> minLimitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'minLimit',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> minLimitEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> minLimitGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> minLimitLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> minLimitBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> showOnDashboardEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showOnDashboard',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> syncStatusEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> syncStatusGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> syncStatusLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> syncStatusBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Vault, Vault, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VaultQueryObject on QueryBuilder<Vault, Vault, QFilterCondition> {}

extension VaultQueryLinks on QueryBuilder<Vault, Vault, QFilterCondition> {}

extension VaultQuerySortBy on QueryBuilder<Vault, Vault, QSortBy> {
  QueryBuilder<Vault, Vault, QAfterSortBy> sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByDashboardLayoutType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardLayoutType', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByDashboardLayoutTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardLayoutType', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByDashboardOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardOrder', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByDashboardOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardOrder', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByIconCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByIsIncludedInTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncludedInTotal', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByIsIncludedInTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncludedInTotal', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByMaxLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLimit', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByMaxLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLimit', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByMinLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLimit', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByMinLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLimit', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByShowOnDashboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDashboard', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByShowOnDashboardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDashboard', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension VaultQuerySortThenBy on QueryBuilder<Vault, Vault, QSortThenBy> {
  QueryBuilder<Vault, Vault, QAfterSortBy> thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByDashboardLayoutType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardLayoutType', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByDashboardLayoutTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardLayoutType', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByDashboardOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardOrder', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByDashboardOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dashboardOrder', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByIconCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByIsIncludedInTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncludedInTotal', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByIsIncludedInTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncludedInTotal', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByMaxLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLimit', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByMaxLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLimit', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByMinLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLimit', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByMinLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLimit', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByShowOnDashboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDashboard', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByShowOnDashboardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDashboard', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Vault, Vault, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension VaultQueryWhereDistinct on QueryBuilder<Vault, Vault, QDistinct> {
  QueryBuilder<Vault, Vault, QDistinct> distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByDashboardLayoutType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dashboardLayoutType');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByDashboardOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dashboardOrder');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByIconCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByIsIncludedInTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isIncludedInTotal');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByMaxLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxLimit');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByMinLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minLimit');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByShowOnDashboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showOnDashboard');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<Vault, Vault, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension VaultQueryProperty on QueryBuilder<Vault, Vault, QQueryProperty> {
  QueryBuilder<Vault, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Vault, double, QQueryOperations> balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }

  QueryBuilder<Vault, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<Vault, int, QQueryOperations> dashboardLayoutTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dashboardLayoutType');
    });
  }

  QueryBuilder<Vault, int, QQueryOperations> dashboardOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dashboardOrder');
    });
  }

  QueryBuilder<Vault, String?, QQueryOperations> iconCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconCode');
    });
  }

  QueryBuilder<Vault, bool, QQueryOperations> isIncludedInTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isIncludedInTotal');
    });
  }

  QueryBuilder<Vault, double?, QQueryOperations> maxLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxLimit');
    });
  }

  QueryBuilder<Vault, double?, QQueryOperations> minLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minLimit');
    });
  }

  QueryBuilder<Vault, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Vault, String?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<Vault, bool, QQueryOperations> showOnDashboardProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showOnDashboard');
    });
  }

  QueryBuilder<Vault, int, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<Vault, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
