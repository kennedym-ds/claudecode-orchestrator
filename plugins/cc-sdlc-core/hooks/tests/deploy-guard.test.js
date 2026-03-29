#!/usr/bin/env node
/**
 * Unit tests for deploy-guard.js hook.
 * Uses node:test (built-in, zero deps). Run: node --test plugins/cc-sdlc-core/hooks/tests/
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const DEPLOY_PATTERNS = [
  /kubectl\s+apply.*--context\s+prod/i,
  /kubectl\s+apply.*production/i,
  /helm\s+(install|upgrade).*prod/i,
  /terraform\s+apply\s+(?!.*-{1,2}target)/i,
  /aws\s+.*deploy/i,
  /az\s+.*deployment\s+create/i,
  /gcloud\s+.*deploy/i,
  /git\s+push.*--force.*main/i,
  /git\s+push.*--force.*master/i,
  /git\s+push.*--force.*release/i,
  /git\s+push.*--force-all/i,
  /docker\s+push.*prod/i,
];

function isDeployBlocked(command) {
  return DEPLOY_PATTERNS.some(p => p.test(command));
}

describe('deploy-guard: blocks production deployments', () => {
  const blocked = [
    ['kubectl apply -f deploy.yml --context production-cluster --context prod', 'kubectl with --context prod'],
    ['kubectl apply -f k8s/ --namespace app -e production', 'kubectl apply to production'],
    ['helm install my-release chartname --set env=prod', 'helm install to prod'],
    ['helm upgrade my-release chartname --values prod-values.yml', 'helm upgrade to prod'],
    ['terraform apply -var="env=prod"', 'terraform apply without --target'],
    ['terraform apply -auto-approve', 'terraform apply with auto-approve'],
    ['aws ecs deploy --cluster my-cluster', 'AWS ECS deploy'],
    ['aws lambda deploy-function --function my-fn', 'AWS Lambda deploy'],
    ['az group deployment create --resource-group rg', 'Azure deployment create'],
    ['gcloud app deploy app.yml', 'gcloud app deploy'],
    ['gcloud run deploy my-service', 'gcloud run deploy'],
    ['git push origin --force main', 'force push to main'],
    ['git push --force origin master', 'force push to master'],
    ['git push --force origin release/v2.0', 'force push to release branch'],
    ['git push --force-all origin', 'force push all refs'],
    ['docker push myrepo/app:prod', 'docker push to prod tag'],
    ['docker push registry.io/app:prod-latest', 'docker push prod-latest'],
  ];

  for (const [cmd, label] of blocked) {
    it(`blocks: ${label}`, () => {
      assert.ok(isDeployBlocked(cmd), `Expected deploy pattern to block: "${cmd}"`);
    });
  }
});

describe('deploy-guard: allows safe commands', () => {
  const safe = [
    ['kubectl get pods --context staging', 'kubectl get (read-only)'],
    ['kubectl apply -f deploy.yml --context staging', 'kubectl apply to staging'],
    ['helm install my-release chart --set env=staging', 'helm install to staging'],
    ['terraform plan', 'terraform plan (read-only)'],
    ['terraform apply --target=module.vpc', 'terraform apply with --target (scoped)'],
    ['terraform apply -target=module.vpc', 'terraform apply with -target (standard flag)'],
    ['aws s3 ls', 'AWS S3 list (not deploy)'],
    ['aws ecs describe-services', 'AWS describe (not deploy)'],
    ['az group list', 'Azure list (not deployment create)'],
    ['gcloud compute instances list', 'gcloud list (not deploy)'],
    ['git push origin feature-branch', 'normal git push to feature'],
    ['git push origin main', 'non-force push to main'],
    ['docker build -t myapp .', 'docker build (not push)'],
    ['docker push myrepo/app:staging', 'docker push to staging (not prod)'],
    ['npm run deploy:staging', 'npm script (not matched patterns)'],
  ];

  for (const [cmd, label] of safe) {
    it(`allows: ${label}`, () => {
      assert.ok(!isDeployBlocked(cmd), `Expected safe command to pass: "${cmd}"`);
    });
  }
});
