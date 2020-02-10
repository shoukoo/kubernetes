#!/bin/bash 

set -exuo pipefail

for instance in controller-0 controller-1 controller-2 ; do
  external_ip=$(aws ec2 --region=${AWS_REGION} describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
  scp -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    server_controller_plane.sh ubuntu@$external_ip:~/

  ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    ubuntu@$external_ip bash server_controller_plane.sh

  # verifying etcd is installed on all the controller servers
  if [ ${instance} == "controller-2" ]; then
    sleep 30
    ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ubuntu@$external_ip <<'EOF'
        set -ex
        count=$(kubectl get componentstatuses | tail -n +2 | grep Healthy | wc -l)
        if ! [[ $count -eq 5 ]]; then
          echo "Controller Plane is not healthy"
        fi
EOF
  fi

done
