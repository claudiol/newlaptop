# Uninstall for MultiCloud-GitOps pattern using ArgoCD CLI manually in the Hub Cluster
# Login to openshift-gitops argocd server instance
# Turn off the auto-sync policy
argocd login --grpc-web $(oc get routes -n openshift-gitops openshift-gitops-server -o=jsonpath='{ .spec.host }') --sso
argocd app set --grpc-web  multicloud-gitops-hub --sync-policy none
sleep 2

# Login to multicloud-gitops hub argocd server instance
argocd login $(oc get routes -n multicloud-gitops-hub hub-gitops-server -o=jsonpath='{ .spec.host }') --sso
APPLIST=$(argocd app list --grpc-web | grep -v NAME | awk '{ print $1 }')

for app in $APPLIST;
do
  echo "Deleting Argocd application [$app] ..."
  argocd app delete --grpc-web $app --cascade -p foreground --yes
  while [ 1 ]; do
    exists=$(argocd app list --grpc-web | grep -v NAME | grep $app | awk '{print $1}')
    if [ "$exists." == "." ]; then
      break;
    fi
    sleep 2
  done
done 

#argocd app delete vault --cascade -p foreground --yes
#argocd app delete config-demo --yes  --cascade -p foreground
#argocd app delete acm --yes  --cascade -p foreground

# Login to openshift-gitops argocd server instance
argocd login  --grpc-web $(oc get routes -n openshift-gitops openshift-gitops-server -o=jsonpath='{ .spec.host }') --sso
argocd app list --grpc-web
argocd app delete multicloud-gitops-hub --cascade --yes -p foreground --grpc-web
while [ 1 ]; do
  exists=$(argocd app list --grpc-web | grep -v NAME | grep multicloud-gitops-hub | awk '{print $1}')
  if [ "$exists." == "." ]; then
    break;
  fi
  sleep 2
done

#
# THIS IS NO MANS LAND AT THIS POINT :)
# Still testing this portion this morning.
#
#oc get sub -n openshift-operators
#oc delete sub/openshift-gitops-operator -n openshift-operators
#oc get  csv -n openshift-operators
#oc delete  csv/openshift-gitops-operator.v1.5.4 -n openshift-operators
#oc patch -n openshift-gitops application.argoproj.io/multicloud-gitops-hub --type=merge -p '{"metadata": {"finalizers":null}}'
#oc api-resources --verbs=list --namespaced -o name | xargs -t -n 1 oc get --show-kind --ignore-not-found -n openshift-gitops

#
# This is an attempt to see if uninstalling the chart also uninstalls the subscription to openshift-gitops
#
oc project default
helm uninstall multicloud-gitops

#
# 
sleep 5

# Let's check some of the expected debris from opehsift-gitops

LEFTOVERS=$(oc get all,deploy,pods -n openshift-gitops | grep -v NAME | awk 'NF { print $1}')

for left in $LEFTOVERS; do
  echo "namespace: openshift-gitops debris: $left"
done

echo "Secrets left behind"
SECRETSLEFT=$(oc get --show-kind --ignore-not-found -n openshift-gitops secrets)
for left in $SECRETSLEFT; do
  echo "namespace: openshift-gitops debris: $left"
done




#oc delete replicasets,subscriptions,deployments,jobs,services,pods --all -n openshift-gitops
# Clean up openshift-gitops pods
#oc project openshift-gitops
#oc get all,deploy,pods | grep -v NAME | awk 'NF { print $1}' | xargs oc delete
#oc get projects | grep -i term

# Clean up secrets for openshift-gitops
# oc get --show-kind --ignore-not-found -n openshift-gitops secrets
#oc get --show-kind --ignore-not-found -n openshift-gitops secrets | grep -v NAME | awk '{print $1}' | xargs oc delete -n openshift-gitops

# Clean up serviceaccounts for openshift-gitops
#oc get --show-kind --ignore-not-found -n openshift-gitops serviceaccounts | grep -v NAME | awk '{ print $1 }' | xargs oc delete 
