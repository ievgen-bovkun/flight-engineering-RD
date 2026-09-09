import math
import unittest

from homework6.src.transfer_function import analyze_transfer_function


class TransferFunctionTests(unittest.TestCase):
    def test_second_order_metrics_match_hand_derived_values(self):
        analysis = analyze_transfer_function([10], [1, 3, 10], time_end=5.0, samples=5001)

        self.assertAlmostEqual(analysis.y_final, 1.0, places=6)
        self.assertAlmostEqual(analysis.y_peak, 1.1840146, places=4)
        self.assertAlmostEqual(analysis.t_peak, math.pi / math.sqrt(7.75), places=3)
        self.assertAlmostEqual(analysis.t_settle_2pct, 2.61, places=2)
        self.assertTrue(analysis.is_asymptotically_stable)

    def test_unsettled_horizon_is_reported_as_none(self):
        analysis = analyze_transfer_function([10], [1, 3, 10], time_end=0.2, samples=201)

        self.assertIsNone(analysis.t_settle_2pct)


if __name__ == "__main__":
    unittest.main()
