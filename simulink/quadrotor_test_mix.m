function mix = quadrotor_test_mix(channel)
%QUADROTOR_TEST_MIX Unit-step motor patterns for the four control channels.

switch lower(string(channel))
    case "vertical"
        mix = [1; 1; 1; 1];
    case "roll"
        mix = [0; 1; 0; -1];
    case "pitch"
        mix = [1; 0; -1; 0];
    case "yaw"
        mix = [-1; 1; -1; 1];
    otherwise
        error('quadrotor_test_mix:UnknownChannel', ...
            'Use vertical, roll, pitch, or yaw.');
end
end
