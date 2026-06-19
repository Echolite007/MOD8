# Databricks JDBC Authentication

## Authentication Provider Chain

The MATLAB Interface for Databricks uses a unified authentication provider chain.
Values are resolved in this order (first match wins):

1. Named arguments passed to the connection class constructor
2. Environment variables (`DATABRICKS_*`)
3. `.databrickscfg` profile file
4. `databricks-settings.json` in MATLAB `prefdir`

## .databrickscfg File

Location: `<HomeDirectory>/.databrickscfg`

Override the file location with the `DATABRICKS_CONFIG_FILE` environment variable.

### File Format

```ini
[DEFAULT]
host = https://adb-1234567890123456.azuredatabricks.net
token = dapi1234567890abcdef
cluster_id = 0521-002819-eit9opfk
org_id = 1234567890123456

[U2M]
host = https://adb-1234567890123456.azuredatabricks.net

[M2M]
host = https://adb-1234567890123456.azuredatabricks.net
client_id = fa0-REDACTED-cd1
client_secret = bc0-REDACTED-cd1
```

### Required Fields by Auth Method

| Auth Method | host | token | client_id | client_secret | cluster_id | org_id |
|-------------|:----:|:-----:|:---------:|:-------------:|:----------:|:------:|
| PAT         | Yes  | Yes   |           |               | Optional   | Optional |
| OauthU2M    | Yes  |       |           |               | Optional   | Optional |
| OauthM2M    | Yes  |       | Yes       | Yes           | Optional   | Optional |

Note: `org_id` is required for JDBC URL construction but optional in the config file
(the connection class can derive it from the host URL on Azure).

### Profile Selection Priority

1. `profileName` argument passed to the constructor
2. `DATABRICKS_CONFIG_PROFILE` environment variable
3. `profileName` field in `databricks-settings.json`
4. Profile named `DEFAULT` if present
5. First profile in the file

Profile names are case sensitive.

## Environment Variables

These override `.databrickscfg` values when set:

| Environment Variable | Overrides Profile Field |
|---------------------|------------------------|
| `DATABRICKS_HOST` | `host` |
| `DATABRICKS_TOKEN` | `token` |
| `DATABRICKS_CLIENT_ID` | `client_id` |
| `DATABRICKS_CLIENT_SECRET` | `client_secret` |
| `DATABRICKS_CLUSTER_ID` | `cluster_id` |
| `DATABRICKS_ORG_ID` | `org_id` |

JDBC-specific environment variables (take precedence over `DATABRICKS_HOST` when set):
- `DATABRICKS_SERVER_HOSTNAME`
- `DATABRICKS_HTTP_PATH`

## Authentication Methods

### PAT (Personal Access Token)

Simplest method. The token is stored in `.databrickscfg` or set via `DATABRICKS_TOKEN`.

```matlab
% Token sourced from .databrickscfg or environment variable
j = databricks.JDBCConnection(authMethod="PAT");
```

JDBC URL auth portion: `AuthMech=3;UID=token;PWD=<token>;`

### OauthU2M (User-to-Machine, Default)

Opens a browser for interactive login. Short-lived tokens are cached automatically.
This is the default authentication method.

```matlab
% Default, no arguments needed
j = databricks.JDBCConnection();

% Or explicitly
j = databricks.JDBCConnection(authMethod="OauthU2M");
```

JDBC URL auth portion: `AuthMech=11;Auth_Flow=2;`

### OauthM2M (Machine-to-Machine)

Uses a service principal with client credentials. Appropriate for automated pipelines.
Requires `client_id` and `client_secret` in `.databrickscfg` or environment variables.

```matlab
j = databricks.JDBCConnection(authMethod="OauthM2M", profileName="M2M");
```

JDBC URL auth portion: `AuthMech=11;Auth_Flow=1;OAuth2ClientId=<id>;OAuth2Secret=<secret>;`

### Token Passthrough

Bypasses the driver's authentication and passes an externally obtained access token directly.
Useful when running on Databricks or when tokens are managed externally.

```matlab
j = databricks.JDBCConnection(passthroughAccessToken=myToken);
```

JDBC URL auth portion: `AuthMech=11;Auth_Flow=0;Auth_AccessToken=<token>;`

## Token Caching

### Package-Managed (OauthU2M without driver auth)

Tokens are cached in `<HomeDirectory>/.databricksOauthTokenCache` as plain text.
Override the location with `DATABRICKS_TOKEN_CACHE_FILE`.
Disable caching by setting `DISABLE_DATABRICKS_TOKEN_CACHE=true`.

### Driver-Managed (default)

The JDBC driver manages its own token cache when `enableTokenCache` is set.
A `TokenCachePassPhrase` protects the cached tokens.

| Driver Version | Windows | Linux/macOS |
|---------------|---------|-------------|
| v2.7.1-2.7.2 | Supported | Not supported (driver bug) |
| v2.7.3+ | Supported | Supported |
| v3.0+ (OSS) | Supported | Supported |

`enableTokenCache` is enabled by default when the driver version supports it.

## OAuth Service Providers

The `OauthService` parameter controls scope resolution:

| OauthService | When to Use |
|-------------|-------------|
| `Databricks` (default) | Standard Databricks workspaces |
| `EntraID` | Azure AD / Entra ID managed authentication |
| `Unspecified` | Let the driver determine the provider |

## Settings File

`databricks-settings.json` in MATLAB `prefdir` stores preferences:

| Field | Purpose |
|-------|---------|
| `authMethod` | Default authentication method (OauthU2M, OauthM2M, PAT, Chain) |
| `profileName` | Default profile name in `.databrickscfg` |
| `vendor` | Cloud platform (azure, aws) for cluster creation |

See `Documentation/Authentication.md` and `Documentation/Setup.md` in the package for
full configuration details.

----

Copyright 2026 The MathWorks, Inc.
