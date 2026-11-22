-- =============================================================================
-- Migration 002 - Immutable audit log
--
-- Every score entry, change and submission, and every security event
-- (login, denied access) is recorded with timestamp, actor and old/new values.
--
--   * Append-only: UPDATE, DELETE and TRUNCATE on audit_log are rejected.
--   * Tamper-evident: each row stores a SHA-256 hash of its content chained
--     to the hash of the previous row. Changing or removing any row breaks
--     the chain, which verify_audit_chain() detects.
--   * Not bypassable by the application: evaluation changes are logged by a
--     database trigger, so even a direct SQL change to a score is recorded.
--
-- ISO/IEC 25010 - Accountability, Non-repudiation
-- ISO/IEC 27001:2022 - A 8.15 Logging
-- =============================================================================

-- The id is assigned inside the chain trigger (not by a column default),
-- so ids have no gaps and always follow the chain order.
CREATE SEQUENCE audit_log_id_seq;

CREATE TABLE audit_log (
    audit_id        BIGINT       PRIMARY KEY,
    occurred_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    -- No foreign key on purpose: a log entry must survive even if the user
    -- is deleted later, and a cascading update would be blocked anyway.
    actor_user_id   INT,
    action          VARCHAR(40)  NOT NULL CHECK (action IN (
                        'LOGIN_SUCCESS', 'LOGIN_FAILURE', 'ACCESS_DENIED',
                        'EVALUATION_CREATE', 'EVALUATION_UPDATE', 'EVALUATION_SUBMIT')),
    entity_type     VARCHAR(40),
    entity_id       INT,
    project_id      INT,
    student_id      INT,
    criteria_id     INT,
    old_value       JSONB,
    new_value       JSONB,
    details         JSONB,
    prev_hash       CHAR(64),
    row_hash        CHAR(64)     NOT NULL
);

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.audit_id;

CREATE INDEX idx_audit_project ON audit_log (project_id, student_id);
CREATE INDEX idx_audit_actor   ON audit_log (actor_user_id);
CREATE INDEX idx_audit_time    ON audit_log (occurred_at);

-- -----------------------------------------------------------------------------
-- Hash of one entry. The same function is used when writing and when
-- verifying, so both always agree on the exact input.
-- -----------------------------------------------------------------------------
CREATE FUNCTION audit_row_hash(
    p_prev_hash   TEXT,
    p_audit_id    BIGINT,
    p_occurred_at TIMESTAMPTZ,
    p_actor       INT,
    p_action      TEXT,
    p_entity_type TEXT,
    p_entity_id   INT,
    p_project_id  INT,
    p_student_id  INT,
    p_criteria_id INT,
    p_old_value   JSONB,
    p_new_value   JSONB,
    p_details     JSONB
) RETURNS CHAR(64)
LANGUAGE sql STABLE AS $$
    SELECT encode(sha256(convert_to(concat_ws('|',
        COALESCE(p_prev_hash, 'GENESIS'),
        p_audit_id,
        to_char(p_occurred_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
        COALESCE(p_actor::text, ''),
        p_action,
        COALESCE(p_entity_type, ''),
        COALESCE(p_entity_id::text, ''),
        COALESCE(p_project_id::text, ''),
        COALESCE(p_student_id::text, ''),
        COALESCE(p_criteria_id::text, ''),
        COALESCE(p_old_value::text, ''),
        COALESCE(p_new_value::text, ''),
        COALESCE(p_details::text, '')
    ), 'UTF8')), 'hex');
$$;

-- -----------------------------------------------------------------------------
-- BEFORE INSERT: link the new row to the chain.
-- An advisory lock serialises concurrent inserts, and the id is taken only
-- after the lock, so id order always equals chain order.
-- -----------------------------------------------------------------------------
CREATE FUNCTION audit_log_chain() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('audit_log_chain'));

    NEW.audit_id    := nextval('audit_log_id_seq');
    NEW.occurred_at := clock_timestamp();

    SELECT row_hash INTO NEW.prev_hash
      FROM audit_log
     ORDER BY audit_id DESC
     LIMIT 1;

    NEW.row_hash := audit_row_hash(
        NEW.prev_hash, NEW.audit_id, NEW.occurred_at, NEW.actor_user_id, NEW.action,
        NEW.entity_type, NEW.entity_id, NEW.project_id, NEW.student_id, NEW.criteria_id,
        NEW.old_value, NEW.new_value, NEW.details);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_log_chain
    BEFORE INSERT ON audit_log
    FOR EACH ROW EXECUTE FUNCTION audit_log_chain();

-- -----------------------------------------------------------------------------
-- Append-only: any attempt to change or remove log entries is rejected.
-- -----------------------------------------------------------------------------
CREATE FUNCTION audit_log_reject_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is append-only: % is not allowed', TG_OP
        USING ERRCODE = 'insufficient_privilege';
END;
$$;

CREATE TRIGGER trg_audit_log_no_update_delete
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION audit_log_reject_change();

CREATE TRIGGER trg_audit_log_no_truncate
    BEFORE TRUNCATE ON audit_log
    FOR EACH STATEMENT EXECUTE FUNCTION audit_log_reject_change();

-- -----------------------------------------------------------------------------
-- Integrity check: returns the id of the first entry whose hash does not
-- match its content or whose link to the previous entry is broken.
-- NULL means the whole chain is intact.
-- -----------------------------------------------------------------------------
CREATE FUNCTION verify_audit_chain() RETURNS BIGINT
LANGUAGE plpgsql STABLE AS $$
DECLARE
    r        audit_log%ROWTYPE;
    expected CHAR(64) := NULL;
BEGIN
    FOR r IN SELECT * FROM audit_log ORDER BY audit_id LOOP
        IF r.prev_hash IS DISTINCT FROM expected
           OR r.row_hash <> audit_row_hash(
                r.prev_hash, r.audit_id, r.occurred_at, r.actor_user_id, r.action,
                r.entity_type, r.entity_id, r.project_id, r.student_id, r.criteria_id,
                r.old_value, r.new_value, r.details) THEN
            RETURN r.audit_id;
        END IF;
        expected := r.row_hash;
    END LOOP;
    RETURN NULL;
END;
$$;

-- -----------------------------------------------------------------------------
-- Automatic logging of evaluation changes.
-- The application identifies the acting user for the current transaction
-- with:  SELECT set_config('app.current_user_id', '<user_id>', true);
-- A change made without this context (e.g. directly in psql) is still
-- logged, with actor NULL and source "direct_db", so it stands out.
-- -----------------------------------------------------------------------------
CREATE FUNCTION log_evaluation_change() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_actor  INT := NULLIF(current_setting('app.current_user_id', true), '')::INT;
    v_action TEXT;
    v_old    JSONB;
    v_new    JSONB;
BEGIN
    v_new := jsonb_build_object(
        'score', NEW.score, 'comment', NEW.comment, 'is_submitted', NEW.is_submitted);

    IF TG_OP = 'INSERT' THEN
        v_action := CASE WHEN NEW.is_submitted THEN 'EVALUATION_SUBMIT' ELSE 'EVALUATION_CREATE' END;
    ELSE
        v_old := jsonb_build_object(
            'score', OLD.score, 'comment', OLD.comment, 'is_submitted', OLD.is_submitted);
        IF v_old = v_new THEN
            RETURN NEW;                       -- nothing that matters changed
        END IF;
        v_action := CASE WHEN NEW.is_submitted AND NOT OLD.is_submitted
                         THEN 'EVALUATION_SUBMIT' ELSE 'EVALUATION_UPDATE' END;
    END IF;

    INSERT INTO audit_log (actor_user_id, action, entity_type, entity_id,
                           project_id, student_id, criteria_id,
                           old_value, new_value, details)
    VALUES (v_actor, v_action, 'evaluation', NEW.evaluation_id,
            NEW.project_id, NEW.student_id, NEW.criteria_id,
            v_old, v_new,
            jsonb_build_object('jury_id', NEW.jury_id,
                               'source', CASE WHEN v_actor IS NULL THEN 'direct_db' ELSE 'api' END));
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_evaluations_audit
    AFTER INSERT OR UPDATE ON evaluations
    FOR EACH ROW EXECUTE FUNCTION log_evaluation_change();
