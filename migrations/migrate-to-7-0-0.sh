#!/bin/sh
set -eu

#
# Precondition: The module call has been extracted to a separate file given in "$1". The code is well-formatted.
#               Run `terraform fmt` to do that
#
# $1: file name containing the module call to be converted
#

converted_file="$1.new"

cp "$1" "$converted_file"

#
# PR #738 chore!: remove deprecated variables
#
sed -i '/arn_format/d' "$converted_file"
sed -i '/subnet_id_runners/d' "$converted_file"
sed -i '/subnet_ids_gitlab_runner/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_hook_create/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_hook_heartbeat_timeout/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_memory_size/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_runtime/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_timeout/d' "$converted_file"

#
# PT #757 refactor!: rename variables and prefix with agent, executor and global scope
#
sed -i '/aws_region/d' "$converted_file"

sed 's/enable_kms/enable_managed_kms_key/g' "$converted_file" | \
sed 's/kms_alias_name/kms_managed_alias_name/g' | \
sed 's/kms_deletion_window_in_days/kms_managed_deletion_rotation_window_in_days/g' | \
sed 's/permission_boundary/iam_permission_boundary/g' | \
sed 's/extra_security_group_ids_runner_agent/agent_extra_security_group_ids/g' | \
sed 's/instance_type/agent_instance_type/g' | \
sed 's/runner_instance_ebs_optimized/agent_ebs_optimized/g' | \
sed 's/runner_instance_enable_monitoring/agent_enable_monitoring/g' | \
sed 's/runner_instance_metadata_options/agent_metadata_options/g' | \
sed 's/runners_userdata/executor_docker_machine_userdata/g' | \
sed 's/runners_executor/executor_type/g' | \
sed 's/runners_install_amazon_ecr_credential_helper/agent_install_amazon_ecr_credential_helper/g' | \
sed 's/runners_clone_url/agent_gitlab_clone_url/g' | \
sed 's/runners_gitlab_url/agent_gitlab_url/g' | \
sed 's/runners_max_builds/executor_max_builds/g' | \
sed 's/runners_idle_count/executor_idle_count/g' | \
sed 's/runners_idle_time/executor_idle_time/g' | \
sed 's/runners_concurrent/agent_maximum_concurrent_jobs/g' | \
sed 's/runners_limit/executor_max_jobs/g' | \
sed 's/runners_check_interval/agent_gitlab_check_interval/g' | \
sed 's/sentry_dsn/agent_sentry_dsn/g' | \
sed 's/prometheus_listen_address/agent_prometheus_listen_address/g' | \
sed 's/runner_extra_config/agent_user_data_extra/g' | \
sed 's/runners_ca_certificate/agent_gitlab_ca_certificate/g' | \
sed 's/runners_yum_update/agent_yum_update/g' | \
sed 's/runners_gitlab_certificate/runners_gitlab_certificate/g' | \
sed 's/asg_terminate_lifecycle_hook_name/agent_terminate_ec2_lifecycle_hook_name/g' | \
sed 's/runner_iam_policy_arns/agent_extra_iam_policy_arns/g' | \
sed 's/create_runner_iam_role/agent_create_runner_iam_role_profile/g' | \
sed 's/runner_iam_role_name/agent_iam_role_profile_name/g' | \
sed 's/enable_eip/agent_enable_eip/g' | \
sed 's/enable_runner_ssm_access/agent_enable_ssm_access/g' | \
sed 's/enable_runner_user_data_trace_log/agent_user_data_enable_trace_log/g' | \
sed 's/enable_schedule/agent_schedule_enable/g' | \
sed 's/schedule_config/agent_schedule_config/g' | \
sed 's/runner_root_block_device/agent_root_block_device/g' | \
sed 's/gitlab_runner_registration_config/agent_gitlab_registration_config/g' | \
sed 's/[^_]ami_filter/agent_ami_filter/g' | \
sed 's/[^_]ami_owners/agent_ami_owners/g' | \
sed 's/runner_ami_filter/executor_docker_machine_ami_filter/g' | \
sed 's/runner_ami_owners/executor_docker_machine_ami_owners/g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

# overrides block
extracted_variables=$(grep -E '(name_sg|name_iam_objects|name_runner_agent_instance|name_docker_machine_runners)' "$converted_file")

extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/name_sg/security_group_prefix/g' | \
                      sed 's/name_iam_objects/iam_object_prefix/g' | \
                      sed 's/name_runner_agent_instance/agent_instance_prefix/g' | \
                      sed 's/name_docker_machine_runners/executor_docker_machine_instance_prefix/g'
                    )

sed '/name_sg/d' "$converted_file" | \
sed '/name_iam_objects/d' | \
sed '/name_runner_agent_instance/d' | \
sed '/name_docker_machine_runners/d' | \
sed '/overrides = {/d' \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

echo "$(head -n -1 "$converted_file")
  $extracted_variables
}" > "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"
