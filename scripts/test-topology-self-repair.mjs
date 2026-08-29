import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { once } from 'node:events';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const binary = path.join(repoDir, 'target', 'debug', 'mtd-evidence-rail');
const candidateImage = 'sociobotregistry.azurecr.io/sf-mtd-evidence-rail:560392b27a89';
const readyImage = 'sociobotregistry.azurecr.io/sf-mtd-evidence-rail:5779508e0a5c';
let receivedPatch;

const server = createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', 'http://127.0.0.1');
  if (request.method === 'GET' && url.pathname === '/identity') {
    assert.equal(request.headers['x-identity-header'], 'fixture-identity-header');
    assert.equal(url.searchParams.get('resource'), 'https://management.azure.com/');
    assert.equal(url.searchParams.get('client_id'), 'fixture-client-id');
    response.setHeader('content-type', 'application/json');
    response.end(JSON.stringify({ access_token: 'fixture-access-token' }));
    return;
  }
  assert.equal(request.headers.authorization, 'Bearer fixture-access-token');
  const appPath = '/subscriptions/fixture-subscription/resourceGroups/fixture-group/providers/Microsoft.App/containerApps/sf-mtd-evidence-rail';
  assert(url.pathname === appPath || url.pathname === `${appPath}/revisions/sf-mtd-evidence-rail--0000053`);
  assert.equal(url.searchParams.get('api-version'), '2024-03-01');
  if (request.method === 'GET') {
    response.setHeader('content-type', 'application/json');
    if (url.pathname.endsWith('/revisions/sf-mtd-evidence-rail--0000053')) {
      response.end(JSON.stringify({
        properties: { template: { containers: [{ image: readyImage }] } },
      }));
      return;
    }
    response.end(JSON.stringify({
      properties: {
        latestRevisionName: 'sf-mtd-evidence-rail--0000054',
        latestReadyRevisionName: 'sf-mtd-evidence-rail--0000053',
        configuration: { activeRevisionsMode: 'Single' },
        template: {
          containers: [{
            name: 'app',
            image: candidateImage,
            resources: { cpu: 0.5, memory: '1Gi' },
            env: [{ name: 'PORT', value: '8080' }],
          }],
          scale: { minReplicas: 1, maxReplicas: 3 },
          volumes: null,
        },
      },
    }));
    return;
  }
  assert.equal(url.pathname, appPath);
  assert.equal(request.method, 'PATCH');
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  receivedPatch = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  response.setHeader('content-type', 'application/json');
  response.end('{}');
});

server.listen(0, '127.0.0.1');
await once(server, 'listening');
const address = server.address();
assert(address && typeof address === 'object');
const origin = `http://127.0.0.1:${address.port}`;

const child = spawn(binary, [], {
  cwd: repoDir,
  env: {
    CONTAINER_APP_NAME: 'sf-mtd-evidence-rail',
    CONTAINER_APP_REVISION: 'sf-mtd-evidence-rail--0000054',
    DATA_DIR: '/data',
    PORT: '8299',
    IDENTITY_ENDPOINT: `${origin}/identity`,
    IDENTITY_HEADER: 'fixture-identity-header',
    AZURE_CLIENT_ID: 'fixture-client-id',
    AZURE_SUBSCRIPTION_ID: 'fixture-subscription',
    AZURE_RESOURCE_GROUP: 'fixture-group',
    AZURE_MANAGEMENT_ENDPOINT: origin,
  },
  stdio: ['ignore', 'pipe', 'pipe'],
});
let output = '';
child.stdout.on('data', (chunk) => { output += chunk; });
child.stderr.on('data', (chunk) => { output += chunk; });
const [exitCode] = await once(child, 'exit');
server.close();
await once(server, 'close');

assert.equal(exitCode, 78, output);
assert(receivedPatch, `repair PATCH was not received\n${output}`);
assert.equal(receivedPatch.properties.configuration.activeRevisionsMode, 'Single');
assert.equal(receivedPatch.properties.template.scale.minReplicas, 1);
assert.equal(receivedPatch.properties.template.scale.maxReplicas, 1);
assert.equal(receivedPatch.properties.template.containers[0].image, readyImage);
assert.deepEqual(receivedPatch.properties.template.containers[0].volumeMounts, [
  { volumeName: 'mtd-data', mountPath: '/data' },
]);
assert.deepEqual(receivedPatch.properties.template.volumes, [{
  name: 'mtd-data',
  storageName: 'mtd-evidence-rail-data',
  storageType: 'AzureFile',
}]);
assert(receivedPatch.properties.template.containers[0].env.some(
  (entry) => entry.name === 'SQLITE_VFS' && entry.value === 'unix-dotfile',
));
assert.match(output, /durable Azure topology requested/);

console.log('Verification 16 self-repair integration PASS — the exact generic revision requested a durable replacement and exited without serving.');
