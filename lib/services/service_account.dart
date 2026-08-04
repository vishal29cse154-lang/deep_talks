class ServiceAccountConfig {
  static const Map<String, dynamic> credentials = {
    // ⚠️ IMPORTANT:
    // 1. Go to Firebase Console > Project Settings > Service Accounts
    // 2. Click "Generate new private key"
    // 3. Open the downloaded JSON file and paste the entire contents between these brackets.
    // Make sure the keys (e.g. "type", "project_id", etc.) are wrapped in double quotes as valid Dart maps.

    // Example:
    // "type": "service_account",
    // "project_id": "together-space-d6htbb",
    // "private_key_id": "...",
    // "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
    // "client_email": "firebase-adminsdk-xxx@together-space-d6htbb.iam.gserviceaccount.com",
    // "client_id": "...",
    // "auth_uri": "...",
    // "token_uri": "...",
    // "auth_provider_x509_cert_url": "...",
    // "client_x509_cert_url": "..."
  };
}
