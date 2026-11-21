-- =============================================================================
-- Seed 002 - Demo data for local development
-- Fictional accounts only. Do NOT load this file in production.
--
-- The administrator is created without a password; the local-login module
-- sets the bcrypt hash during its own setup step.
-- Safe to run more than once.
-- =============================================================================
INSERT INTO users (cats_username, name, email, role) VALUES
    ('admin',       'System Administrator', 'admin@example.edu',       'Admin'),
    ('jury.demo1',  'Demo Jury One',        'jury1@example.edu',       'Jury'),
    ('jury.demo2',  'Demo Jury Two',        'jury2@example.edu',       'Jury'),
    ('student.d1',  'Demo Student One',     'student1@example.edu',    'Student'),
    ('student.d2',  'Demo Student Two',     'student2@example.edu',    'Student'),
    ('student.d3',  'Demo Student Three',   'student3@example.edu',    'Student')
ON CONFLICT (cats_username) DO NOTHING;

-- Two demo projects: one team project, one individual project.
INSERT INTO projects (project_name, description, advisor_id, exam_datetime, status)
SELECT v.project_name, v.description, u.user_id, v.exam_datetime::timestamp, 'Pending'
FROM (VALUES
    ('Smart Campus Navigation', 'Indoor navigation app for the campus (team project).', '2026-12-15 10:00'),
    ('Library Seat Tracker',    'IoT-based seat occupancy tracker (individual project).', '2026-12-15 14:00')
) AS v(project_name, description, exam_datetime)
JOIN users u ON u.cats_username = 'jury.demo1'
WHERE NOT EXISTS (SELECT 1 FROM projects p WHERE p.project_name = v.project_name)
ORDER BY v.exam_datetime;

-- Team members
INSERT INTO project_members (project_id, student_id)
SELECT p.project_id, u.user_id
FROM projects p
JOIN users u ON (p.project_name = 'Smart Campus Navigation' AND u.cats_username IN ('student.d1', 'student.d2'))
             OR (p.project_name = 'Library Seat Tracker'    AND u.cats_username = 'student.d3')
ON CONFLICT (project_id, student_id) DO NOTHING;

-- Both demo jury members evaluate both projects.
INSERT INTO jury_assignments (jury_id, project_id)
SELECT u.user_id, p.project_id
FROM users u CROSS JOIN projects p
WHERE u.cats_username IN ('jury.demo1', 'jury.demo2')
ON CONFLICT (jury_id, project_id) DO NOTHING;
