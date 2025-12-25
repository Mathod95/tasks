# Crossplane Deployment via ArgoCD

Ce répertoire contient la configuration pour déployer Crossplane et les providers AWS via ArgoCD en utilisant un pattern Helm wrapper.

## 📋 Architecture

```
crossplane/
├── Chart.yaml                     # Définition du chart Helm avec dépendance Crossplane
├── values.yaml                    # Valeurs par défaut
├── environments/                  # Configuration par environnement
│   ├── production/values.yaml    # Config production avec tous les providers
│   └── staging/values.yaml       # Config staging avec providers essentiels
├── templates/                     # Templates Kubernetes
│   ├── providers.yaml            # Déploiement des providers AWS
│   ├── provider-configs.yaml    # Configuration des providers
│   ├── controller-config.yaml   # Optimisation des ressources
│   └── aws-credentials-secret.yaml  # Secret AWS (optionnel)
└── argocd/
    └── applicationset-crossplane.yaml  # ApplicationSet pour multi-cluster
```

## 🚀 Déploiement

### 1. Prérequis

- ArgoCD installé et configuré
- Credentials AWS configurés via External Secrets ou Sealed Secrets
- Clusters Kubernetes (production et staging)

### 2. Configuration des Credentials AWS

**Option 1: External Secrets Operator (Recommandé)**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: aws-credentials
  namespace: crossplane-system
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: aws-credentials
    creationPolicy: Owner
  data:
  - secretKey: credentials
    remoteRef:
      key: crossplane-aws-credentials
```

**Option 2: Sealed Secrets**
```bash
# Créer le secret
echo -n '[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY' | kubectl create secret generic aws-credentials \
  --namespace crossplane-system \
  --from-file=credentials=/dev/stdin \
  --dry-run=client -o yaml | kubeseal -o yaml > sealed-secret.yaml
```

**Option 3: IRSA (IAM Roles for Service Accounts) sur EKS**
```yaml
# Dans controller-config.yaml
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: aws-controller-config
spec:
  serviceAccountName: crossplane-provider-aws
  podSecurityContext:
    fsGroup: 2000
```

### 3. Déployer l'ApplicationSet

```bash
kubectl apply -f argocd/applicationset-crossplane.yaml
```

## 📦 Providers AWS Disponibles

| Provider | Description | Production | Staging |
|----------|-------------|------------|---------|
| `provider-aws-s3` | Gestion des buckets S3 | ✅ | ✅ |
| `provider-aws-eks` | Gestion des clusters EKS | ✅ | ✅ |
| `provider-aws-ec2` | Gestion des instances EC2 | ✅ | ✅ |
| `provider-aws-iam` | Gestion IAM | ✅ | ✅ |
| `provider-aws-vpc` | Gestion VPC et networking | ✅ | ✅ |
| `provider-aws-rds` | Gestion des bases de données | ✅ | ❌ |
| `provider-aws-lambda` | Gestion des fonctions Lambda | ✅ | ❌ |
| `provider-aws-cloudfront` | CDN et distribution | ✅ | ❌ |
| `provider-aws-route53` | Gestion DNS | ✅ | ❌ |

## 🔧 Personnalisation

### Ajouter un nouveau provider

1. Ajouter dans `environments/{env}/values.yaml`:
```yaml
providers:
  - name: upbound-provider-aws-sqs
    package: xpkg.upbound.io/upbound/provider-aws-sqs:v2.3.0
    enabled: true
```

2. Commit et push - ArgoCD synchronisera automatiquement

### Ajuster les ressources

Modifier dans `environments/{env}/values.yaml`:
```yaml
controllerConfig:
  resources:
    limits:
      cpu: 2
      memory: 4Gi
    requests:
      cpu: 1
      memory: 2Gi
```

### Activer le mode debug

```yaml
controllerConfig:
  debug: true
  maxReconcileRate: 5  # Réduire pour debug
```

## 📊 Monitoring

### Vérifier l'état des providers

```bash
# Lister tous les providers
kubectl get providers -n crossplane-system

# Détails d'un provider
kubectl describe provider upbound-provider-aws-eks -n crossplane-system

# Vérifier les révisions
kubectl get providerrevisions -n crossplane-system
```

### Vérifier la santé de Crossplane

```bash
# État général
kubectl get all -n crossplane-system

# Pods et leur statut
kubectl get pods -n crossplane-system -o wide

# ProviderConfig
kubectl get providerconfig -A
```

### Logs

```bash
# Logs Crossplane core
kubectl logs -n crossplane-system deployment/crossplane --tail=100 -f

# Logs RBAC Manager
kubectl logs -n crossplane-system deployment/crossplane-rbac-manager --tail=100 -f

# Logs d'un provider spécifique
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=upbound-provider-aws-eks --tail=100 -f

# Tous les logs d'un provider
stern -n crossplane-system upbound-provider-aws
```

## 🔍 Troubleshooting

### Provider ne s'installe pas

```bash
# Vérifier les events
kubectl describe provider upbound-provider-aws-eks -n crossplane-system

# Vérifier le ProviderRevision
kubectl get providerrevision -n crossplane-system

# Vérifier les conditions
kubectl get provider upbound-provider-aws-eks -n crossplane-system -o jsonpath='{.status.conditions[*]}'
```

### Problème de credentials AWS

```bash
# Vérifier que le secret existe
kubectl get secret aws-credentials -n crossplane-system
kubectl describe secret aws-credentials -n crossplane-system

# Tester la ProviderConfig
kubectl describe providerconfig default

# Vérifier les logs du provider pour les erreurs AWS
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=upbound-provider-aws-iam --tail=50
```

### Provider en CrashLoopBackOff

```bash
# Augmenter les ressources dans controllerConfig
# Vérifier les limites actuelles
kubectl top pods -n crossplane-system

# Voir les derniers logs avant le crash
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=upbound-provider-aws-eks --previous
```

### Ressources AWS ne se créent pas

```bash
# Vérifier les Managed Resources
kubectl get managed -A

# Exemple pour un bucket S3
kubectl describe bucket.s3.aws.upbound.io my-bucket

# Vérifier les events
kubectl get events -n crossplane-system --sort-by='.lastTimestamp'
```

## 🔄 Workflow GitOps

### Processus de modification

1. **Modifier la configuration**
   ```bash
   git checkout -b feature/add-sqs-provider
   vim environments/production/values.yaml
   ```

2. **Tester localement (optionnel)**
   ```bash
   helm dependency update
   helm template . -f values.yaml -f environments/staging/values.yaml
   ```

3. **Commit et Push**
   ```bash
   git add .
   git commit -m "feat: add SQS provider to production"
   git push origin feature/add-sqs-provider
   ```

4. **Merge Request et Sync ArgoCD**
   - Créer MR dans GitLab
   - Après merge, ArgoCD synchronise automatiquement

### Rollback

```bash
# Via ArgoCD UI ou CLI
argocd app rollback production-crossplane <revision>

# Ou via Git
git revert <commit>
git push
```

## 📚 Ressources utiles

- [Documentation Crossplane](https://docs.crossplane.io/)
- [Upbound Marketplace](https://marketplace.upbound.io/)
- [Provider AWS Documentation](https://docs.upbound.io/providers/provider-aws/)
- [Crossplane AWS Examples](https://github.com/crossplane/provider-aws/tree/main/examples)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## 🏷️ Versions

| Composant | Version |
|-----------|---------|
| Crossplane | v2.1.3 |
| Providers AWS | v2.3.0 |
| ArgoCD | v2.8+ |
| Kubernetes | v1.27+ |

## 🔒 Sécurité

- **Ne jamais** commiter les credentials AWS dans Git
- Utiliser IRSA sur EKS quand possible
- Rotation régulière des access keys
- Principe du moindre privilège pour les IAM policies
- Activer les audit logs Kubernetes

## 📝 Notes importantes

### Ordre de déploiement
1. Crossplane Core doit être installé en premier
2. Les Providers s'installent après
3. Les ProviderConfigs après les Providers
4. Les Managed Resources en dernier

### Limites connues
- Un seul ProviderConfig "default" par provider
- Les providers peuvent prendre 2-3 minutes à devenir healthy
- ServerSideApply requis pour éviter les conflits

## 👥 Support

Pour toute question ou problème :
1. Vérifier cette documentation
2. Consulter les logs et events
3. Créer une issue dans le repo GitOps
4. Contacter l'équipe Platform sur Slack #platform-engineering

---

## 📄 Fichiers complets

### 📁 Chart.yaml
```yaml
apiVersion: v2
name: crossplane-wrapper
description: Wrapper for crossplane-stable crossplane
type: application
version: 1.0.0
appVersion: "2.1.3"
maintainers:
  - name: Mathod
dependencies:
  - name: crossplane
    version: 2.1.3
    repository: https://charts.crossplane.io/stable
```

### 📁 values.yaml
```yaml
# Configuration par défaut du chart Crossplane
crossplane:
  enabled: true
  
  # Configuration des ressources pour Crossplane
  resourcesCrossplane:
    limits:
      cpu: 1
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

  # Configuration RBAC Manager
  rbacManager:
    deploy: true
    resources:
      limits:
        cpu: 100m
        memory: 256Mi
      requests:
        cpu: 50m
        memory: 128Mi

# Liste des providers AWS à installer
providers: []  # Override par environnement

# Configuration AWS
aws:
  region: eu-west-1  # Région par défaut

# Configuration du provider AWS
providerConfig:
  aws:
    credentials:
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: aws-credentials
        key: credentials

# ControllerConfig pour optimiser les ressources des providers
controllerConfig:
  enabled: false  # Override par environnement
  debug: false
  maxReconcileRate: 10
  resources:
    limits:
      cpu: 500m
      memory: 1Gi
    requests:
      cpu: 250m
      memory: 512Mi

# Gestion du secret AWS (utiliser External Secrets en production)
awsCredentials:
  create: false  # Ne pas créer via Helm en production
  credentials: ""  # Will be set via sealed-secrets or external-secrets
```

### 📁 environments/production/values.yaml
```yaml
# Configuration Crossplane pour Production
crossplane:
  resourcesCrossplane:
    limits:
      cpu: 2
      memory: 2Gi
    requests:
      cpu: 1
      memory: 1Gi

  rbacManager:
    deploy: true
    resources:
      limits:
        cpu: 200m
        memory: 512Mi
      requests:
        cpu: 100m
        memory: 256Mi

# Providers AWS pour Production
providers:
  - name: upbound-provider-aws-s3
    package: xpkg.upbound.io/upbound/provider-aws-s3:v2.3.0
    enabled: true
  - name: upbound-provider-aws-eks
    package: xpkg.upbound.io/upbound/provider-aws-eks:v2.3.0
    enabled: true
  - name: upbound-provider-aws-ec2
    package: xpkg.upbound.io/upbound/provider-aws-ec2:v2.3.0
    enabled: true
  - name: upbound-provider-aws-iam
    package: xpkg.upbound.io/upbound/provider-aws-iam:v2.3.0
    enabled: true
  - name: upbound-provider-aws-rds
    package: xpkg.upbound.io/upbound/provider-aws-rds:v2.3.0
    enabled: true
  - name: upbound-provider-aws-lambda
    package: xpkg.upbound.io/upbound/provider-aws-lambda:v2.3.0
    enabled: true
  - name: upbound-provider-aws-vpc
    package: xpkg.upbound.io/upbound/provider-aws-vpc:v2.3.0
    enabled: true
  - name: upbound-provider-aws-cloudfront
    package: xpkg.upbound.io/upbound/provider-aws-cloudfront:v2.3.0
    enabled: true
  - name: upbound-provider-aws-route53
    package: xpkg.upbound.io/upbound/provider-aws-route53:v2.3.0
    enabled: true

aws:
  region: eu-west-1

# ControllerConfig pour optimiser les performances
controllerConfig:
  enabled: true
  debug: false
  maxReconcileRate: 20
  resources:
    limits:
      cpu: 1
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 1Gi

# Ne pas créer le secret via Helm (utiliser External Secrets)
awsCredentials:
  create: false
```

### 📁 environments/staging/values.yaml
```yaml
# Configuration Crossplane pour Staging
crossplane:
  resourcesCrossplane:
    limits:
      cpu: 1
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

  rbacManager:
    deploy: true
    resources:
      limits:
        cpu: 100m
        memory: 256Mi
      requests:
        cpu: 50m
        memory: 128Mi

# Providers AWS pour Staging (subset de production)
providers:
  - name: upbound-provider-aws-s3
    package: xpkg.upbound.io/upbound/provider-aws-s3:v2.3.0
    enabled: true
  - name: upbound-provider-aws-eks
    package: xpkg.upbound.io/upbound/provider-aws-eks:v2.3.0
    enabled: true
  - name: upbound-provider-aws-ec2
    package: xpkg.upbound.io/upbound/provider-aws-ec2:v2.3.0
    enabled: true
  - name: upbound-provider-aws-iam
    package: xpkg.upbound.io/upbound/provider-aws-iam:v2.3.0
    enabled: true
  - name: upbound-provider-aws-vpc
    package: xpkg.upbound.io/upbound/provider-aws-vpc:v2.3.0
    enabled: true

aws:
  region: eu-west-1

# ControllerConfig avec moins de ressources
controllerConfig:
  enabled: true
  debug: true  # Debug activé en staging
  maxReconcileRate: 10
  resources:
    limits:
      cpu: 500m
      memory: 1Gi
    requests:
      cpu: 250m
      memory: 512Mi

awsCredentials:
  create: false
```

### 📁 templates/providers.yaml
```yaml
{{- range .Values.providers }}
{{- if .enabled }}
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: {{ .name }}
  namespace: crossplane-system
  labels:
    app.kubernetes.io/name: {{ .name }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
spec:
  package: {{ .package }}
  {{- if $.Values.controllerConfig.enabled }}
  controllerConfigRef:
    name: aws-controller-config
  {{- end }}
  # Politique de mise à jour
  revisionActivationPolicy: Automatic
  revisionHistoryLimit: 1
  packagePullPolicy: IfNotPresent
{{- end }}
{{- end }}
```

### 📁 templates/provider-configs.yaml
```yaml
{{- $awsProviders := list "upbound-provider-aws-s3" "upbound-provider-aws-eks" "upbound-provider-aws-ec2" "upbound-provider-aws-iam" "upbound-provider-aws-rds" "upbound-provider-aws-lambda" "upbound-provider-aws-vpc" "upbound-provider-aws-cloudfront" "upbound-provider-aws-route53" }}
{{- $providerFound := false }}
{{- range .Values.providers }}
  {{- if and .enabled (has .name $awsProviders) }}
    {{- $providerFound = true }}
  {{- end }}
{{- end }}

{{- if $providerFound }}
---
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
  namespace: crossplane-system
  labels:
    app.kubernetes.io/name: provider-config-aws
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
spec:
  region: {{ .Values.aws.region }}
  credentials:
    source: {{ .Values.providerConfig.aws.credentials.source }}
    secretRef:
      namespace: {{ .Values.providerConfig.aws.credentials.secretRef.namespace }}
      name: {{ .Values.providerConfig.aws.credentials.secretRef.name }}
      key: {{ .Values.providerConfig.aws.credentials.secretRef.key }}
{{- end }}
```

### 📁 templates/controller-config.yaml
```yaml
{{- if .Values.controllerConfig.enabled }}
---
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: aws-controller-config
  namespace: crossplane-system
  labels:
    app.kubernetes.io/name: controller-config
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
spec:
  args:
    - --debug={{ .Values.controllerConfig.debug }}
    - --max-reconcile-rate={{ .Values.controllerConfig.maxReconcileRate }}
  resources:
    limits:
      cpu: {{ .Values.controllerConfig.resources.limits.cpu }}
      memory: {{ .Values.controllerConfig.resources.limits.memory }}
    requests:
      cpu: {{ .Values.controllerConfig.resources.requests.cpu }}
      memory: {{ .Values.controllerConfig.resources.requests.memory }}
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 65532
    runAsGroup: 65532
    fsGroup: 65532
{{- end }}
```

### 📁 templates/aws-credentials-secret.yaml
```yaml
{{- if .Values.awsCredentials.create }}
---
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: crossplane-system
  labels:
    app.kubernetes.io/name: aws-credentials
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
type: Opaque
data:
  credentials: {{ .Values.awsCredentials.credentials | b64enc }}
{{- end }}
```

### 📁 argocd/applicationset-crossplane.yaml
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: crossplane
  namespace: argocd
  labels:
    app.kubernetes.io/name: crossplane
    app.kubernetes.io/part-of: infrastructure
spec:
  generators:
  - list:
      elements:
      - cluster: production
        url: https://kubernetes.default.svc
        namespace: crossplane-system
      - cluster: staging
        url: https://staging.k8s.mathod.io  # Remplace par ton URL staging
        namespace: crossplane-system
  template:
    metadata:
      name: '{{cluster}}-crossplane'
      labels:
        environment: '{{cluster}}'
        app.kubernetes.io/name: crossplane
        app.kubernetes.io/instance: '{{cluster}}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: infrastructure  # Ou ton projet ArgoCD
      source:
        repoURL: https://gitlab.com/mathod/infrastructure  # Ton repo GitOps
        targetRevision: main
        path: crossplane
        helm:
          valueFiles:
          - values.yaml
          - environments/{{cluster}}/values.yaml
          # Update dependencies avant de déployer
          skipCrds: false
      destination:
        server: '{{url}}'
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
          allowEmpty: false
        syncOptions:
        - CreateNamespace=true
        - ServerSideApply=true
        - RespectIgnoreDifferences=true
        retry:
          limit: 5
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
      revisionHistoryLimit: 3
      # Ignoré les différences sur les status
      ignoreDifferences:
      - group: pkg.crossplane.io
        kind: Provider
        jsonPointers:
        - /status
      - group: aws.upbound.io
        kind: ProviderConfig
        jsonPointers:
        - /status
```

---
*Dernière mise à jour: Décembre 2024*
*Maintenu par: Mathod - Platform Engineering*