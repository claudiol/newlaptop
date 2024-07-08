# Uninstall for Validated Pattern using ArgoCD CLI manually in the Hub Cluster
# Login to openshift-gitops argocd server instance
# Turn off the auto-sync policy

argocd login --grpc-web $(oc get routes -n openshift-gitops openshift-gitops-server -o=jsonpath='{ .spec.host }') --sso

# We are going to delete the resources from the main argocd application that we 
# install on the openshift-gitops ArgoCD instance 

MAIN_PATTERN_APP=$(argocd app list --grpc-web | grep -v NAME | awk '{ print $1 }')

argocd app set --grpc-web $MAIN_PATTERN_APP --sync-policy none
sleep 2

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
#   \033[0K\r - Trailing escape sequence to leave output on the same line
function log {
    if [ -z "$2" ]; then
        echo -e "\033[0K\r\033[1;36m$1\033[0m"
    else
        echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
    fi
}


function uninstallHelmChart {
    if [ $# -lt 1  ]; then
	echo "Need helm chart name as argument"
	return
    fi
    
    HELM=$(which helm 2>$)
    if [ $? != 0 ]; then
	echo "Cannot check for helm charts. Helm is not installed"
	return
    fi

    helm uninstall $1 -n default
}

function deleteArgoCDResource {
    if [ $# -lt 1 ]; then
	echo "Need argument for Kind"
	return
    fi
    RESOURCE=$1
    APPRESOURCES=""

    if [ "$RESOURCE" == "Namespace" ]; then
	APPRESOURCES=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | awk '{print $2}')
    elif [ "$RESOURCE" == "ConfigMap" ] || [ "$RESOURCE" == "ServiceAccount" ] || [ "$RESOURCE" == "ConsoleLink" ] || [ "$RESOURCE" == "ClusterRole" ] || [ "$RESOURCE" == "ClusterRoleBinding" ] ; then
	APPRESOURCES=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | awk '{print $3}')
    else
	APPRESOURCES=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | awk '{print $4}')
    fi

    
    if [ "$APPRESOURCES." == "." ]; then
	echo "Something went wrong ... no applications found"
	return
    fi

    #
    # Let's loop through the applications and delete the resources
    #
    for resource in $APPRESOURCES
    do
	if [ "$RESOURCE" == "Namespace" ]; then
    	    GROUP=""
	    KIND=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $1}')
	    NAMESPACE=""
	elif [ "$RESOURCE" == "ConfigMap" ]; then
	    GROUP=""
	    KIND=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $1}')
	    NAMESPACE=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $2}')
	elif [ "$RESOURCE" == "ServiceAccount" ]; then
	    GROUP=""
	    KIND=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $1}')
	    NAMESPACE=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $2}')
	elif [ "$RESOURCE" == "ConsoleLink" ] || [ "$RESOURCE" == "ClusterRole" ] || [ "$RESOURCE" == "ClusterRoleBinding" ]; then
	    GROUP=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $1}')
	    KIND=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $2}')
	    NAMESPACE=""
	else
	    GROUP=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $1}')
	    KIND=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $2}')
	    NAMESPACE=$(argocd app resources $MAIN_PATTERN_APP | grep -v NAME | grep " $RESOURCE " | grep " $resource " | awk '{print $3}')
	fi
	echo "Telling ArgoCD to delete [$GROUP:$KIND:$resource]"
	
	if [ "$resource." != "." ]; then
	    if [ "$RESOURCE" == "Namespace" ]; then
		EXISTS=$(oc get ns/$resource 2>&1 )
	    elif [ "$RESOURCE" == "ConfigMap" ]; then
		EXISTS=$(oc get cm/$resource 2>&1 )
	    elif [ "$RESOURCE" == "ServiceAccount" ]; then
		EXISTS=$(oc get sa/$resource 2>&1 )
	    else
		# Let's check with OpenShift to see if the resource is there
		EXISTS=$(oc get $KIND/$resource 2>&1 )
	    fi
	    
	    if [[ $EXISTS == *"not found"* ]]; then
		echo "Resource [$resource] does not exist in OpenShift. Probably deleted"
                echo "Result: $EXISTS"
	    else
	    
		argocd app delete-resource $MAIN_PATTERN_APP --kind $KIND --resource-name $resource #--namespace $resource
		if [ $? == 0 ]; then
		    echo "Deleted resource [$GROUP:$KIND:$resource]."
		    if [ "$RESOURCE" == "Namespace" ]; then
			EXISTS=$(oc get ns/$resource 2>&1 )
		    elif [ "$RESOURCE" == "ConfigMap" ]; then
			EXISTS=$(oc get cm/$resource 2>&1 )
		    elif [ "$RESOURCE" == "ServiceAccount" ]; then
			EXISTS=$(oc get sa/$resource 2>&1 )
		    else
			# Let's check with OpenShift to see if the resource is there
			EXISTS=$(oc get $KIND/$resource 2>&1 )
		    fi
		    
		    while [[ "$EXISTS" != *"not found"* ]]
		    do
			log -n "Waiting on resource [$resource] to be deleted from OpenShift ###"
			sleep 2
			PROGRESS=$(oc get ns/$resource 2>&1 | grep -v NAME | awk 'print $3}' 2>&1 )
			# Special case but probably not a great solution
			if [[ "$PROGRESS" == *"Missing"* ]]; then
			  oc patch $KIND/$resource --type=merge -p '{"metadata": {"finalizers":null}}'
			fi
			
			if [ "$RESOURCE" == "Namespace" ]; then
			    EXISTS=$(oc get ns/$resource 2>&1 )
			elif [ "$RESOURCE" == "ConfigMap" ]; then
			    EXISTS=$(oc get cm/$resource 2>&1 )
			elif [ "$RESOURCE" == "ServiceAccount" ]; then
			    EXISTS=$(oc get sa/$resource 2>&1 )
			else
			    # Let's check with OpenShift to see if the resource is there
			    EXISTS=$(oc get $KIND/$resource  2>&1 )
			fi
			#echo "$EXISTS"
			log -n "Waiting on resource [$resource] to be deleted from OpenShift #  "
			sleep 2
		    done
		else
		    log "Error deleting resource [$resource]"
		fi
	    fi
	fi
    done

}

log "Removing resources from the pattern application [$MAIN_PATTERN_APP]"

oc project $MAIN_PATTERN_APP 2>&1 > /dev/null

log "Let's get all the applications first ..."
deleteArgoCDResource Application

# Now let's do app projects
log "Deleting AppProjects resources"
deleteArgoCDResource AppProject

# Now we start deleting OperatorGroup
log "Deleting OperatorGroup resources"
deleteArgoCDResource OperatorGroup

# ClusterRole
log "Deleting ClusterRole resources"
deleteArgoCDResource ClusterRole

# ClusterRoleBinding
log "Deleting ClusterRoleBinding resources"
deleteArgoCDResource ClusterRoleBinding

# Role
log "Deleting Role resources"
deleteArgoCDResource Role

# RoleBinding
log "Deleting RoleBinding resources"
deleteArgoCDResource RoleBinding

# ServiceAccount
log "Deleging ServiceAccount resources"
deleteArgoCDResource ServiceAccount

# ConfigMap
log "Deleting ConfigMap"
deleteArgoCDResource ConfigMap

# CronJob
log "Deleting CronJob resources"
deleteArgoCDResource CronJob

# ConsoleLink
log "Deleting ConsoleLink resources"
deleteArgoCDResource ConsoleLink

# Subscription
log "Deleting Subscription resources"
deleteArgoCDResource Subscription

# Finally namespaces
log "Deleting Namespace resouces"
deleteArgoCDResource Namespace

# Check to see if there's a helm chart
# This will delete openshift-gitops subscription.
# But it leaves the operator subscription waiting for the CSV to get deleted.
# Everything in openshift-gitops seems to continue to run.
# If the pattern was deployed by the operator having the openshift-gitops subscription
# does not matter and the operator will install the rest.
# If done via make install then the initial helm chart will be upgraded and it should work.
# So we will not delete it for now.
#echo "Checking for helm chart. Uninstall helm chart if it exist"
#uninstallHelmChart $(shell basename `pwd`)

echo "Final step: removing $MAIN_PATTERN_APP"
argocd app delete $MAIN_PATTERN_APP -y
oc project openshift-operators
oc delete gitopsservice cluster -n openshift-gitops
oc delete deployment gitops-operator-controller-manager
echo "Done"
exit

# Output expected from argocd CLI
#
# $ argocd app resources $(argocd app list | grep -v NAME | awk '{print $1}') | grep -v NAME 
#                            ConfigMap           imperative               helm-values-configmap                            No
#                            Namespace                                    config-demo                                      No
#                            Namespace                                    golang-external-secrets                          No
#                            Namespace                                    imperative                                       No
#                            Namespace                                    multicloud-gitops-hub                            No
#                            Namespace                                    open-cluster-management                          No
#                            Namespace                                    vault                                            No
#                            ServiceAccount      imperative               imperative-sa                                    No
# argoproj.io                AppProject          multicloud-gitops-hub    config-demo                                      No
# argoproj.io                AppProject          multicloud-gitops-hub    hub                                              No
# argoproj.io                Application         multicloud-gitops-hub    acm                                              No
# argoproj.io                Application         multicloud-gitops-hub    config-demo                                      No
# argoproj.io                Application         multicloud-gitops-hub    golang-external-secrets                          No
# argoproj.io                Application         multicloud-gitops-hub    vault                                            No
# argoproj.io                ArgoCD              multicloud-gitops-hub    hub-gitops                                       No
# batch                      CronJob             imperative               imperative-cronjob                               No
# console.openshift.io       ConsoleLink                                  hub-gitops-link                                  No
# operators.coreos.com       OperatorGroup       config-demo              config-demo-operator-group                       No
# operators.coreos.com       OperatorGroup       golang-external-secrets  golang-external-secrets-operator-group           No
# operators.coreos.com       OperatorGroup       open-cluster-management  open-cluster-management-operator-group           No
# operators.coreos.com       OperatorGroup       vault                    vault-operator-group                             No
# operators.coreos.com       Subscription        open-cluster-management  advanced-cluster-management                      No
# rbac.authorization.k8s.io  ClusterRole                                  imperative-cluster-role                          No
# rbac.authorization.k8s.io  ClusterRoleBinding                           imperative-cluster-admin-rolebinding             No
# rbac.authorization.k8s.io  ClusterRoleBinding                           multicloud-gitops-hub-cluster-admin-rolebinding  No
# rbac.authorization.k8s.io  ClusterRoleBinding                           openshift-gitops-cluster-admin-rolebinding       No
# rbac.authorization.k8s.io  Role                imperative               imperative-role                                  No
# rbac.authorization.k8s.io  RoleBinding         imperative               imperative-admin-rolebinding                     No


