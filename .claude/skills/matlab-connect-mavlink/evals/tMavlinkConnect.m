classdef tMavlinkConnect < matlab.unittest.TestCase
    % tMavlinkConnect  Integration tests for matlab-connect-mavlink skill
    %
    %   Launches PX4 SITL via WSL and validates both connection workflows.
    %
    %   Prerequisites:
    %     - PX4 SITL built at ~/px4_16 in WSL
    %     - WSL accessible from Windows via 'wsl' command
    %     - UAV Toolbox installed
    %
    %   Usage:
    %     results = runtests('tMavlinkConnect');

    % Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        PX4Dir = "~/px4_16"
        MakeTarget = "px4_sitl_sih sihsim_quadx"
        MavlinkConfigPath = "~/px4_16/build/px4_sitl_sih/etc/init.d-posix/px4-rc.mavlink"
        GCSLocalPort = 14550
        SITLPortDefault = 18570  % udp_gcs_port_local for instance 0
        StartupTimeout = 90  % seconds to wait for SITL to start
        DiscoveryTimeout = 10  % seconds to wait for client discovery
    end

    properties (Access = private)
        SITLProcess
        SITLReader
        SITLHost string
    end

    methods (TestClassSetup)
        function getSITLHost(testCase)
            [~, output] = system('wsl -e bash -c "hostname -I | awk ''{print $1}''"');
            lines = splitlines(strip(string(output)));
            % Filter out WSL translation warnings
            ipLine = lines(~startsWith(lines, "wsl:") & strlength(lines) > 0);
            testCase.SITLHost = strip(ipLine(end));
            testCase.assertNotEmpty(testCase.SITLHost, "Could not determine WSL IP");
            testCase.log(1, "SITL Host: " + testCase.SITLHost);
        end
    end

    methods (TestMethodSetup)
        function killExistingSITL(testCase)
            % Kill any existing PX4 SITL processes
            system('wsl -e bash -c "pkill -f px4 2>/dev/null; sleep 1"');
            testCase.SITLProcess = [];
            testCase.SITLReader = [];
        end
    end

    methods (TestMethodTeardown)
        function cleanupSITL(testCase)
            if ~isempty(testCase.SITLProcess) && testCase.SITLProcess.isAlive()
                testCase.SITLProcess.destroyForcibly();
                pause(1);
            end
            % Also kill via pkill as a safety net
            system('wsl -e bash -c "pkill -f px4 2>/dev/null"');
            delete(timerfindall);
        end
    end

    methods (Test)
        function testWorkflowA_AutoDiscovery(testCase)
            % Test Workflow A: SITL broadcasts, autopilot auto-discovered

            % Enable broadcast and launch SITL
            testCase.setBroadcast(true);
            testCase.launchSITL();

            % Connect — no heartbeat needed for discovery
            dialect = mavlinkdialect("common.xml", 2);
            mavlink = mavlinkio(dialect, 'SystemID', 255, 'ComponentID', 1);
            cleanup = onCleanup(@() disconnect(mavlink));
            connect(mavlink, "UDP", LocalPort=testCase.GCSLocalPort);

            % Wait for auto-discovery
            [discovered, clients] = testCase.waitForDiscovery(mavlink);
            testCase.verifyTrue(discovered, ...
                "Autopilot should be auto-discovered when broadcast is enabled");

            % Verify client identity
            remoteClient = clients(clients.SystemID ~= 255, :);
            testCase.verifyEqual(height(remoteClient), 1, ...
                "Should discover exactly one remote client");
            testCase.verifyEqual(remoteClient.SystemID, uint8(1));
            testCase.verifyEqual(remoteClient.ComponentID, uint8(1));

            % Start GCS heartbeat back via sendmsg
            hbMsg = testCase.buildHeartbeat(dialect);
            autopilot = mavlinkclient(mavlink, remoteClient.SystemID, remoteClient.ComponentID);
            hbTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
                'TimerFcn', @(~,~) sendmsg(mavlink, hbMsg, autopilot));
            start(hbTimer);
            timerCleanup = onCleanup(@() testCase.deleteTimer(hbTimer));

            % Verify we receive messages
            attSub = mavlinksub(mavlink, autopilot, "ATTITUDE");
            pause(2);
            msgs = latestmsgs(attSub, 1);
            testCase.verifyNotEmpty(msgs, "Should receive ATTITUDE messages");
        end

        function testWorkflowB_ManualHeartbeat(testCase)
            % Test Workflow B: SITL not broadcasting, manual heartbeat needed

            % Disable broadcast and launch SITL
            testCase.setBroadcast(false);
            testCase.launchSITL();

            % Connect
            dialect = mavlinkdialect("common.xml", 2);
            mavlink = mavlinkio(dialect, 'SystemID', 255, 'ComponentID', 1);
            cleanup = onCleanup(@() disconnect(mavlink));
            connect(mavlink, "UDP", LocalPort=testCase.GCSLocalPort);

            % Verify NOT auto-discovered without heartbeat
            pause(2);
            clients = listClients(mavlink);
            testCase.verifyEqual(height(clients), 1, ...
                "Should NOT discover autopilot without sending heartbeat");

            % Start manual heartbeat via sendudpmsg
            hbMsg = testCase.buildHeartbeat(dialect);
            hbTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
                'TimerFcn', @(~,~) sendudpmsg(mavlink, hbMsg, ...
                    testCase.SITLHost, testCase.SITLPortDefault));
            start(hbTimer);
            timerCleanup = onCleanup(@() testCase.deleteTimer(hbTimer));

            % Now should discover
            [discovered, clients] = testCase.waitForDiscovery(mavlink);
            testCase.verifyTrue(discovered, ...
                "Autopilot should be discovered after sending heartbeat");

            % Verify can subscribe and receive
            remoteClient = clients(clients.SystemID ~= 255, :);
            autopilot = mavlinkclient(mavlink, remoteClient.SystemID, remoteClient.ComponentID);
            posSub = mavlinksub(mavlink, autopilot, "GLOBAL_POSITION_INT");
            pause(2);
            msgs = latestmsgs(posSub, 1);
            testCase.verifyNotEmpty(msgs, "Should receive position messages");
        end

        function testSendmsgAfterDiscovery(testCase)
            % Test that sendmsg works after client is discovered

            testCase.setBroadcast(true);
            testCase.launchSITL();

            dialect = mavlinkdialect("common.xml", 2);
            mavlink = mavlinkio(dialect, 'SystemID', 255, 'ComponentID', 1);
            cleanup = onCleanup(@() disconnect(mavlink));
            connect(mavlink, "UDP", LocalPort=testCase.GCSLocalPort);

            [discovered, clients] = testCase.waitForDiscovery(mavlink);
            testCase.assumeTrue(discovered, "Need discovery for this test");

            remoteClient = clients(clients.SystemID ~= 255, :);
            autopilot = mavlinkclient(mavlink, remoteClient.SystemID, remoteClient.ComponentID);

            % sendmsg to discovered client should work
            hbMsg = testCase.buildHeartbeat(dialect);
            testCase.verifyWarningFree( ...
                @() sendmsg(mavlink, hbMsg, autopilot), ...
                "sendmsg to discovered client should not error");
        end

        function testPayloadTypePreservation(testCase)
            % Test that (:) indexing preserves wire types

            dialect = mavlinkdialect("common.xml", 2);

            hbMsg = createmsg(dialect, "HEARTBEAT");
            hbMsg.Payload.type(:) = dialect.enum2num("MAV_TYPE", "MAV_TYPE_GCS");
            hbMsg.Payload.autopilot(:) = dialect.enum2num("MAV_AUTOPILOT", "MAV_AUTOPILOT_INVALID");
            hbMsg.Payload.base_mode(:) = 0;
            hbMsg.Payload.custom_mode(:) = 0;
            hbMsg.Payload.system_status(:) = 0;

            testCase.verifyClass(hbMsg.Payload.type, 'uint8');
            testCase.verifyClass(hbMsg.Payload.autopilot, 'uint8');
            testCase.verifyClass(hbMsg.Payload.base_mode, 'uint8');
            testCase.verifyClass(hbMsg.Payload.custom_mode, 'uint32');
            testCase.verifyClass(hbMsg.Payload.system_status, 'uint8');

            cmdMsg = createmsg(dialect, "COMMAND_LONG");
            cmdMsg.Payload.target_system(:) = 1;
            cmdMsg.Payload.command(:) = 400;
            cmdMsg.Payload.param1(:) = 1;

            testCase.verifyClass(cmdMsg.Payload.target_system, 'uint8');
            testCase.verifyClass(cmdMsg.Payload.command, 'uint16');
            testCase.verifyClass(cmdMsg.Payload.param1, 'single');
        end

        function testSendmsgFailsPreDiscovery(testCase)
            % Test that sendmsg to undiscovered client errors correctly

            dialect = mavlinkdialect("common.xml", 2);
            mavlink = mavlinkio(dialect, 'SystemID', 255, 'ComponentID', 1);
            cleanup = onCleanup(@() disconnect(mavlink));
            connect(mavlink, "UDP", LocalPort=testCase.GCSLocalPort);

            hbMsg = testCase.buildHeartbeat(dialect);
            autopilot = mavlinkclient(mavlink, 1, 1);

            testCase.verifyError( ...
                @() sendmsg(mavlink, hbMsg, autopilot), ...
                'uav:robotcpp:mavlinkcpp:UnknownMAVLinkClient', ...
                "sendmsg to undiscovered client should error");
        end
    end

    methods (Access = private)
        function launchSITL(testCase)
            import java.lang.ProcessBuilder

            cmd = sprintf("cd %s && make %s 2>&1", ...
                testCase.PX4Dir, testCase.MakeTarget);
            pb = java.lang.ProcessBuilder(["wsl", "-e", "bash", "-c", cmd]);
            pb.redirectErrorStream(true);

            testCase.SITLProcess = pb.start();
            testCase.SITLReader = java.io.BufferedReader( ...
                java.io.InputStreamReader(testCase.SITLProcess.getInputStream()));

            % Wait for SITL to be ready
            tic;
            ready = false;
            while toc < testCase.StartupTimeout
                if testCase.SITLReader.ready()
                    line = string(testCase.SITLReader.readLine());
                    if contains(line, "udp port") || contains(line, "pxh>")
                        ready = true;
                        testCase.log(1, "SITL ready: " + line);
                        break;
                    end
                else
                    pause(0.1);
                end
            end

            testCase.assumeTrue(ready, ...
                "PX4 SITL did not start within " + testCase.StartupTimeout + "s");
            pause(2);  % Allow SITL to stabilize
        end

        function setBroadcast(testCase, enable)
            configPath = testCase.MavlinkConfigPath;
            if enable
                replacement = "mavlink_network_interface_arg=-p";
            else
                replacement = "mavlink_network_interface_arg=";
            end
            cmd = sprintf( ...
                'wsl -e bash -c "sed -i ''14s/.*/%s/'' %s"', ...
                replacement, configPath);
            [status, ~] = system(cmd);
            testCase.assumeEqual(status, 0, "Failed to set broadcast flag");
        end

        function [discovered, clients] = waitForDiscovery(testCase, mavlink)
            timeout = testCase.DiscoveryTimeout;
            tic;
            discovered = false;
            clients = listClients(mavlink);
            while toc < timeout
                clients = listClients(mavlink);
                if height(clients) > 1
                    discovered = true;
                    break;
                end
                pause(0.5);
            end
        end

        function hbMsg = buildHeartbeat(~, dialect)
            hbMsg = createmsg(dialect, "HEARTBEAT");
            hbMsg.Payload.type(:) = dialect.enum2num("MAV_TYPE", "MAV_TYPE_GCS");
            hbMsg.Payload.autopilot(:) = dialect.enum2num("MAV_AUTOPILOT", "MAV_AUTOPILOT_INVALID");
            hbMsg.Payload.base_mode(:) = 0;
            hbMsg.Payload.custom_mode(:) = 0;
            hbMsg.Payload.system_status(:) = 0;
        end
    end

    methods (Static, Access = private)
        function deleteTimer(t)
            if isvalid(t)
                stop(t);
                delete(t);
            end
        end
    end
end
