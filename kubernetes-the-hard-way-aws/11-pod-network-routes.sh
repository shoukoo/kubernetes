#!/bin/bash 

# https://github.com/prabhatsharma/kubernetes-the-hard-way-aws/blob/master/docs/11-pod-network-routes.md
# Pods scheduled to a node receive an IP address from the node's Pod CIDR range.
# At this point pods can not communicate with other pods running on different nodes due to missing network routes.
# In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

set -exuo pipefail

route_table_id=$(aws --region=ap-southeast-2 ec2 describe-route-tables --filter Name=tag-value,Values=kubernetes --query "RouteTables[*].RouteTableId" --output text)

for instance in worker-0 worker-1 worker-2; do
  instance_id_ip="$(aws --region=ap-southeast-2 ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" "Name=instance-state-name,Values=running"\
    --output text --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,SubnetId]')"
  instance_id="$(echo "${instance_id_ip}" | cut -f1)"
  instance_ip="$(echo "${instance_id_ip}" | cut -f2)"
  subnet_id="$(echo "${instance_id_ip}" | cut -f3)"

  pod_cidr="$(aws --region=ap-southeast-2 ec2 describe-instance-attribute \
    --instance-id "${instance_id}" \
    --attribute userData \
    --output text --query 'UserData.Value' \
    | base64 --decode | tr "|" "\n" | grep "^pod-cidr" | cut -d'=' -f2)"
  echo "${instance_ip} ${pod_cidr}"

  aws --region=ap-southeast-2 ec2 create-route \
      --route-table-id "${route_table_id}" \
      --destination-cidr-block "${pod_cidr}" \
      --instance-id "${instance_id}"
done

count=$(aws --region=ap-southeast-2 ec2 describe-route-tables \
  --route-table-ids "${route_table_id}" \
  --query 'RouteTables[].Routes' | grep "10.200.[0-9].0" | wc -l)

if ! [[ $count -eq 3 ]]; then 
  echo "Routes is missing"
  exit 1
fi
