"""Linear and nonlinear cart-pendulum models with sampled PID control."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable

import matplotlib.pyplot as plt
import numpy as np


@dataclass(frozen=True)
class PendulumParameters:
    cart_mass: float = 0.5
    pendulum_mass: float = 0.2
    cart_damping: float = 0.1
    length_to_com: float = 0.3
    pendulum_inertia: float = 0.006
    gravity: float = 9.81


@dataclass(frozen=True)
class SimulationResult:
    time: np.ndarray
    states: np.ndarray
    force: np.ndarray


def linear_matrices(params: PendulumParameters) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Return A, B, C, D around the upright equilibrium theta=0."""
    m_cart, m_pendulum = params.cart_mass, params.pendulum_mass
    length, inertia, damping, gravity = (params.length_to_com, params.pendulum_inertia, params.cart_damping, params.gravity)
    common = inertia * (m_cart + m_pendulum) + m_cart * m_pendulum * length**2
    a_matrix = np.array([
        [0.0, 1.0, 0.0, 0.0],
        [0.0, -(inertia + m_pendulum * length**2) * damping / common, -(m_pendulum**2) * gravity * length**2 / common, 0.0],
        [0.0, 0.0, 0.0, 1.0],
        [0.0, m_pendulum * length * damping / common, (m_cart + m_pendulum) * m_pendulum * gravity * length / common, 0.0],
    ])
    b_matrix = np.array([[0.0], [(inertia + m_pendulum * length**2) / common], [0.0], [-m_pendulum * length / common]])
    c_matrix = np.array([[1.0, 0.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0]])
    return a_matrix, b_matrix, c_matrix, np.zeros((2, 1))


def nonlinear_derivative(state: np.ndarray, force: float, params: PendulumParameters) -> np.ndarray:
    """Return the nonlinear derivatives from the Lagrange equations."""
    _, cart_velocity, angle, angular_velocity = np.asarray(state, dtype=float)
    cosine, sine = np.cos(angle), np.sin(angle)
    matrix = np.array([
        [params.cart_mass + params.pendulum_mass, params.pendulum_mass * params.length_to_com * cosine],
        [params.pendulum_mass * params.length_to_com * cosine, params.pendulum_inertia + params.pendulum_mass * params.length_to_com**2],
    ])
    rhs = np.array([
        force - params.cart_damping * cart_velocity + params.pendulum_mass * params.length_to_com * angular_velocity**2 * sine,
        params.pendulum_mass * params.gravity * params.length_to_com * sine,
    ])
    cart_acceleration, angular_acceleration = np.linalg.solve(matrix, rhs)
    return np.array([cart_velocity, cart_acceleration, angular_velocity, angular_acceleration])


def linear_derivative(state: np.ndarray, force: float, a_matrix: np.ndarray, b_matrix: np.ndarray) -> np.ndarray:
    return a_matrix @ np.asarray(state, dtype=float) + b_matrix.reshape(-1) * force


def rk4_step(derivative: Callable[[np.ndarray, float], np.ndarray], state: np.ndarray, force: float, dt: float) -> np.ndarray:
    """Advance exactly one fixed RK4 step while holding force constant."""
    k1 = derivative(state, force)
    k2 = derivative(state + dt * k1 / 2, force)
    k3 = derivative(state + dt * k2 / 2, force)
    k4 = derivative(state + dt * k3, force)
    return state + dt * (k1 + 2 * k2 + 2 * k3 + k4) / 6


class PIDController:
    """Sampled PID with derivative filtering, saturation, and conditional integration."""

    def __init__(self, kp: float, ki: float, kd: float, dt: float, u_limit: float = 20.0, derivative_filter: float = 0.02):
        self.kp, self.ki, self.kd = kp, ki, kd
        self.dt, self.u_limit, self.derivative_filter = dt, u_limit, derivative_filter
        self.integral = 0.0
        self.previous_error: float | None = None
        self.filtered_derivative = 0.0

    def update(self, measurement: float, reference: float = 0.0) -> float:
        error = measurement - reference
        raw_derivative = 0.0 if self.previous_error is None else (error - self.previous_error) / self.dt
        alpha = self.dt / (self.derivative_filter + self.dt)
        self.filtered_derivative += alpha * (raw_derivative - self.filtered_derivative)
        unsaturated = self.kp * error + self.ki * self.integral + self.kd * self.filtered_derivative
        force = float(np.clip(unsaturated, -self.u_limit, self.u_limit))
        if np.isclose(force, unsaturated):
            self.integral += error * self.dt
        self.previous_error = error
        return force


def simulate(
    derivative: Callable[[np.ndarray, float], np.ndarray],
    initial_state: np.ndarray,
    *,
    t_end: float,
    dt: float,
    controller: PIDController | None = None,
) -> SimulationResult:
    """Run a sampled-data simulation: PID update, ZOH force, one RK4 step."""
    count = int(round(t_end / dt)) + 1
    time = np.linspace(0.0, t_end, count)
    states = np.zeros((count, 4))
    force = np.zeros(count)
    states[0] = initial_state
    for index in range(count - 1):
        force[index] = controller.update(states[index, 2]) if controller else 0.0
        states[index + 1] = rk4_step(derivative, states[index], force[index], dt)
        if not np.all(np.isfinite(states[index + 1])) or abs(states[index + 1, 2]) > np.deg2rad(720):
            states[index + 1 :] = states[index + 1]
            force[index + 1 :] = force[index]
            break
    force[-1] = force[-2]
    return SimulationResult(time=time, states=states, force=force)


def sustained_angle_settling_time(result: SimulationResult, threshold_deg: float = 0.5) -> float | None:
    outside = np.flatnonzero(np.abs(np.rad2deg(result.states[:, 2])) > threshold_deg)
    if outside.size == 0:
        return float(result.time[0])
    if outside[-1] == len(result.time) - 1:
        return None
    return float(result.time[outside[-1] + 1])


def run_experiments(output_path: Path) -> dict[str, float | None]:
    """Generate all comparison plots and return report metrics."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    params = PendulumParameters()
    a_matrix, b_matrix, _, _ = linear_matrices(params)
    linear = lambda state, force: linear_derivative(state, force, a_matrix, b_matrix)
    nonlinear = lambda state, force: nonlinear_derivative(state, force, params)
    dt = 0.005
    initial_small = np.array([0.0, 0.0, np.deg2rad(10.0), 0.0])
    initial_large = np.array([0.0, 0.0, np.deg2rad(60.0), 0.0])
    open_linear = simulate(linear, initial_small, t_end=2.5, dt=dt)
    open_nonlinear = simulate(nonlinear, initial_small, t_end=2.5, dt=dt)
    gains = dict(kp=40.0, ki=50.0, kd=5.0, dt=dt)
    closed_linear = simulate(linear, initial_small, t_end=5.0, dt=dt, controller=PIDController(**gains))
    closed_nonlinear = simulate(nonlinear, initial_small, t_end=5.0, dt=dt, controller=PIDController(**gains))
    large_linear = simulate(linear, initial_large, t_end=3.0, dt=dt, controller=PIDController(**gains))
    large_nonlinear = simulate(nonlinear, initial_large, t_end=3.0, dt=dt, controller=PIDController(**gains))

    fig, axes = plt.subplots(2, 2, figsize=(13.5, 9))
    axes[0, 0].plot(open_linear.time, np.rad2deg(open_linear.states[:, 2]), label="linear model")
    axes[0, 0].plot(open_nonlinear.time, np.rad2deg(open_nonlinear.states[:, 2]), "--", label="nonlinear model")
    axes[0, 0].set(title="Open loop: upright equilibrium is unstable", ylabel="angle, deg")
    axes[0, 1].plot(closed_linear.time, np.rad2deg(closed_linear.states[:, 2]), label="linear + PID")
    axes[0, 1].plot(closed_nonlinear.time, np.rad2deg(closed_nonlinear.states[:, 2]), "--", label="nonlinear + PID")
    axes[0, 1].set(title="Closed loop at 10 deg initial error", ylabel="angle, deg")
    axes[1, 0].plot(closed_linear.time, closed_linear.force, label="linear force")
    axes[1, 0].plot(closed_nonlinear.time, closed_nonlinear.force, "--", label="nonlinear force")
    axes[1, 0].set(title="PID control force", xlabel="time, s", ylabel="force, N")
    cart_axis = axes[1, 0].twinx()
    cart_axis.plot(closed_nonlinear.time, closed_nonlinear.states[:, 0], color="#2ca02c", alpha=0.8, label="cart position")
    cart_axis.set_ylabel("cart position, m", color="#2ca02c")
    axes[1, 1].plot(large_linear.time, np.rad2deg(large_linear.states[:, 2]), label="linear + PID")
    axes[1, 1].plot(large_nonlinear.time, np.rad2deg(large_nonlinear.states[:, 2]), "--", label="nonlinear + PID")
    axes[1, 1].set(title="Large 60 deg error: linearization limit", xlabel="time, s", ylabel="angle, deg")
    for axis in axes.ravel():
        axis.grid(alpha=0.3)
        axis.legend(fontsize=8)
        axis.set_xlabel("time, s")
    fig.tight_layout()
    fig.savefig(output_path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return {
        "angle_settling_time": sustained_angle_settling_time(closed_nonlinear),
        "max_angle_deg": float(np.rad2deg(np.abs(closed_nonlinear.states[:, 2])).max()),
        "max_force_n": float(np.abs(closed_nonlinear.force).max()),
        "final_cart_position_m": float(closed_nonlinear.states[-1, 0]),
        "large_angle_model_gap_deg": float(np.rad2deg(np.abs(large_linear.states[:, 2] - large_nonlinear.states[:, 2])).max()),
    }
