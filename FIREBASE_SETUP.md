# Firebase setup

The app contains a guarded Firebase integration. It stays in local mode when a
Firebase project configuration is not present, so startup does not crash.

## Connect a Firebase project

1. Create or select a Firebase project.
2. Enable Email/Password under Authentication.
3. Create a Firestore database and Storage bucket.
4. Run `flutterfire configure` from the project root. This generates the
   platform configuration without putting API secrets in Dart source.
5. Add the generated Android `google-services.json` when FlutterFire requests
   it, and deploy the rules:

```text
firebase deploy --only firestore:rules,storage
```

The first admin user must be promoted from the Firebase console or a trusted
admin script by setting `users/{uid}.role` to `admin`. A normal registration
always starts with the `user` role and cannot change it from the app.

## Collections

The rules cover `users`, `cows`, `healthRecords`, `donations`, `expenses`,
`volunteers`, `products`, `goshala`, and `serviceRecords`.

Firestore mobile persistence queues authorized writes while offline and syncs
them when connectivity returns. The app's existing local store remains the
fallback when Firebase is unavailable.
