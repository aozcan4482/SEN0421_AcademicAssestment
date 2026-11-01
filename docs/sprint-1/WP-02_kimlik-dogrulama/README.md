# CATS Authentication & RBAC – Proof of Concept

Sprint 1 – WP-02. This prototype validates two security rules before they are implemented in the main Node.js backend:

1. **Authentication:** User credentials are forwarded to the IKU CATS portal. A `302` redirect from CATS means the login succeeded. Passwords are never stored by the application.
2. **Authorization:** After login, the user gets a role (Student / Jury). A jury member can only open and submit evaluations assigned to them. Any other request returns `403 Forbidden` / `ACCESS DENIED`.

> This is a proof of concept only. Roles and evaluation ownership are kept in memory (`USER_ROLES`, `EVALUATION_OWNERS`). In the final system they come from the PostgreSQL database.

## Run

```bash
pip install -r requirements.txt
python app.py
```

Open http://127.0.0.1:5000 and log in with a CATS account.

## Test scenarios

| # | Scenario | Expected result |
|---|---|---|
| 1 | Wrong CATS password | "Authentication Failed" |
| 2 | Valid CATS user not in `USER_ROLES` | "Authenticated but NOT authorized" |
| 3 | Student opens `/jury` | 403 Forbidden |
| 4 | Jury opens their own evaluation | Evaluation form is shown |
| 5 | Jury opens another jury's evaluation | ACCESS DENIED – Not your evaluation |
