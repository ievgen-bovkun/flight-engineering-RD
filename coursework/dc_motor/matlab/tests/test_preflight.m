function tests = test_preflight
tests = functiontests(localfunctions);
end

function testCoreCliAndCapabilityEvidence(tc)
env = preflight(false);
verifyTrue(tc, env.matlabSmoke);
verifyTrue(tc, env.simulinkSmoke);
verifyEqual(tc, env.release, version('-release'));
verifyEqual(tc, env.simscape, ~isempty(ver('simscape')) && ~isempty(which('fl_lib')));
verifyEqual(tc, env.fmuExporter, ~isempty(which('exportToFMU')));
verifyTrue(tc, isfile(fullfile(env.projectRoot, 'results', 'json', 'environment.json')));
end

function testRequiredCapabilitiesCannotBeSilentlySkipped(tc)
env = preflight(false);
if isempty(env.missingRequired)
    verifyTrue(tc, preflight(true).complete);
else
    verifyError(tc, @() preflight(true), 'dc_motor:MissingPrerequisites');
end
end
