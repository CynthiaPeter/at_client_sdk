import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_client/src/client/secondary.dart';
import 'package:at_client/src/exception/at_client_exception.dart';
import 'package:at_client/src/manager/at_client_manager.dart';
import 'package:at_client/src/util/at_client_util.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_spec/at_persistence_spec.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_utils/at_utils.dart';

/// Contains methods to execute verb on local secondary storage using [executeVerb]
/// Set [AtClientPreference.isLocalStoreRequired] to true and other preferences that your app needs.
/// Delete and Update commands will be synced to the server
class LocalSecondary implements Secondary {
  final AtClient _atClient;

  final _logger = AtSignLogger('LocalSecondary');

  /// Local keystore used to store data for the current atSign.
  SecondaryKeyStore? keyStore;

  LocalSecondary(this._atClient) {
    keyStore = SecondaryPersistenceStoreFactory.getInstance()
        .getSecondaryPersistenceStore(_atClient.getCurrentAtSign())!
        .getSecondaryKeyStore();
  }

  /// Executes a verb builder on the local secondary. For update and delete operation, if [sync] is
  /// set to true then data is synced from local to remote.
  /// if [sync] is set to false, no sync operation is done.
  @override
  Future<String?> executeVerb(VerbBuilder builder, {sync}) async {
    var verbResult;

    try {
      if (builder is UpdateVerbBuilder || builder is DeleteVerbBuilder) {
        //1. if local and server are out of sync, first sync before updating current key-value

        //2 . update/delete to local store
        if (builder is UpdateVerbBuilder) {
          verbResult = await _update(builder);
        } else if (builder is DeleteVerbBuilder) {
          verbResult = await _delete(builder);
        }
        // 3. sync latest update/delete if strategy is immediate
        if (sync != null && sync) {
          _logger.finer('calling sync immediate from local secondary');
          AtClientManager.getInstance().syncService.sync();
        }
      } else if (builder is LLookupVerbBuilder) {
        verbResult = await _llookup(builder);
      } else if (builder is ScanVerbBuilder) {
        verbResult = await _scan(builder);
      }
    } on Exception catch (e) {
      if (e is AtLookUpException) {
        return Future.error(AtClientException(e.errorCode, e.errorMessage));
      } else {
        rethrow;
      }
    }
    return verbResult;
  }

  Future<String> _update(UpdateVerbBuilder builder) async {
    try {
      var updateResult;
      var updateKey = AtClientUtil.buildKey(builder);
      switch (builder.operation) {
        case UPDATE_META:
          var metadata = Metadata();
          metadata
            ..ttl = builder.ttl
            ..ttb = builder.ttb
            ..ttr = builder.ttr
            ..ccd = builder.ccd
            ..isBinary = builder.isBinary
            ..isEncrypted = builder.isEncrypted;
          var atMetadata = AtMetadataAdapter(metadata);
          updateResult = await keyStore!.putMeta(updateKey, atMetadata);
          break;
        default:
          var atData = AtData();
          atData.data = builder.value;
          if (builder.dataSignature != null) {
            var metadata = Metadata();
            metadata
              ..ttl = builder.ttl
              ..ttb = builder.ttb
              ..ttr = builder.ttr
              ..ccd = builder.ccd
              ..isBinary = builder.isBinary
              ..isEncrypted = builder.isEncrypted
              ..dataSignature = builder.dataSignature;
            var atMetadata = AtMetadataAdapter(metadata);
            updateResult =
                await keyStore!.putAll(updateKey, atData, atMetadata);
            break;
          }
          // #TODO replace below call with putAll.
          updateResult = await keyStore!.put(updateKey, atData,
              time_to_live: builder.ttl,
              time_to_born: builder.ttb,
              time_to_refresh: builder.ttr,
              isCascade: builder.ccd,
              isBinary: builder.isBinary,
              isEncrypted: builder.isEncrypted);
          break;
      }
      return 'data:$updateResult';
    } on DataStoreException catch (e) {
      _logger.severe('exception in local update:${e.toString()}');
      rethrow;
    }
  }

  Future<String> _llookup(LLookupVerbBuilder builder) async {
    try {
      var llookupKey = '';
      if (builder.isCached) {
        llookupKey += 'cached:';
      }
      if (builder.sharedWith != null) {
        llookupKey += '${AtUtils.formatAtSign(builder.sharedWith!)}:';
      }
      if (builder.atKey != null) {
        llookupKey += builder.atKey!;
      }
      if (builder.sharedBy != null) {
        llookupKey += AtUtils.formatAtSign(builder.sharedBy)!;
      }
      var llookupMeta = await keyStore!.getMeta(llookupKey);
      var isActive = _isActiveKey(llookupMeta);
      var result;
      if (isActive) {
        var llookupResult = await keyStore!.get(llookupKey);
        result = _prepareResponseData(builder.operation, llookupResult);
      }
      return 'data:$result';
    } on DataStoreException catch (e) {
      _logger.severe('exception in llookup:${e.toString()}');
      rethrow;
    }
  }

  Future<String> _delete(DeleteVerbBuilder builder) async {
    try {
      var deleteKey = '';
      if (builder.isCached) {
        deleteKey += 'cached:';
      }
      if (builder.isPublic) {
        deleteKey += 'public:';
      }
      if (builder.sharedWith != null && builder.sharedWith!.isNotEmpty) {
        deleteKey += '${AtUtils.formatAtSign(builder.sharedWith!)}:';
      }
      if (builder.sharedBy != null && builder.sharedBy!.isNotEmpty) {
        deleteKey +=
            '${builder.atKey}${AtUtils.formatAtSign(builder.sharedBy!)}';
      } else {
        deleteKey += builder.atKey!;
      }
      var deleteResult = await keyStore!.remove(deleteKey);
      return 'data:$deleteResult';
    } on DataStoreException catch (e) {
      _logger.severe('exception in delete:${e.toString()}');
      rethrow;
    }
  }

  Future<String?> _scan(ScanVerbBuilder builder) async {
    try {
      // Call to remote secondary sever and performs an outbound scan to retrieve values from sharedBy secondary
      // shared with current atSign
      if (builder.sharedBy != null) {
        var command = builder.buildCommand();
        return await RemoteSecondary(
                _atClient.getCurrentAtSign()!, _atClient.getPreferences()!,
                privateKey: _atClient.getPreferences()!.privateKey)
            .executeCommand(command, auth: true);
      }
      List<String?> keys;
      keys = keyStore!.getKeys(regex: builder.regex) as List<String?>;
      // Gets keys shared to sharedWith atSign.
      if (builder.sharedWith != null) {
        keys.retainWhere(
            (element) => element!.startsWith(builder.sharedWith!) == true);
      }
      keys.removeWhere((key) =>
          key.toString().startsWith('privatekey:') ||
          key.toString().startsWith('private:') ||
          key.toString().startsWith('public:_'));
      var keyString = keys.toString();
      // Apply regex on keyString to remove unnecessary characters and spaces
      keyString = keyString.replaceFirst(RegExp(r'^\['), '');
      keyString = keyString.replaceFirst(RegExp(r'\]$'), '');
      keyString = keyString.replaceAll(', ', ',');
      var keysArray = keyString.isNotEmpty ? (keyString.split(',')) : [];
      return json.encode(keysArray);
    } on DataStoreException catch (e) {
      _logger.severe('exception in scan:${e.toString()}');
      rethrow;
    }
  }

  bool _isActiveKey(AtMetaData? atMetaData) {
    if (atMetaData == null) return true;
    var ttb = atMetaData.availableAt;
    var ttl = atMetaData.expiresAt;
    if (ttb == null && ttl == null) return true;
    var now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (ttb != null) {
      var ttb_ms = ttb.toUtc().millisecondsSinceEpoch;
      if (ttb_ms > now) return false;
    }
    if (ttl != null) {
      var ttl_ms = ttl.toUtc().millisecondsSinceEpoch;
      if (ttl_ms < now) return false;
    }
    //If TTB or TTL populated but not met, return true.
    return true;
  }

  String? _prepareResponseData(String? operation, AtData? atData) {
    var result;
    if (atData == null) {
      return result;
    }
    switch (operation) {
      case 'meta':
        result = json.encode(atData.metaData!.toJson());
        break;
      case 'all':
        result = json.encode(atData.toJson());
        break;
      default:
        result = atData.data;
        break;
    }
    return result;
  }

  Future<String?> getPrivateKey() async {
    var privateKeyData = await keyStore!.get(AT_PKAM_PRIVATE_KEY);
    return privateKeyData?.data;
  }

  Future<String?> getEncryptionPrivateKey() async {
    var privateKeyData = await keyStore!.get(AT_ENCRYPTION_PRIVATE_KEY);
    return privateKeyData?.data;
  }

  Future<String?> getPublicKey() async {
    var publicKeyData = await keyStore!.get(AT_PKAM_PUBLIC_KEY);
    return publicKeyData?.data;
  }

  Future<String?> getEncryptionPublicKey(String atSign) async {
    atSign = AtUtils.formatAtSign(atSign)!;
    var privateKeyData =
        await keyStore!.get('$AT_ENCRYPTION_PUBLIC_KEY$atSign');
    return privateKeyData?.data;
  }

  Future<String?> getEncryptionSelfKey() async {
    var selfKeyData = await keyStore!.get(AT_ENCRYPTION_SELF_KEY);
    return selfKeyData?.data;
  }

  ///Returns `true` on successfully storing the values into local secondary.
  Future<bool> putValue(String key, String value) async {
    var isStored;
    var atData = AtData()..data = value;
    isStored = await keyStore!.put(key, atData);
    return isStored != null ? true : false;
  }
}
