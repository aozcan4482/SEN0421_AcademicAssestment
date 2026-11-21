-- =============================================================================
-- Seed 001 - Evaluation criteria (WP-04, section 6)
-- The six weights add up to 1.00; the deferred trigger verifies this at COMMIT.
-- Safe to run more than once.
-- =============================================================================
INSERT INTO criteria (criteria_name, weight) VALUES
    ('Technical Merits',                  0.15),
    ('Project Design and Implementation', 0.40),
    ('Report',                            0.15),
    ('Presentation',                      0.10),
    ('Demo',                              0.10),
    ('Papers',                            0.10)
ON CONFLICT (criteria_name) DO UPDATE SET weight = EXCLUDED.weight;
