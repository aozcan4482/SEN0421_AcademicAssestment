-- =============================================================================
-- Migration 001 - Initial schema
-- Academic Assessment & Audit Management System
--
-- Implements the information view defined in Sprint 1 / WP-04
-- (IEEE 1016 - Information Viewpoint, ISO/IEC 25010 - Integrity).
--
-- Tables are created in dependency order so that every foreign key
-- refers to a table that already exists.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- users
-- Jury members and students sign in through CATS (cats_username).
-- Administrators sign in locally; password_hash stores a bcrypt hash for
-- them and stays NULL for CATS accounts (no CATS password is ever stored).
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    user_id         SERIAL       PRIMARY KEY,
    cats_username   VARCHAR(50)  NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE,
    password_hash   VARCHAR(255),
    role            VARCHAR(20)  NOT NULL
                    CHECK (role IN ('Admin', 'Jury', 'Student')),
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),

    -- Only local (Admin) accounts may carry a password hash.
    CONSTRAINT users_password_only_for_admin
        CHECK (password_hash IS NULL OR role = 'Admin')
);

-- -----------------------------------------------------------------------------
-- criteria
-- The rubric is data, not code: criteria and weights can be changed
-- without touching the application.
-- -----------------------------------------------------------------------------
CREATE TABLE criteria (
    criteria_id     SERIAL        PRIMARY KEY,
    criteria_name   VARCHAR(100)  NOT NULL UNIQUE,
    weight          NUMERIC(4, 3) NOT NULL
                    CHECK (weight >= 0 AND weight <= 1)
);

-- -----------------------------------------------------------------------------
-- projects
-- -----------------------------------------------------------------------------
CREATE TABLE projects (
    project_id      SERIAL       PRIMARY KEY,
    project_name    VARCHAR(200) NOT NULL,
    description     TEXT,
    advisor_id      INT          REFERENCES users (user_id) ON DELETE SET NULL,
    exam_datetime   TIMESTAMP,
    status          VARCHAR(20)  NOT NULL DEFAULT 'Pending'
                    CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Finalized')),
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- project_members  (a project may have several students)
-- -----------------------------------------------------------------------------
CREATE TABLE project_members (
    member_id       SERIAL PRIMARY KEY,
    project_id      INT    NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    student_id      INT    NOT NULL REFERENCES users (user_id)       ON DELETE CASCADE,
    UNIQUE (project_id, student_id)
);

-- -----------------------------------------------------------------------------
-- jury_assignments
-- -----------------------------------------------------------------------------
CREATE TABLE jury_assignments (
    assignment_id   SERIAL    PRIMARY KEY,
    jury_id         INT       NOT NULL REFERENCES users (user_id)       ON DELETE CASCADE,
    project_id      INT       NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    assigned_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    is_completed    BOOLEAN   NOT NULL DEFAULT FALSE,
    completed_at    TIMESTAMP,
    UNIQUE (jury_id, project_id)
);

-- -----------------------------------------------------------------------------
-- evaluations
-- One row per jury x project x student x criterion, so every member of a
-- team is scored individually (RSK-01).
-- -----------------------------------------------------------------------------
CREATE TABLE evaluations (
    evaluation_id   SERIAL    PRIMARY KEY,
    jury_id         INT       NOT NULL REFERENCES users (user_id),
    project_id      INT       NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    student_id      INT       NOT NULL REFERENCES users (user_id),
    criteria_id     INT       NOT NULL REFERENCES criteria (criteria_id),
    score           INT       NOT NULL CHECK (score >= 0 AND score <= 100),
    comment         TEXT,
    is_submitted    BOOLEAN   NOT NULL DEFAULT FALSE,
    submitted_at    TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (jury_id, project_id, student_id, criteria_id),

    -- A score may only be given by a jury member assigned to the project
    -- (WP-02 ownership rule) and only to a student who belongs to it.
    CONSTRAINT evaluations_jury_assigned
        FOREIGN KEY (jury_id, project_id)
        REFERENCES jury_assignments (jury_id, project_id) ON DELETE CASCADE,
    CONSTRAINT evaluations_student_is_member
        FOREIGN KEY (project_id, student_id)
        REFERENCES project_members (project_id, student_id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- final_results  (weighted score per student and project)
-- -----------------------------------------------------------------------------
CREATE TABLE final_results (
    result_id             SERIAL        PRIMARY KEY,
    project_id            INT           NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    student_id            INT           NOT NULL REFERENCES users (user_id)       ON DELETE CASCADE,
    total_weighted_score  NUMERIC(5, 2) NOT NULL
                          CHECK (total_weighted_score >= 0 AND total_weighted_score <= 100),
    generated_at          TIMESTAMP     NOT NULL DEFAULT NOW(),
    UNIQUE (project_id, student_id)
);

-- -----------------------------------------------------------------------------
-- Indexes for the foreign keys used by the most frequent lookups
-- (assigned projects of a jury, members of a project, scores of a project).
-- -----------------------------------------------------------------------------
CREATE INDEX idx_projects_advisor       ON projects (advisor_id);
CREATE INDEX idx_members_student        ON project_members (student_id);
CREATE INDEX idx_assignments_project    ON jury_assignments (project_id);
CREATE INDEX idx_evaluations_project    ON evaluations (project_id, student_id);
CREATE INDEX idx_final_results_student  ON final_results (student_id);

-- -----------------------------------------------------------------------------
-- Rule: the weights of all criteria must add up to 1.0 (WP-04, section 5).
-- A single row cannot express this, so it is enforced by a deferred
-- constraint trigger that runs at COMMIT. This lets a transaction change
-- several weights at once and only checks the final total.
-- -----------------------------------------------------------------------------
CREATE FUNCTION check_criteria_weight_total() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(weight), 0) INTO total FROM criteria;
    IF EXISTS (SELECT 1 FROM criteria) AND ABS(total - 1.0) > 0.0001 THEN
        RAISE EXCEPTION 'Criteria weights must sum to 1.0 (current total: %)', total
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_criteria_weight_total
    AFTER INSERT OR UPDATE OR DELETE ON criteria
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION check_criteria_weight_total();
