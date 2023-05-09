# K8S Openldap Deplyment (03.04~18.04)
Using helm chart install openldap, ldapphpadmin, and self-password modify(forgetPasssword)

## Prerequire
1. Kubernetes Cluster (with storageClass)
2. PV

## Install Helm in Ubuntu/Debian [Ref.](https://helm.sh/docs/intro/install/)
```
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Install Openldap chart from GitHub
[Ref.](https://artifacthub.io/packages/helm/helm-openldap/openldap)
```
git clone https://github.com/jp-gouin/helm-openldap.git
cd helm-openldap
helm install openldap .
```

## Check the installation status of the charts
1. check pods `kubectl get pods -A`
2. check pvc `kubectl get pvc -A`
3. check pv `kubectl get pv -A`
4. check service `kubectl get service -A`

## Setting PVC bound to PV (optinal)
[Volume setting Ref.](https://qiita.com/ysakashita/items/67a452e76260b1211920    )
1. `kubectl edit pvc <openldapPVCName>`

PVC example
```yaml=
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  creationTimestamp: "2023-04-15T17:11:36Z"
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app.kubernetes.io/component: test
    app.kubernetes.io/instance: test
    app.kubernetes.io/name: openldap-stack-ha
  name: data-test-2
  namespace: default
  resourceVersion: "295477"
  uid: b28c7be2-67d2-4f3f-9a4b-cd0f7176f9e2
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8G
  storageClassName: local-storage # storageClass setting
  volumeMode: Filesystem
  volumeName: local-pv3 #connect to which pv
```

## Setting Service and Ingress to port forwarding
1. GKE servsion
    I. Go to Service page
    II. `choose the phpadmin` and `self-password modify` service
    III. Settig yaml from `ClusterPort` or `NodePort` to `Loadbalancer`
    IV. Back to Service page use the loadbalancer url to access service
2. Local version
    I. Edit service yaml with `kubectl edit service <serviceName>` from `ClusterPort` to `NodePort`
    II. Use local browser to access service
    
## Setting the LDAP connector for dex (25.04~09.05)
---
#### pre-require *Kubeflow*
---
1. Access into the dex to get the configmap file
`kubectl exec -it -n auth dex-787856df6-ts7kd -- /bin/sh`
`kubectl get deploy -n auth dex`
2. Get the configmap of dex as **dex-config.yaml**
`kubectl get cm -n auth dex -o jsonpath='{.data.config\.yaml}' > dex-config.yaml`
3. edit **dex-config.yaml** add connectors attribute
```yaml= 
connectors:
- type: ldap
  id: ldap
  name: LDAP
  config:
    host: openldap.default.svc.cluster.local:389
    insecureNoSSL: true
    insecureSkipVerify: true
    startTLS: false
    redirectURI: https://120.126.23.245/
    bindDN: cn=admin,dc=example,dc=org #admin dn
    bindPW: Not@SecurePassw0rd # admin password
    usernamePrompt: example Username
    userSearch:
      baseDN: ou=users,dc=example,dc=org
      filter: "(objectClass=inetOrgPerson)"
      username: cn
      idAttr: DN
      emailAttr: mail
      nameAttr: cn
    groupSearch:
      baseDN: ou=Groups,dc=example,dc=org
      filter: "(objectClass=groupOfNames)"
      userMatchers:
      - userAttr: cn
        groupAttr: member
      nameAttr: cn
```
4. apply the new configmap to dex
`kubectl create configmap dex --from-file=config.yaml=dex-config.yaml -n auth --dry-run -oyaml | kubectl apply -f -`
5. Restart dex deployment
`kubectl rollout restart deployment dex -n auth`
