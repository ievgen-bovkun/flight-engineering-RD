function rotations = ned_rotation_matrices(phi, theta, psi)
%NED_ROTATION_MATRICES Return sequential 3-2-1 NED rotation matrices.
% phi: roll about North, theta: pitch about intermediate East,
% psi: yaw about final Down. Angles are in radians.

Rx = [1, 0, 0; ...
      0, cos(phi), -sin(phi); ...
      0, sin(phi), cos(phi)];
Ry = [cos(theta), 0, sin(theta); ...
      0, 1, 0; ...
      -sin(theta), 0, cos(theta)];
Rz = [cos(psi), -sin(psi), 0; ...
      sin(psi), cos(psi), 0; ...
      0, 0, 1];

rotations.initial = eye(3);
rotations.roll = Rx;
rotations.rollPitch = Ry * Rx;
rotations.full = Rz * Ry * Rx;
end
