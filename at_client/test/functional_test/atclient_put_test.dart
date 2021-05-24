import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

import 'at_demo_credentials.dart' as demo_credentials;
import 'set_encryption_keys.dart';

void main() {
  AtClient? atClient;
  test('put method - create a key sharing to other atsign', () async {
    var atsign = '@alice🛠';
    var preference = getAlicePreference(atsign);
    await AtClientImpl.createClient(atsign, 'me', preference);
    atClient= await AtClientImpl.getClient(atsign);
    atClient?.getSyncManager()!.init(atsign, preference,
        atClient!.getRemoteSecondary(), atClient!.getLocalSecondary());
    await atClient?.getSyncManager()!.sync();
    // To setup encryption keys
    await setEncryptionKeys(atsign, preference);
    // phone.me@alice🛠
    var phoneKey = AtKey()
      ..key = 'phone'
      ..sharedWith = '@bob🛠';
    var value = '+1 100 200 300';
    var putResult = await atClient?.put(phoneKey, value);
    expect(putResult, true);
    var getResult = await atClient?.get(phoneKey);
    expect(getResult?.value, value);
  }, timeout: Timeout(Duration(seconds: 300)));
  Future.delayed(Duration(seconds: 150));
  // tearDown(() async => await tearDownFunc());
}

Future<void> tearDownFunc() async {
  var isExists = await Directory('test/hive').exists();
  if (isExists) {
    Directory('test/hive').deleteSync(recursive: true);
  }
}

AtClientPreference getAlicePreference(String atsign) {
  var preference = AtClientPreference();
  preference.hiveStoragePath = 'test/hive/client';
  preference.commitLogPath = 'test/hive/client/commit';
  preference.isLocalStoreRequired = true;
  preference.syncStrategy = SyncStrategy.IMMEDIATE;
  preference.privateKey = demo_credentials.pkamPrivateKeyMap[atsign];
  preference.rootDomain = 'vip.ve.atsign.zone';
  return preference;
}
