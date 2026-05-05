const express = require('express');
const { KubeConfig } = require('@kubernetes/client-node');
const k8s = require('@kubernetes/client-node');

const app = express();
const port = process.env.PORT || 3000;

const MODULE_METADATA = {
  'cert-manager': { namespace: 'cert-manager', description: 'Certificate management for TLS', techs: ['Kubernetes', "Let's Encrypt"], category: 'Infrastructure' },
  'ingress-nginx': { namespace: 'ingress-nginx', description: 'Ingress controller for HTTP(S) routing', techs: ['Kubernetes', 'Nginx'], category: 'Network' },
  'kube-prometheus-stack': { namespace: 'monitoring', description: 'Prometheus, Grafana, and AlertManager stack', techs: ['Prometheus', 'Grafana'], category: 'Observability' },
  'argocd': { namespace: 'argocd', description: 'GitOps continuous deployment', techs: ['GitOps', 'Kubernetes'], category: 'CI/CD' },
  'keycloak': { namespace: 'keycloak', description: 'Identity and access management', techs: ['OAuth2', 'SAML'], category: 'Security' },
  'vault': { namespace: 'vault', description: 'Secrets and encryption management', techs: ['HashiCorp', 'PKI'], category: 'Security' },
  'minio': { namespace: 'minio', description: 'S3-compatible object storage', techs: ['S3', 'Storage'], category: 'Storage' },
  'harbor': { namespace: 'harbor', description: 'Container registry and repository management', techs: ['Docker', 'OCI'], category: 'Infrastructure' },
  'jellyfin': { namespace: 'jellyfin', description: 'Media streaming server', techs: ['Streaming', 'Kubernetes'], category: 'Applications' },
  'pihole': { namespace: 'pihole', description: 'DNS ad blocking and local DNS server', techs: ['DNS', 'Networking'], category: 'Network' },
  'n8n': { namespace: 'n8n', description: 'Workflow automation platform', techs: ['Automation', 'Workflows'], category: 'Automation' },
  'oauth2-proxy': { namespace: 'oauth2-proxy', description: 'OAuth2 reverse proxy for authentication', techs: ['OAuth2', 'Security'], category: 'Security' },
  'immich': { namespace: 'immich', description: 'Self-hosted photo management system', techs: ['PostgreSQL', 'Kubernetes'], category: 'Applications' },
  'loki': { namespace: 'loki', description: 'Log aggregation and querying system', techs: ['Logs', 'Grafana'], category: 'Observability' }
};

let clusterState = {
  modules: {},
  lastUpdated: new Date()
};

const kc = new KubeConfig();
kc.loadFromDefault();
const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const appsApi = kc.makeApiClient(k8s.AppsV1Api);

async function fetchClusterState() {
  try {
    const namespaces = await k8sApi.listNamespace();
    const newModules = {};

    // Initialize all known modules as not deployed
    for (const [modName, modMeta] of Object.entries(MODULE_METADATA)) {
      newModules[modName] = {
        ...modMeta,
        status: 'Not deployed',
        replicas: '0/0'
      };
    }

    for (const ns of namespaces.body.items) {
      const nsName = ns.metadata.name;
      try {
        const deployments = await appsApi.listNamespacedDeployment(nsName);
        for (const dep of deployments.body.items) {
          for (const [modName, modMeta] of Object.entries(MODULE_METADATA)) {
            if (modMeta.namespace === nsName) {
              const ready = dep.status?.readyReplicas || 0;
              const desired = dep.spec?.replicas || 0;
              newModules[modName] = {
                ...modMeta,
                status: ready === desired && ready > 0 ? 'Running' : ready > 0 ? 'Degraded' : 'Not deployed',
                replicas: `${ready}/${desired}`
              };
            }
          }
        }
      } catch (e) {
        // Continue even if a namespace call fails
      }
    }

    clusterState.modules = newModules;
    clusterState.lastUpdated = new Date();
  } catch (err) {
    console.error('Error fetching cluster state:', err.message);
  }
}

fetchClusterState();
setInterval(fetchClusterState, 10000);

app.use(express.static('.'));

app.get('/', (req, res) => {
  res.sendFile('/app/index.html');
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/cluster-state', (req, res) => {
  res.json(clusterState);
});

app.get('/api/modules', (req, res) => {
  res.json(clusterState.modules);
});

app.get('/api/infrastructure-summary', (req, res) => {
  const modules = Object.entries(clusterState.modules).map(([name, meta]) => ({ name, ...meta }));
  const categorized = {};

  modules.forEach((m) => {
    if (!categorized[m.category]) categorized[m.category] = [];
    categorized[m.category].push(m);
  });

  res.json({
    modules,
    categorized,
    summary: {
      totalModules: modules.length,
      runningCount: modules.filter((m) => m.status === 'Running').length,
      degradedCount: modules.filter((m) => m.status === 'Degraded').length,
      notDeployedCount: modules.filter((m) => m.status === 'Not deployed').length
    },
    lastUpdated: clusterState.lastUpdated
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Skills dashboard listening on port ${port}`);
});
