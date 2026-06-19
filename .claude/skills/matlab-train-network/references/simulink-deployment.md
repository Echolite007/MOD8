# Simulink Deployment

Deploy a trained `dlnetwork` to Simulink. Replaces the legacy `gensim` function.

## Deployment Methods

### 1. exportNetworkToSimulink (preferred)

Use when the network is small and all layers are supported for export.
Generates a Simulink subsystem with individual layer blocks.

```matlab
exportNetworkToSimulink(net)
```

### 2. Predict Block

Use for larger networks or when the network contains layers not supported by
`exportNetworkToSimulink`. Add a **Predict** block from the `deeplib` library
and configure it to load the saved `dlnetwork`.

```matlab
save("myNet.mat","net");
add_block("deeplib/Predict","myModel/Predict", ...
    Network="Network from MAT-file", ...
    NetworkFilePath="myNet.mat");
```

## Legacy Pattern (DO NOT USE)

```matlab
% DON'T — legacy pattern
net = feedforwardnet(10);
net = train(net,X,T);
gensim(net)

% DO — modern pattern
net = dlnetwork([...]);
net = trainnet(X,T,net,"mse",options);
exportNetworkToSimulink(net)
```

----

Copyright 2026 The MathWorks, Inc.

----
