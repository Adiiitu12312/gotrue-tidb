SET FOREIGN_KEY_CHECKS = 0;


-- instances definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`instances` (
    `id` VARCHAR(36) NOT NULL,
    `uuid` VARCHAR(36) NULL,
    `raw_base_config` TEXT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- users definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (
    `instance_id` VARCHAR(36) NULL,
    `id` VARCHAR(36) NOT NULL,
    `aud` VARCHAR(255) NULL,
    `role` VARCHAR(255) NULL,
    `email` VARCHAR(255) NULL,
    `encrypted_password` VARCHAR(255) NULL,
    `email_confirmed_at` DATETIME(6) NULL,
    `invited_at` DATETIME(6) NULL,
    `confirmation_token` VARCHAR(255) NULL,
    `confirmation_sent_at` DATETIME(6) NULL,
    `recovery_token` VARCHAR(255) NULL,
    `recovery_sent_at` DATETIME(6) NULL,
    `email_change_token_new` VARCHAR(255) NULL,
    `email_change` VARCHAR(255) NULL,
    `email_change_sent_at` DATETIME(6) NULL,
    `last_sign_in_at` DATETIME(6) NULL,
    `raw_app_meta_data` JSON NULL,
    `raw_user_meta_data` JSON NULL,
    `is_super_admin` TINYINT(1) NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `phone` VARCHAR(255) NULL,
    `phone_confirmed_at` DATETIME(6) NULL,
    `phone_change` VARCHAR(255) NULL,
    `phone_change_token` VARCHAR(255) NULL,
    `phone_change_sent_at` DATETIME(6) NULL,
    `confirmed_at` DATETIME(6) NULL,
    `email_change_token_current` VARCHAR(255) NULL,
    `email_change_confirm_status` SMALLINT DEFAULT 0,
    `banned_until` DATETIME(6) NULL,
    `reauthentication_token` VARCHAR(255) NULL,
    `reauthentication_sent_at` DATETIME(6) NULL,
    `is_sso_user` TINYINT(1) NOT NULL DEFAULT 0,
    `deleted_at` DATETIME(6) NULL,
    `is_anonymous` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `users_email_idx` (`email`),
    KEY `users_instance_id_idx` (`instance_id`),
    KEY `users_instance_id_email_idx` (`instance_id`, `email`),
    KEY `users_phone_idx` (`phone`),
    KEY `users_is_anonymous_idx` (`is_anonymous`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- refresh_tokens definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`refresh_tokens` (
    `instance_id` VARCHAR(36) NULL,
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `token` VARCHAR(255) NULL,
    `user_id` VARCHAR(255) NULL,
    `revoked` TINYINT(1) NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `parent` VARCHAR(255) NULL,
    `session_id` VARCHAR(36) NULL,
    PRIMARY KEY (`id`),
    KEY `refresh_tokens_instance_id_idx` (`instance_id`),
    KEY `refresh_tokens_instance_id_user_id_idx` (`instance_id`, `user_id`),
    KEY `refresh_tokens_token_idx` (`token`),
    KEY `refresh_tokens_session_id_revoked_idx` (`session_id`, `revoked`),
    KEY `refresh_tokens_updated_at_idx` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- audit_log_entries definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`audit_log_entries` (
    `instance_id` VARCHAR(36) NULL,
    `id` VARCHAR(36) NOT NULL,
    `payload` JSON NULL,
    `created_at` DATETIME(6) NULL,
    `ip_address` VARCHAR(64) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `audit_logs_instance_id_idx` (`instance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- identities definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`identities` (
    `provider_id` VARCHAR(255) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `identity_data` JSON NOT NULL,
    `provider` VARCHAR(255) NOT NULL,
    `last_sign_in_at` DATETIME(6) NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `id` VARCHAR(36) NOT NULL,
    `email` VARCHAR(255) GENERATED ALWAYS AS (LOWER(JSON_UNQUOTE(JSON_EXTRACT(`identity_data`, '$.email')))) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identities_provider_id_provider_unique` (`provider_id`, `provider`),
    KEY `identities_user_id_idx` (`user_id`),
    KEY `identities_email_idx` (`email`),
    CONSTRAINT `identities_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- oauth_clients definition (referenced by sessions)
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`oauth_clients` (
    `id` VARCHAR(36) NOT NULL,
    `client_secret_hash` VARCHAR(255) NOT NULL,
    `registration_type` VARCHAR(255) NOT NULL,
    `client_type` VARCHAR(255) NOT NULL,
    `token_endpoint_auth_method` VARCHAR(255) NOT NULL,
    `redirect_uris` TEXT NOT NULL,
    `grant_types` VARCHAR(255) NOT NULL,
    `client_name` VARCHAR(255) NULL,
    `client_uri` VARCHAR(1024) NULL,
    `logo_uri` VARCHAR(1024) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    `deleted_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    KEY `oauth_clients_deleted_at_idx` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- sessions definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sessions` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `factor_id` VARCHAR(36) NULL,
    `aal` VARCHAR(255) NULL,
    `not_after` DATETIME(6) NULL,
    `refreshed_at` DATETIME(6) NULL,
    `user_agent` VARCHAR(255) NULL,
    `ip` VARCHAR(255) NULL,
    `tag` VARCHAR(255) NULL,
    `oauth_client_id` VARCHAR(36) NULL,
    `scopes` TEXT NULL,
    `refresh_token_hmac_key` VARCHAR(255) NULL,
    `refresh_token_counter` BIGINT NULL,
    PRIMARY KEY (`id`),
    KEY `sessions_user_id_idx` (`user_id`),
    KEY `sessions_not_after_idx` (`not_after`),
    KEY `sessions_user_id_created_at_idx` (`user_id`, `created_at`),
    KEY `sessions_oauth_client_id_idx` (`oauth_client_id`),
    CONSTRAINT `sessions_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- mfa_factors definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_factors` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `friendly_name` VARCHAR(255) NULL,
    `factor_type` VARCHAR(255) NOT NULL,
    `status` VARCHAR(255) NOT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `secret` VARCHAR(255) NULL,
    `phone` VARCHAR(255) NULL,
    `last_challenged_at` DATETIME(6) NULL,
    `web_authn_credential` JSON NULL,
    `web_authn_aaguid` VARCHAR(36) NULL,
    `last_webauthn_challenge_data` JSON NULL,
    PRIMARY KEY (`id`),
    KEY `mfa_factors_user_id_idx` (`user_id`),
    KEY `mfa_factors_user_friendly_name_unique` (`user_id`, `friendly_name`),
    UNIQUE KEY `mfa_factors_last_challenged_at_key` (`last_challenged_at`),
    CONSTRAINT `mfa_factors_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- mfa_challenges definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_challenges` (
    `id` VARCHAR(36) NOT NULL,
    `factor_id` VARCHAR(36) NOT NULL,
    `created_at` DATETIME(6) NULL,
    `verified_at` DATETIME(6) NULL,
    `ip_address` VARCHAR(255) NOT NULL,
    `otp_code` VARCHAR(255) NULL,
    `web_authn_session_data` JSON NULL,
    PRIMARY KEY (`id`),
    KEY `mfa_challenges_created_at_idx` (`created_at`),
    CONSTRAINT `mfa_challenges_factor_id_fkey` FOREIGN KEY (`factor_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_factors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- mfa_amr_claims definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_amr_claims` (
    `id` VARCHAR(36) NOT NULL,
    `session_id` VARCHAR(36) NOT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `authentication_method` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `mfa_amr_claims_session_id_authentication_method_pkey` (`session_id`, `authentication_method`),
    CONSTRAINT `mfa_amr_claims_session_id_fkey` FOREIGN KEY (`session_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- sso_providers definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_providers` (
    `id` VARCHAR(36) NOT NULL,
    `resource_id` VARCHAR(255) NULL,
    `disabled` TINYINT(1) NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `sso_providers_resource_id_idx` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- saml_providers definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`saml_providers` (
    `id` VARCHAR(36) NOT NULL,
    `sso_provider_id` VARCHAR(36) NOT NULL,
    `entity_id` VARCHAR(255) NOT NULL,
    `metadata_xml` MEDIUMTEXT NOT NULL,
    `metadata_url` VARCHAR(1024) NULL,
    `attribute_mapping` JSON NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `name_id_format` VARCHAR(255) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `saml_providers_entity_id_key` (`entity_id`),
    KEY `saml_providers_sso_provider_id_idx` (`sso_provider_id`),
    CONSTRAINT `saml_providers_sso_provider_id_fkey` FOREIGN KEY (`sso_provider_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- saml_relay_states definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`saml_relay_states` (
    `id` VARCHAR(36) NOT NULL,
    `sso_provider_id` VARCHAR(36) NOT NULL,
    `request_id` VARCHAR(255) NOT NULL,
    `for_email` VARCHAR(255) NULL,
    `redirect_to` TEXT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `flow_state_id` VARCHAR(36) NULL,
    PRIMARY KEY (`id`),
    KEY `saml_relay_states_sso_provider_id_idx` (`sso_provider_id`),
    KEY `saml_relay_states_for_email_idx` (`for_email`),
    KEY `saml_relay_states_created_at_idx` (`created_at`),
    CONSTRAINT `saml_relay_states_sso_provider_id_fkey` FOREIGN KEY (`sso_provider_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- sso_domains definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_domains` (
    `id` VARCHAR(36) NOT NULL,
    `sso_provider_id` VARCHAR(36) NOT NULL,
    `domain` VARCHAR(255) NOT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    KEY `sso_domains_sso_provider_id_idx` (`sso_provider_id`),
    KEY `sso_domains_domain_idx` (`domain`),
    CONSTRAINT `sso_domains_sso_provider_id_fkey` FOREIGN KEY (`sso_provider_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- flow_state definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`flow_state` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NULL,
    `auth_code` VARCHAR(255) NULL,
    `code_challenge_method` VARCHAR(255) NULL,
    `code_challenge` VARCHAR(255) NULL,
    `provider_type` VARCHAR(255) NOT NULL,
    `provider_access_token` MEDIUMTEXT NULL,
    `provider_refresh_token` MEDIUMTEXT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `authentication_method` VARCHAR(255) NOT NULL,
    `auth_code_issued_at` DATETIME(6) NULL,
    `oauth_client_state_id` VARCHAR(36) NULL,
    `linking_target_id` VARCHAR(36) NULL,
    `email_optional` TINYINT(1) NOT NULL DEFAULT 0,
    `invite_token` VARCHAR(255) NULL,
    `referrer` TEXT NULL,
    PRIMARY KEY (`id`),
    KEY `flow_state_created_at_idx` (`created_at`),
    KEY `flow_state_auth_code_idx` (`auth_code`),
    KEY `flow_state_user_id_auth_method_idx` (`user_id`, `authentication_method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- one_time_tokens definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`one_time_tokens` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `token_type` VARCHAR(255) NOT NULL,
    `token_hash` VARCHAR(255) NOT NULL,
    `relates_to` VARCHAR(255) NOT NULL,
    `created_at` DATETIME(6) NULL,
    `updated_at` DATETIME(6) NULL,
    `expires_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    KEY `one_time_tokens_token_hash_hash_idx` (`token_hash`),
    KEY `one_time_tokens_relates_to_hash_idx` (`relates_to`),
    KEY `one_time_tokens_user_id_token_type_idx` (`user_id`, `token_type`),
    CONSTRAINT `one_time_tokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- oauth_authorizations definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`oauth_authorizations` (
    `id` VARCHAR(36) NOT NULL,
    `authorization_id` VARCHAR(255) NOT NULL,
    `client_id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NULL,
    `redirect_uri` TEXT NOT NULL,
    `scope` TEXT NOT NULL,
    `state` VARCHAR(255) NULL,
    `resource` VARCHAR(255) NULL,
    `code_challenge` VARCHAR(255) NULL,
    `code_challenge_method` VARCHAR(255) NULL,
    `response_type` VARCHAR(255) NOT NULL,
    `status` VARCHAR(255) NOT NULL,
    `authorization_code` VARCHAR(255) NULL,
    `nonce` VARCHAR(255) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `expires_at` DATETIME(6) NOT NULL,
    `approved_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `oauth_authorizations_authorization_id_key` (`authorization_id`),
    KEY `oauth_authorizations_authorization_code_idx` (`authorization_code`),
    KEY `oauth_authorizations_client_id_idx` (`client_id`),
    KEY `oauth_authorizations_user_id_idx` (`user_id`),
    CONSTRAINT `oauth_authorizations_client_id_fkey` FOREIGN KEY (`client_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`oauth_clients` (`id`) ON DELETE CASCADE,
    CONSTRAINT `oauth_authorizations_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- oauth_consents definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`oauth_consents` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `client_id` VARCHAR(36) NOT NULL,
    `scopes` TEXT NOT NULL,
    `granted_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `revoked_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    KEY `oauth_consents_user_id_idx` (`user_id`),
    KEY `oauth_consents_client_id_idx` (`client_id`),
    KEY `oauth_consents_revoked_at_idx` (`revoked_at`),
    CONSTRAINT `oauth_consents_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `oauth_consents_client_id_fkey` FOREIGN KEY (`client_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`oauth_clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- oauth_client_states definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`oauth_client_states` (
    `id` VARCHAR(36) NOT NULL,
    `provider_type` VARCHAR(255) NOT NULL,
    `code_verifier` TEXT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    KEY `oauth_client_states_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- custom_oauth_providers definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`custom_oauth_providers` (
    `id` VARCHAR(36) NOT NULL,
    `provider_type` VARCHAR(255) NOT NULL,
    `identifier` VARCHAR(255) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `client_id` VARCHAR(255) NOT NULL,
    `client_secret` TEXT NOT NULL,
    `acceptable_client_ids` TEXT NOT NULL,
    `scopes` TEXT NOT NULL,
    `pkce_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `attribute_mapping` JSON NOT NULL,
    `custom_claims_allowlist` TEXT NOT NULL,
    `authorization_params` JSON NOT NULL,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `email_optional` TINYINT(1) NOT NULL DEFAULT 0,
    `issuer` VARCHAR(1024) NULL,
    `discovery_url` VARCHAR(1024) NULL,
    `skip_nonce_check` TINYINT(1) NOT NULL DEFAULT 0,
    `cached_discovery` JSON NULL,
    `discovery_cached_at` DATETIME(6) NULL,
    `authorization_url` VARCHAR(1024) NULL,
    `token_url` VARCHAR(1024) NULL,
    `userinfo_url` VARCHAR(1024) NULL,
    `jwks_uri` VARCHAR(1024) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    UNIQUE KEY `custom_oauth_providers_identifier_key` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- webauthn_credentials definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`webauthn_credentials` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `credential_id` VARBINARY(1024) NOT NULL,
    `public_key` BLOB NOT NULL,
    `attestation_type` VARCHAR(255) NOT NULL,
    `aaguid` VARCHAR(36) NULL,
    `sign_count` BIGINT NOT NULL DEFAULT 0,
    `transports` JSON NOT NULL,
    `backup_eligible` TINYINT(1) NOT NULL DEFAULT 0,
    `backed_up` TINYINT(1) NOT NULL DEFAULT 0,
    `friendly_name` VARCHAR(255) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    `last_used_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `webauthn_credentials_credential_id_key` (`credential_id`(255)),
    KEY `webauthn_credentials_user_id_idx` (`user_id`),
    CONSTRAINT `webauthn_credentials_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- webauthn_challenges definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`webauthn_challenges` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NULL,
    `session_data` JSON NOT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `expires_at` DATETIME(6) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `webauthn_challenges_expires_at_idx` (`expires_at`),
    CONSTRAINT `webauthn_challenges_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- mfa_recovery_code_sets definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_recovery_code_sets` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `mfa_factor_id` VARCHAR(36) NOT NULL,
    `failed_verification_count` INT NOT NULL DEFAULT 0,
    `verification_locked_until` DATETIME(6) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    UNIQUE KEY `mfa_recovery_code_sets_user_id_key` (`user_id`),
    UNIQUE KEY `mfa_recovery_code_sets_mfa_factor_id_key` (`mfa_factor_id`),
    CONSTRAINT `mfa_recovery_code_sets_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `mfa_recovery_code_sets_mfa_factor_id_fkey` FOREIGN KEY (`mfa_factor_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_factors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- mfa_recovery_codes definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_recovery_codes` (
    `id` VARCHAR(36) NOT NULL,
    `mfa_recovery_code_set_id` VARCHAR(36) NOT NULL,
    `code_hash` VARCHAR(255) NOT NULL,
    `consumed_at` DATETIME(6) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    KEY `mfa_recovery_codes_set_id_idx` (`mfa_recovery_code_set_id`),
    CONSTRAINT `mfa_recovery_codes_set_id_fkey` FOREIGN KEY (`mfa_recovery_code_set_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`mfa_recovery_code_sets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- scim_users definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`scim_users` (
    `id` VARCHAR(36) NOT NULL,
    `sso_provider_id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NULL,
    `resource` JSON NOT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    `deleted_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    KEY `scim_users_sso_provider_id_idx` (`sso_provider_id`),
    KEY `scim_users_user_id_idx` (`user_id`),
    CONSTRAINT `scim_users_sso_provider_id_fkey` FOREIGN KEY (`sso_provider_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_providers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `scim_users_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- scim_tokens definition
CREATE TABLE IF NOT EXISTS {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`scim_tokens` (
    `id` VARCHAR(36) NOT NULL,
    `sso_provider_id` VARCHAR(36) NOT NULL,
    `token_hash` VARCHAR(255) NOT NULL,
    `description` VARCHAR(255) NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `expires_at` DATETIME(6) NULL,
    `revoked_at` DATETIME(6) NULL,
    `last_used_at` DATETIME(6) NULL,
    PRIMARY KEY (`id`),
    KEY `scim_tokens_sso_provider_id_idx` (`sso_provider_id`),
    KEY `scim_tokens_token_hash_idx` (`token_hash`),
    CONSTRAINT `scim_tokens_sso_provider_id_fkey` FOREIGN KEY (`sso_provider_id`) REFERENCES {{ if index .Options "Namespace" }}`{{ index .Options "Namespace" }}`.{{ end }}`sso_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
