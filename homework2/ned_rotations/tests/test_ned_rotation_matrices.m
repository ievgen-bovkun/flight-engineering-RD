function tests = test_ned_rotation_matrices
%TEST_NED_ROTATION_MATRICES Verify the 3-2-1 NED rotation sequence.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testMatricesAreOrthonormal(testCase)
rotations = ned_rotation_matrices(deg2rad(30), deg2rad(20), deg2rad(45));

verifyEqual(testCase, rotations.roll.' * rotations.roll, eye(3), 'AbsTol', 1e-12);
verifyEqual(testCase, rotations.rollPitch.' * rotations.rollPitch, eye(3), 'AbsTol', 1e-12);
verifyEqual(testCase, rotations.full.' * rotations.full, eye(3), 'AbsTol', 1e-12);
end

function testSequenceMatchesYawPitchRollProduct(testCase)
phi = deg2rad(30); theta = deg2rad(20); psi = deg2rad(45);
rotations = ned_rotation_matrices(phi, theta, psi);

Rx = [1, 0, 0; 0, cos(phi), -sin(phi); 0, sin(phi), cos(phi)];
Ry = [cos(theta), 0, sin(theta); 0, 1, 0; -sin(theta), 0, cos(theta)];
Rz = [cos(psi), -sin(psi), 0; sin(psi), cos(psi), 0; 0, 0, 1];

verifyEqual(testCase, rotations.full, Rz * Ry * Rx, 'AbsTol', 1e-12);
end
