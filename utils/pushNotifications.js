const fs = require('fs');
const https = require('https');
const jwt = require('jsonwebtoken');

let cachedAccessToken = null;
let cachedAccessTokenExpiresAt = 0;

const getServiceAccount = () => {
  if (process.env.FCM_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(process.env.FCM_SERVICE_ACCOUNT_JSON);
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
    }
    return serviceAccount;
  }

  if (process.env.FCM_SERVICE_ACCOUNT_PATH) {
    const serviceAccount = JSON.parse(fs.readFileSync(process.env.FCM_SERVICE_ACCOUNT_PATH, 'utf8'));
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
    }
    return serviceAccount;
  }

  return null;
};

const postJson = (url, payload, headers = {}) =>
  new Promise((resolve, reject) => {
    const body = JSON.stringify(payload);
    const request = https.request(
      url,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
          ...headers,
        },
      },
      (response) => {
        let responseBody = '';

        response.on('data', (chunk) => {
          responseBody += chunk;
        });

        response.on('end', () => {
          let parsedBody = responseBody;
          try {
            parsedBody = responseBody ? JSON.parse(responseBody) : {};
          } catch (error) {
            parsedBody = responseBody;
          }

          if (response.statusCode >= 200 && response.statusCode < 300) {
            resolve(parsedBody);
            return;
          }

          const error = new Error('Push notification request failed.');
          error.statusCode = response.statusCode;
          error.body = parsedBody;
          reject(error);
        });
      }
    );

    request.on('error', reject);
    request.write(body);
    request.end();
  });

const getAccessToken = async (serviceAccount) => {
  if (cachedAccessToken && Date.now() < cachedAccessTokenExpiresAt) {
    return cachedAccessToken;
  }

  const now = Math.floor(Date.now() / 1000);
  const assertion = jwt.sign(
    {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    },
    serviceAccount.private_key,
    { algorithm: 'RS256' }
  );

  const response = await postJson('https://oauth2.googleapis.com/token', {
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion,
  });

  cachedAccessToken = response.access_token;
  cachedAccessTokenExpiresAt = Date.now() + ((response.expires_in || 3600) - 60) * 1000;

  return cachedAccessToken;
};

exports.sendPushNotification = async ({ token, title, body, data = {} }) => {
  const serviceAccount = getServiceAccount();
  const projectId = process.env.FCM_PROJECT_ID || serviceAccount?.project_id;

  if (!serviceAccount || !projectId) {
    return { skipped: true, reason: 'FCM is not configured.' };
  }

  const accessToken = await getAccessToken(serviceAccount);
  const stringData = Object.entries(data).reduce((acc, [key, value]) => {
    acc[key] = value == null ? '' : String(value);
    return acc;
  }, {});

  return postJson(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      message: {
        token,
        notification: {
          title,
          body,
        },
        data: stringData,
      },
    },
    {
      Authorization: `Bearer ${accessToken}`,
    }
  );
};
