# Multi-Output Training

End-to-end recipe for training and evaluating a multi-output `dlnetwork` with
`trainnet`. Three things must align: `net.OutputNames` order, loss function
argument order, and combined datastore column order.

## Step-by-Step Recipe

### 1. Build the dlnetwork

```matlab
numChannels = 6;
numClasses = 4;
net = dlnetwork;

layers = [
    sequenceInputLayer(numChannels)
    lstmLayer(128, OutputMode="last", Name="lstm")
];
net = addLayers(net,layers);

classHead = [
    fullyConnectedLayer(numClasses, Name="fcClass")
    softmaxLayer(Name="softmax")
];
net = addLayers(net,classHead);
net = connectLayers(net,"lstm","fcClass");

regHead = [
    fullyConnectedLayer(1, Name="fcEnergy")
];
net = addLayers(net,regHead);
net = connectLayers(net,"lstm","fcEnergy");
```

### 2. Check net.OutputNames — this is the source of truth

```matlab
net.OutputNames
% ans = {'softmax', 'fcEnergy'}
```

The order here determines everything below.

### 3. Build the combined datastore with targets in OutputNames order

```matlab
dsXTrain = arrayDatastore(XTrain, IterationDimension=3, OutputType="cell");
dsTClass = arrayDatastore(TClassTrain);
dsTEnergy = arrayDatastore(TEnergyTrain);

% Columns: input, target1 (class), target2 (energy) — matching OutputNames
dsTrain = combine(dsXTrain,dsTClass,dsTEnergy);
```

### 4. Write the loss function to match OutputNames order

The loss function receives: outputs first (in `OutputNames` order), then
targets (in the same order).

```matlab
% OutputNames = {'softmax', 'fcEnergy'}
% So: lossFcn(YClass, YEnergy, TClass, TEnergy)
lossFcn = @(YClass, YEnergy, TClass, TEnergy) ...
    crossentropy(YClass,TClass) + 0.01*mse(YEnergy,TEnergy);
```

### 5. Train

```matlab
% Metrics must be a cell array, not a matrix — use { } not [ ]
metrics = {
    accuracyMetric(NetworkOutput="softmax")
    rmseMetric(NetworkOutput="fcEnergy")
};

options = trainingOptions("adam", ...
    MaxEpochs=15, ...
    MiniBatchSize=128, ...
    Shuffle="every-epoch", ...
    Metrics=metrics, ...
    Plots="training-progress");

net = trainnet(dsTrain,net,lossFcn,options);
```
The `NetworkOutput` values in metric objects must match `net.OutputNames`
exactly.

### 6. Evaluate with testnet — same datastore structure

`testnet` for multi-output networks requires a datastore that provides all
targets (one per output). You cannot pass `XTest, TTest` when there are
multiple outputs.

```matlab
dsXTest = arrayDatastore(XTest, IterationDimension=3, OutputType="cell");
dsTClassTest = arrayDatastore(TClassTest);
dsTEnergyTest = arrayDatastore(TEnergyTest);
dsTest = combine(dsXTest,dsTClassTest,dsTEnergyTest);

results = testnet(net,dsTest,metrics);
% results = [accuracy, rmse] — one value per metric, in order
```

## Common Pitfalls

| Symptom | Issue | Fix |
|---------|-------|-----|
| Dimension mismatch during training | Datastore columns are in wrong order | Reorder to match `net.OutputNames` |
| Training runs but accuracy is poor | Loss function argument positions are swapped | Reorder to match `net.OutputNames` |
| `testnet` errors on multi-output | Passing `XTest, TTest` arrays | Use a combined datastore |

----

Copyright 2026 The MathWorks, Inc.

----
