# Databricks JDBC Driver Selection

## Supported Drivers

The MATLAB Interface for Databricks supports two JDBC drivers:

| Driver | Version Range | Java Requirement | Included in Package | Key Feature |
|--------|--------------|------------------|--------------------:|-------------|
| Simba (non-OSS) | >= 2.7.3, < 3.0.0 | Java 8+ (MATLAB default) | Yes | Write optimization via `UseNativeQuery` |
| OSS | >= 3.0.3 | Java 11+ | No (download separately) | Arrow-based data transfer for faster large reads |

## Auto-Selection Logic

When neither `useDriverType` nor `jarFilePath` are specified, the driver is selected
automatically based on availability and Java version:

| Java Version | Simba Present | OSS Present | Driver Selected |
|:------------:|:------------:|:-----------:|:---------------:|
| > 8 | Yes | Yes | OSS |
| > 8 | Yes | No | Simba |
| 8 | Yes | Any | Simba (default) |

Explicit selection overrides auto-detection:

| Argument | Effect |
|----------|--------|
| `useDriverType='oss'` | Forces OSS driver |
| `useDriverType='simba'` | Forces Simba driver |
| `jarFilePath="path/to/specific.jar"` | Uses the specified jar directly |

## Simba Driver (Default)

### Location

The shaded driver ships with the package at:
`Software/MATLAB/lib/jar/Shaded-Databricks-JDBC-Driver-0.0.2.jar`

The driver is "shaded" (repackaged with relocated dependencies) to avoid classpath
conflicts with MATLAB's JVM. Using the unshaded driver from Databricks directly
will produce spurious logging messages.

### Driver Class

`com.databricks.client.jdbc.Driver`

### Write Optimization

The Simba driver supports `UseNativeQuery` and `EnableNativeParameterizedQuery`
parameters that significantly improve `sqlwrite` performance. These are set in
the JDBC URL:

```
UseNativeQuery=1;EnableNativeParameterizedQuery=0;
```

This is enabled by default when connections are created via `databricks.JDBCConnection`
or `SQLWarehouse.connect()`. To disable:

```matlab
j = databricks.JDBCConnection(useNativeQuery=false, enableNativeParameterizedQuery=true);
```

### Custom Build

To build a shaded version from a newer Databricks driver:

1. Install Apache Maven and a JDK
2. Verify: `mvn -version`
3. From `Software/Java/JDBCDriver/`, run: `mvn clean package`
4. Output: `Software/MATLAB/lib/jar/Shaded-Databricks-JDBC-Driver-0.0.2.jar`

## OSS Driver

### Download

The OSS driver is not included in the package. Build it using Maven:

1. From `Software/Java/JDBCDriver/`, run: `mvn clean package -f pomOSS.xml`
2. Output: `Software/MATLAB/lib/jar/Databricks-JDBC-OSS-Driver-0.0.1.jar`

### Java Version Configuration

The OSS driver requires Java 11 or greater. MATLAB's default Java 8 environment
is not compatible.

```matlab
% Check current Java version
jenv

% Set a Java 11+ environment (requires MATLAB restart)
jenv("/usr/local/jre-11")

% Or use JAVA_HOME if set
jenv(getenv("JAVA_HOME"))

% Reset to factory default
jenv("factory")
```

MATLAB must be restarted after changing the Java environment.

For compatible JDK versions, see the MathWorks OpenJDK support page.

**Avoid Java 16**: It requires a JVM startup argument
(`--add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED`)
that must be configured in MATLAB's `java.opts` file. Java 11, 17, or 21 are
recommended instead.

### Driver Class

The OSS driver uses the same class name: `com.databricks.client.jdbc.Driver`

### Limitations

- `UseNativeQuery` / `EnableNativeParameterizedQuery` are Simba-specific and are
  ignored by the OSS driver
- The `thriftTransport` parameter is ignored by the OSS driver
- Logging output is not currently suppressed (the OSS driver jar is not shaded)

## Classpath Management

`databricks.JDBCConnection` automatically adds the chosen driver jar to MATLAB's
dynamic Java class path before connecting. No manual `javaaddpath()` is needed
when using the full package.

For `StandaloneJDBCConnection`, the jar must be on the classpath already or the
class will attempt to add it via `javaaddpath()` and ask you to retry.

```matlab
% Manual classpath addition (standalone scenario)
javaaddpath("path/to/Shaded-Databricks-JDBC-Driver-0.0.2.jar");
```

## Proxy Support

The Databricks JDBC driver supports SOCKS proxies only. `JDBCConnection` does not
configure proxy details automatically. Use `connectionURLAppend` to add proxy
settings if required:

```matlab
j = databricks.JDBCConnection(connectionURLAppend="ProxyHost=myproxy;ProxyPort=1080;");
```

See `Documentation/InstallingJDBCDriver.md` and `Documentation/JDBCWorkflow.md`
in the package for full driver documentation.

----

Copyright 2026 The MathWorks, Inc.
