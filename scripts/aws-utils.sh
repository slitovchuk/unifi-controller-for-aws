#!/bin/sh

restart_unifi_controller()
{
    docker service update --force unifi_controller
}

get_ssl_cert()
{
    docker run --rm -d -p 443:443 -p 80:80 --name certbot -v "ubnt_letsencrypt:/etc/letsencrypt" -v "ubnt_letsencrypt-var:/var/lib/letsencrypt" -v "ubnt_letsencrypt-log:/var/log/letsencrypt" -v "ubnt_unifi-cert:/unifi-cert" certbot/certbot certonly --standalone --noninteractive --agree-tos --email ${CERTBOT_EMAIL} -d ${CERTBOT_DOMAIN} --deploy-hook 'cp "${RENEWED_LINEAGE}/"*.pem /unifi-cert' -v --test-cert --force-renewal
}

mount_efs()
{
    sudo mkdir -p /mnt/efs/reg /mnt/efs/max && sudo chown -R ec2-user:ec2-user /mnt/efs/
    sudo mount -t nfs4 -o rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${EFS_ID_REGULAR}.efs.us-east-1.amazonaws.com:/ /mnt/efs/reg/
    sudo mount -t nfs4 -o rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${EFS_ID_MAXIO}.efs.us-east-1.amazonaws.com:/ /mnt/efs/max/
}

install_cloudstor_plugin()
{
    docker plugin install --alias cloudstor:aws --grant-all-permissions docker4x/cloudstor:17.10.0-ce-aws1 CLOUD_PLATFORM=AWS EFS_ID_REGULAR=${EFS_ID_REGULAR} EFS_ID_MAXIO=${EFS_ID_MAXIO} DEBUG=1
}

update_stack()
{
    aws cloudformation deploy --template-file uni-stack.yml --stack-name uni-stack --capabilities CAPABILITY_IAM
}

update_stack_policy()
{
    aws cloudformation set-stack-policy --stack-name uni-stack --stack-policy-body file://uni-stack-policy.json
}

create_changeset()
{
    aws cloudformation create-change-set --stack-name uni-stack --template-body file://uni-stack.yml --change-set-name ${1} --description "${2}" --change-set-type UPDATE --parameters ParameterKey="KeyName",UsePreviousValue='true' ParameterKey="Subnets",UsePreviousValue='true' ParameterKey="VpcId",UsePreviousValue='true' ParameterKey="DomainOwnerEmail",UsePreviousValue='true' ParameterKey="DomainName",UsePreviousValue='true' ParameterKey="SSHLocation",UsePreviousValue='true' --capabilities CAPABILITY_IAM
}

execute_changeset()
{
    aws cloudformation execute-change-set --stack-name uni-stack --change-set-name ${1}
}
