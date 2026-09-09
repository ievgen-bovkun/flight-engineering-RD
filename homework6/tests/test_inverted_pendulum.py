import unittest

import numpy as np

from homework6.src.inverted_pendulum import (
    PIDController,
    PendulumParameters,
    linear_matrices,
    linear_derivative,
    nonlinear_derivative,
)


class InvertedPendulumTests(unittest.TestCase):
    def test_linearization_matches_nonlinear_derivative_near_upright_equilibrium(self):
        params = PendulumParameters()
        state = np.array([0.02, -0.03, 1e-6, 0.04])
        force = 0.5
        a_matrix, b_matrix, _, _ = linear_matrices(params)

        nonlinear = nonlinear_derivative(state, force, params)
        linear = linear_derivative(state, force, a_matrix, b_matrix)

        np.testing.assert_allclose(nonlinear, linear, rtol=2e-5, atol=2e-7)

    def test_pid_saturates_control_force(self):
        pid = PIDController(kp=40.0, ki=50.0, kd=5.0, dt=0.005, u_limit=20.0)

        force = pid.update(measurement=np.deg2rad(90.0), reference=0.0)

        self.assertEqual(force, 20.0)


if __name__ == "__main__":
    unittest.main()
