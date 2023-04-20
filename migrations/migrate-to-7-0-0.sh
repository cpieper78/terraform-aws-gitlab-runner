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
#  PR #711 feat!: refactor Docker Machine autoscaling options
#
sed -i 's/runners_machine_autoscaling/runners_machine_autoscaling_options/g' "$converted_file"

#
# PR #710 chore!: remove old variable `runners_pull_policy`
#
sed -i '/runners_pull_policy/d' "$converted_file"

#
# PR #511 feat!: allow to set all docker options for the Executor
#
extracted_variables=$(grep -E '(runners_pull_policies|runners_docker_runtime|runners_helper_image|runners_shm_size|runners_shm_size|runners_extra_hosts|runners_disable_cache|runners_image|runners_privileged)' "$converted_file")

sed -i '/runners_image/d' "$converted_file"
sed -i '/runners_privileged/d' "$converted_file"
sed -i '/runners_disable_cache/d' "$converted_file"
sed -i '/runners_extra_hosts/d' "$converted_file"
sed -i '/runners_shm_size/d' "$converted_file"
sed -i '/runners_docker_runtime/d' "$converted_file"
sed -i '/runners_helper_image/d' "$converted_file"
sed -i '/runners_pull_policies/d' "$converted_file"

# content to be added to `volumes`
volumes=$(grep "runners_additional_volumes" "$converted_file" | cut -d '=' -f 2 | tr -d '[]')

if [ -n "$volumes" ]; then
  extracted_variables="$extracted_variables
    volumes = [\"/cache\", $volumes]"
fi

sed -i '/runners_additional_volumes/d' "$converted_file"


# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runners_image/image/g' | \
                      sed 's/runners_privileged/privileged/g' | \
                      sed 's/runners_disable_cache/disable_cache/g' | \
                      sed 's/runners_extra_hosts/extra_hosts/g' | \
                      sed 's/runners_shm_size/shm_size/g' | \
                      sed 's/runners_docker_runtime/runtime/g' | \
                      sed 's/runners_helper_image/helper_image/g' | \
                      sed 's/runners_pull_policies/pull_policies/g'
                    )

# add new block runners_docker_options at the end
echo "$(head -n -1 "$converted_file")
runners_docker_options {
  $extracted_variables
}
}" > x

mv x "$converted_file"

#
# PR #757 refactor!: rename variables and prefix with agent, executor and global scope
#
sed -i '/aws_region/d' "$converted_file"
sed -i '/enable_manage_gitlab_token/d' "$converted_file"

sed 's/enable_kms/enable_managed_kms_key/g' "$converted_file" | \
sed 's/kms_alias_name/kms_managed_alias_name/g' | \
sed 's/kms_deletion_window_in_days/kms_managed_deletion_rotation_window_in_days/g' | \
sed 's/permission_boundary/iam_permission_boundary/g' | \
sed 's/extra_security_group_ids_runner_agent/runner_manager_extra_security_group_ids/g' | \
sed 's/instance_type/runner_manager_instance_type/g' | \
sed 's/runner_instance_ebs_optimized/runner_manager_ebs_optimized/g' | \
sed 's/runner_instance_enable_monitoring/runner_manager_enable_monitoring/g' | \
sed 's/runner_instance_metadata_options/runner_manager_metadata_options/g' | \
sed 's/runners_userdata/executor_docker_machine_userdata/g' | \
sed 's/runners_executor/executor_type/g' | \
sed 's/runners_install_amazon_ecr_credential_helper/runner_manager_install_amazon_ecr_credential_helper/g' | \
sed 's/runners_clone_url/runner_manager_gitlab_clone_url/g' | \
sed 's/runners_gitlab_url/runner_manager_gitlab_url/g' | \
sed 's/runners_max_builds/executor_docker_machine_max_builds/g' | \
sed 's/runners_idle_count/executor_idle_count/g' | \
sed 's/runners_idle_time/executor_idle_time/g' | \
sed 's/runners_concurrent/runner_manager_maximum_concurrent_jobs/g' | \
sed 's/runners_limit/executor_max_jobs/g' | \
sed 's/runners_check_interval/runner_manager_gitlab_check_interval/g' | \
sed 's/sentry_dsn/runner_manager_sentry_dsn/g' | \
sed 's/prometheus_listen_address/runner_manager_prometheus_listen_address/g' | \
sed 's/runner_extra_config/runner_manager_user_data_extra/g' | \
sed 's/runners_ca_certificate/runner_manager_gitlab_ca_certificate/g' | \
sed 's/runners_yum_update/runner_manager_yum_update/g' | \
sed 's/runners_gitlab_certificate/runners_gitlab_certificate/g' | \
sed 's/asg_terminate_lifecycle_hook_name/runner_manager_terminate_ec2_lifecycle_hook_name/g' | \
sed 's/runner_iam_policy_arns/runner_manager_extra_iam_policy_arns/g' | \
sed 's/create_runner_iam_role/runner_manager_create_runner_iam_role_profile/g' | \
sed 's/runner_iam_role_name/runner_manager_iam_role_profile_name/g' | \
sed 's/enable_eip/runner_manager_enable_eip/g' | \
sed 's/enable_runner_ssm_access/runner_manager_enable_ssm_access/g' | \
sed 's/enable_runner_user_data_trace_log/runner_manager_user_data_enable_trace_log/g' | \
sed 's/enable_schedule/runner_manager_schedule_enable/g' | \
sed 's/schedule_config/runner_manager_schedule_config/g' | \
sed 's/runner_root_block_device/runner_manager_root_block_device/g' | \
sed 's/gitlab_runner_registration_config/runner_manager_gitlab_registration_config/g' | \
sed 's/[^_]ami_filter/runner_manager_ami_filter/g' | \
sed 's/[^_]ami_owners/runner_manager_ami_owners/g' | \
sed 's/runner_ami_filter/executor_docker_machine_ami_filter/g' | \
sed 's/runner_ami_owners/executor_docker_machine_ami_owners/g' | \
sed 's/instance_role_json/runner_manager_assume_role_json/g' | \
sed 's/docker_machine_role_json/executor_docker_machine_assume_role_json/g' | \
sed 's/role_tags/runner_manager_extra_role_tags/g' | \
sed 's/runner_tags/executor_docker_machine_extra_role_tags/g' | \
sed 's/agent_tags/runner_manager_extra_instance_tags/g' | \
sed 's/enable_ping/runner_manager_ping_enable/g' | \
sed 's/gitlab_runner_version/runner_manager_gitlab_runner_version/g' | \
sed 's/gitlab_runner_egress_rules/runner_manager_extra_egress_rules/g' | \
sed 's/gitlab_runner_security_group_ids/runner_manager_ping_allow_from_security_groups/g' | \
sed 's/gitlab_runner_security_group_description/runner_manager_security_group_description/g' | \
sed 's/cache_shared/executor_cache_shared/g' | \
sed 's/cache_expiration_days/executor_cache_s3_expiration_days/g' | \
sed 's/cache_bucket_versioning/executor_cache_s3_enable_versioning/g' | \
sed 's/cache_logging_bucket_prefix/executor_cache_s3_logging_bucket_prefix/g' | \
sed 's/cache_logging_bucket/executor_cache_s3_logging_bucket_id/g' | \
sed 's/cache_bucket_set_random_suffix/executor_cache_s3_bucket_enable_random_suffix/g' | \
sed 's/cache_bucket_name_include_account_id/executor_cache_s3_bucket_name_include_account_id/g' | \
sed 's/cache_bucket_prefix/executor_cache_s3_bucket_prefix/g' | \
sed 's/runner_agent_uses_private_address/runner_manager_use_private_address/g' | \
sed 's/runners_use_private_address/executor_docker_machine_use_private_address/g' | \
sed 's/runners_request_spot_instance/executor_docker_machine_request_spot_instances/g' | \
sed 's/userdata_pre_install/runner_manager_userdata_pre_install/g' | \
sed 's/userdata_post_install/runner_manager_userdata_post_install/g' | \
sed 's/runners_pre_build_script/executor_pre_build_script/g' | \
sed 's/runners_post_build_script/executor_post_build_script/g' | \
sed 's/runners_pre_clone_script/executor_pre_clone_script/g' | \
sed 's/runners_request_concurrency/executor_request_concurrency/g' | \
sed 's/runners_output_limit/executor_output_limit/g' | \
sed 's/runners_environment_vars/executor_extra_environment_variables/g' | \
sed 's/runners_docker_registry_mirror/executor_docker_machine_docker_registry_mirror_url/g' | \
sed 's/docker_machine_egress_rules/executor_docker_machine_extra_egress_rules/g' | \
sed 's/docker_machine_iam_policy_arns/executor_docker_machine_extra_iam_policy_arns/g' | \
sed 's/enable_cloudwatch_logging/runner_manager_cloudwatch_enable/g' | \
sed 's/cloudwatch_logging_retention_in_days/runner_manager_cloudwatch_retention_days/g' | \
sed 's/log_group_name/runner_manager_cloudwatch_log_group_name/g' | \
sed 's/asg_max_instance_lifetime/runner_manager_max_instance_lifetime_seconds/g' | \
sed 's/asg_delete_timeout/runner_manager_terraform_timeout_delete_asg/g' | \
sed 's/enable_docker_machine_ssm_access/executor_enable_ssm_access/g' | \
sed 's/cache_bucket/executor_cache_s3_bucket/g' | \
sed 's/docker_machine_security_group_description//g' | \
sed 's/docker_machine_options/executor_docker_machine_ec2_options/g' | \
sed 's/runners_iam_instance_profile_name/executor_docker_machine_iam_instance_profile_name/g' | \
sed 's/runners_volume_type/executor_docker_machine_ec2_volume_type/g' | \
sed 's/runners_ebs_optimized/executor_docker_machine_ec2_ebs_optimized/g' | \
sed 's/runners_monitoring/executor_docker_machine_enable_monitoring/g' | \
sed 's/runners_machine_autoscaling_options/executor_docker_machine_autoscaling_options/g' | \
sed 's/runners_docker_services/executor_docker_services/g' | \
sed 's/runners_services_volumes_tmpfs/executor_docker_services_volumes_tmpfs/g' | \
sed 's/runners_volumes_tmpfs/executor_docker_volumes_tmpfs/g' | \
sed 's/runners_root_size/executor_docker_machine_ec2_root_size/g' | \
sed 's/enable_asg_recreation/runner_manager_enable_asg_recreation/g' | \
sed 's/secure_parameter_store_runner_sentry_dsn/runner_manager_sentry_secure_parameter_store_name/g' | \
sed 's/secure_parameter_store_runner_token_key/runner_manager_gitlab_token_secure_parameter_store/g' | \
sed 's/allow_iam_service_linked_role_creation/runner_manager_allow_iam_service_linked_role_creation/g' | \
sed 's/runners_add_dind_volumes/executor_docker_add_dind_volumes/g' | \
sed 's/runners_token/runner_manager_gitlab_token/g' | \
sed 's/runners_name/runner_manager_gitlab_runner_name/g' | \
sed 's/docker_machine_version/runner_manager_docker_machine_version/g' | \
sed 's/docker_machine_download_url/runner_manager_docker_machine_download_url/g' | \
sed 's/docker_machine_spot_price_bid/executor_docker_machine_ec2_spot_price_bid/g' | \
sed 's/docker_machine_instance_type/executor_docker_machine_instance_type/g' | \
sed 's/docker_machine_instance_metadata_options/executor_docker_machine_ec2_metadata_options/g' | \
sed 's/runner_instance_spot_price/runner_manager_spot_price/g' | \
sed 's/metrics_autoscaling/runner_manager_collect_autoscaling_metrics/g' | \
sed 's/auth_type_cache_sr/executor_cache_s3_authentication_type/g' \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

# overrides block
extracted_variables=$(grep -E '(name_sg|name_iam_objects|name_runner_agent_instance|name_docker_machine_runners)' "$converted_file")

extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/name_sg/security_group_prefix/g' | \
                      sed 's/name_iam_objects/iam_object_prefix/g' | \
                      sed 's/name_runner_agent_instance/runner_manager_instance_prefix/g' | \
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

echo "Module call converted. Output: $converted_file"
