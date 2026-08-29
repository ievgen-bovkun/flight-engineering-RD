function tests = test_dz4_artifacts
tests = functiontests(localfunctions);
end

function testExportCreatesGraphAndModelEvidence(testCase)
result = dz4_export_artifacts(dz4_run(1));

verifyTrue(testCase, isfile(result.responses_png_path));
verifyTrue(testCase, isfile(result.altitude_dip_png_path));
verifyTrue(testCase, isfile(result.simulink_scheme_png_path));
end
