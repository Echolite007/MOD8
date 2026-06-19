# StandaloneJDBCConnection Setup

## Overview

`StandaloneJDBCConnection` provides JDBC connectivity to Databricks with zero
dependencies on the MATLAB Interface for Databricks package. It is designed to
be copied out of the package and embedded in standalone codebases where only
Database Toolbox connectivity is needed.

Requirements:
- MATLAB R2022b or later
- Database Toolbox
- Databricks Simba JDBC driver (the standalone class does not support the OSS driver)

## Class Location

Source: `Software/MATLAB/Standalone/source/StandaloneJDBCConnection.m`

The class is **not** added to the MATLAB path by the package. Add it manually
or include it in your project's path.

## JSON Settings File

The class reads configuration from `databricks_standalone_jdbc_settings.json`.
A template is provided at: `Software/MATLAB/config/databricks_standalone_jdbc_settings.json.template`

The MATLAB path is searched for this file, so place it alongside your code.

### Template

```json
{
    "host": "https://adb-1234567890123456.1.azuredatabricks.net",
    "port": "443",
    "orgId": "1234567890123456",
    "clusterId": "1234-123456-abcdefgh",
    "schema": "myschema",
    "catalog": "mycatalog",

    "authMethod": "OauthU2M",
    "token": "",
    "clientId": "",
    "clientSecret": "",
    "passthroughAccessToken": "",
    "passthroughRefreshToken": "",
    "enableTokenCache": "",
    "tokenCachePassPhrase": "",

    "scope": "",
    "oauthService": "Databricks",
    "oauth2ClientId": "databricks-sql-jdbc",
    "vendor": "",

    "driverClass": "com.databricks.client.jdbc.Driver",
    "jarFilePath": "Shaded-Databricks-JDBC-Driver-0.0.2.jar",

    "connectionURL": "",
    "connectionURLAppend": "",
    "httpPath": "",
    "ssl": "1",
    "thriftTransport": "",

    "logLevel": "0",
    "verbose": "1"
}
```

Values set to `""` are ignored. All fields are specified as scalar strings.

On Windows, escape backslashes in `jarFilePath`:
`"jarFilePath": "c:\\mydir\\Shaded-Databricks-JDBC-Driver-0.0.2.jar"`

## Settings Precedence

1. Constructor arguments (highest priority)
2. Values from the JSON settings file
3. Built-in defaults (lowest priority)

Built-in defaults:
- `authMethod`: `"OauthU2M"`
- `oauthService`: `"Databricks"`
- `oauth2ClientId`: `"databricks-sql-jdbc"`
- `port`: `"443"`
- `driverClass`: `"com.databricks.client.jdbc.Driver"`
- `jarFilePath`: `"Shaded-Databricks-JDBC-Driver-0.0.2.jar"`
- `tokenCachePassPhrase`: `"InsecureTokenCachePassPhrase"`
- `ssl`: `"1"`
- `logLevel`: `"0"`

## Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `host` | Workspace URL | `"https://adb-1234567890123456.1.azuredatabricks.net"` |
| `port` | Driver port | `"443"` |
| `orgId` | Workspace org ID | `"1234567890123456"` |
| `clusterId` | Cluster or SQL Warehouse ID | `"0912-173539-zf4ob0md"` |
| `schema` | Database/schema name | `"myschema"` |
| `catalog` | Unity Catalog catalog | `"mycatalog"` |

## Authentication

| Auth Method | Required Fields |
|-------------|----------------|
| PAT | `token` |
| OauthU2M | None (browser flow) |
| OauthM2M | `clientId`, `clientSecret` |

Token passthrough is also supported via `passthroughAccessToken` (and optionally
`passthroughRefreshToken`). This bypasses the driver's auth mechanisms entirely.

## Usage Examples

```matlab
% Basic: use defaults from JSON settings file
j = StandaloneJDBCConnection();
data = fetch(j.Connection, "SELECT * FROM mytable LIMIT 10");
close(j);

% Override schema and catalog
j = StandaloneJDBCConnection(schema="analytics", catalog="main");
data = sqlread(j.Connection, "mytable");
close(j);

% PAT authentication with explicit token
j = StandaloneJDBCConnection(authMethod="PAT", token=myToken);

% Custom settings file
j = StandaloneJDBCConnection(settingsFile="my_databricks_settings.json");
```

## JDBC Driver Setup

The standalone class requires the shaded Databricks JDBC driver jar on MATLAB's
dynamic Java class path. If the driver is not found, the class will attempt to
add it via `javaaddpath()`.

```matlab
% Manually add the driver if needed
javaaddpath("path/to/Shaded-Databricks-JDBC-Driver-0.0.2.jar");
```

## On-Databricks Considerations

When running on a Databricks cluster, the JDBC driver's OauthU2M cannot be used
(it tries to open a browser). Use `passthroughAccessToken` or an alternative
auth method instead.

```matlab
j = StandaloneJDBCConnection(passthroughAccessToken=accessToken);
```

## Datasource Name Conflict

The `database()` function treats the first argument as either a datasource name
or a database name. If a saved ODBC/JDBC datasource has the same name as the
schema, the connection will fail. Rename the datasource or use a different schema
name.

See `Documentation/StandaloneJDBCDatabaseInterface.md` in the package for full details.

----

Copyright 2026 The MathWorks, Inc.
