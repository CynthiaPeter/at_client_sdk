<img width=250px src="https://atsign.dev/assets/img/@platform_logo_grey.svg?sanitize=true">

## Now for some internet optimism.

[![pub package](https://img.shields.io/pub/v/at_client_mobile)](https://pub.dev/packages/at_client_mobile) [![pub points](https://badges.bar/at_client_mobile/pub%20points)](https://pub.dev/packages/at_client_mobile/score) [![build status](https://github.com/atsign-foundation/at_client_sdk/actions/workflows/at_client_sdk.yaml/badge.svg?branch=trunk)](https://github.com/atsign-foundation/at_client_sdk/actions/workflows/at_client_sdk.yaml) [![gitHub license](https://img.shields.io/badge/license-BSD3-blue.svg)](./LICENSE)

# at_client

### Introduction

SDK that provides the essential methods for building an app using [The @protocol](https://atsign.com). You may also want to look at [at_client_mobile](https://pub.dev/packages/at_client_mobile).

**at_client** package is written in Dart, supports Flutter and follows the
@platform's decentralized, edge computing model with the following features: 
- Cryptographic control of data access through personal data stores
- No application backend needed
- End to end encryption where only the data owner has the keys
- Private and surveillance free connectivity
- ... <!--- add package features here -->

We call giving people control of access to their data "*flipping the internet*".

## Get Started

Initially to get a basic overview of the SDK, you must read the [atsign docs](https://atsign.dev/docs/overview/).

> To use this package you must be having a basic setup, Follow here to [get started](https://atsign.dev/docs/get-started/setup-your-env/).

Check how to use this package in the [at_client installtion tab](https://pub.dev/packages/at_client/install).

## Usage

**AtClient**
  - AtClient is an abstract class that provides the basic functionality for the SDK.
  - It is an interface for a client application that can communicate with a secondary server.
  - It provides the following methods:
    
    - [`getRemoteSecondary()`]()
        
        - Returns a singleton instance of [RemoteSecondary](https://pub.dev/documentation/at_client/latest/at_client/RemoteSecondary-class.html) to communicate with user's secondary server.

    - [`getLocalSecondary()`]()

        - Returns a singleton instance of [LocalSecondary](https://pub.dev/documentation/at_client/latest/at_client/LocalSecondary-class.html) to communicate with user's secondary server.

    - [`setPreferences()`]()

        - Sets the preferences such as sync strategy, storage path etc., for the client.
        
    - [`getPreferences()`]()

        - Gets the preferences such as sync strategy, storage path etc., for the client.

    - [`put()`]()

        - Updates value of [AtKey.key](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/key.html) is if it is already present. Otherwise creates a new key. Set [AtKey.sharedWith](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/sharedWith.html) if the key has to be shared with another atSign. Set [AtKey.metadata.isBinary](https://pub.dev/documentation/at_commons/latest/at_commons/Metadata/isBinary.html) if you are updating binary value e.g image,file. By default namespace that is used to create the [AtClient](https://pub.dev/documentation/at_client/latest/at_client/AtClient-class.html) instance will be appended to the key. phone@alice will be saved as phone.persona@alice where 'persona' is the namespace. If you want to save by ignoring the namespace set [AtKey.metadata.namespaceAware](https://pub.dev/documentation/at_commons/latest/at_commons/Metadata/namespaceAware.html) to false. Additional metadata can be set using [AtKey.metadata](https://pub.dev/documentation/at_commons/latest/at_commons/Metadata-class.html).

    - [`putMeta()`]()

        - Updates the metadata of [AtKey.key](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/key.html) if it is already present. Otherwise creates a new key without a value. By default namespace that is used to create the [AtClient](https://pub.dev/documentation/at_client/latest/at_client/AtClient-class.html) instance will be appended to the key. phone@alice will be saved as phone.persona@alice where 'persona' is the namespace. If you want to save by ignoring the namespace set [AtKey.metadata.namespaceAware](https://pub.dev/documentation/at_commons/latest/at_commons/Metadata/namespaceAware.html) to false.

    - [`get()`]()

        - Get the value of [AtKey.key](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/key.html) from user's cloud secondary if [AtKey.sharedBy](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/sharedBy.html) is set. Otherwise looks up the key from local secondary. If the key was stored with public access, set [AtKey.metadata.isPublic](https://pub.dev/documentation/at_commons/latest/at_commons/Metadata/isPublic.html) to true. If the key was shared with another atSign set [AtKey.sharedWith](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/sharedBy.html).

    - [`getMeta()`]()

        - Gets the metadata of [AtKey.key](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey/key.html)

    - [`delete()`]()

        - Delete the [key](https://pub.dev/documentation/at_commons/latest/at_commons/AtKey-class.html) from user's local secondary and syncs the delete to cloud secondary if client's sync preference is immediate. By default namespace that is used to create the [AtClient](https://pub.dev/documentation/at_client/latest/at_client/AtClient-class.html) instance will be appended to the key. phone@alice translates to phone.persona@alice where 'persona' is the namespace. If you want to ignoring the namespace set [AtKey.metadata.namespaceAware](https://pub.dev/documentation/at_commons/latest/at_commons/Metadata/namespaceAware.html) to false.

    - [`notifyChange()`]()

        - Notifies the ***NotificationParams.atKey*** to ***notificationParams.atKey.sharedWith*** user of the atSign. Optionally, operation, value and metadata can be set along with key to notify.

    AtClient has many more methods that are exposed. Please refer to the [atsign docs](https://pub.dev/documentation/at_client/latest/at_client/AtClient-class.html) for more details. [AtClientImpl](https://pub.dev/documentation/at_client/latest/at_client/AtClientImpl-class.html) is the implementation of AtClient.


**RemoteSecondary**

  - RemoteSecondary provides methods used to execute verbs on remote secondary server of the atSign.
  
  - It provides the following methods:
    
    - [`sync()`]()

        - Executes sync verb on the remote server. Return commit entries greater than [lastSyncedId]().

    - [`monitor()`]()

        - Executes monitor verb on remote secondary. Result of the monitor verb is processed using *monitorResponseCallback*.

    - [`authenticate()`]()

        - Generates digest using from verb response and *privateKey* and performs a PKAM authentication to secondary server. This method is executed for all verbs that requires authentication.

    RemoteSecondary has many more methods that are exposed. Please refer to the [atsign docs](https://pub.dev/documentation/at_client/latest/at_client/RemoteSecondary-class.html) for more details.

**LocalSecondary**

  - LocalSecondary provides methods to execute verb on local secondary storage using [executeVerb]() set [AtClientPreference.isLocalStoreRequired]() to true and other preferences that your app needs. Delete and Update commands will be synced to the server.

  Both **LocalSecondary** and **RemoteSecondary** classes implements the same interface called [Secondary]().

**AtClientManager**

  - Factory class for creating [AtClient](#:~:text=AtClient), [SyncService](https://pub.dev/documentation/at_client/latest/at_client/SyncService-class.html) and [NotificationService](https://pub.dev/documentation/at_client/latest/at_client/NotificationService-class.html) instances.

  - The sample usage is
  
  ```dart
  /// Create an instance of AtClientManager
  AtClientManager atClientManager = AtClientManager.getInstance().setCurrentAtSign(atSign, appNamespace, atClientPreferences);
  ```

**AtNotification**

  - A model class that represents the notification received from the atSign.