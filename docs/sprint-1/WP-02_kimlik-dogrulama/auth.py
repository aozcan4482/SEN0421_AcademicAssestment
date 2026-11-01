# coding=cp1254
from flask import Flask, request, redirect, session, url_for
import requests

app = Flask(__name__)
app.secret_key = "secretkey"

CATS_LOGIN_URL = "https://cats.iku.edu.tr/portal/xlogin"

USER_ROLES = {
    "2200004962": "Student",
    "2200004482": "Jury",
    "2200005058": "Jury"
}

EVALUATION_OWNERS = {
    1: "2200004482",
    2: "2200004482",
    3: "2200005058"
}

def authenticate(username, password):
    payload = {
        "eid": username,
        "pw": password,
        "submit": "Login"
    }

    try:
        response = requests.post(
            CATS_LOGIN_URL,
            data=payload,
            allow_redirects=False,
            timeout=10
        )
        return response.status_code == 302
    except requests.RequestException:
        return False

@app.route("/")
def index():
    return """
    <h2>CATS Secure Authentication Demo</h2>
    <form method="post" action="/login">
        Username:<br>
        <input name="username" required><br><br>
        Password:<br>
        <input type="password" name="password" required><br><br>
        <button type="submit">Login</button>
    </form>
    """

@app.route("/login", methods=["POST"])
def login():
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "").strip()

    if not authenticate(username, password):
        return "<h3>Authentication Failed</h3><a href='/'>Back</a>"

    role = USER_ROLES.get(username)

    if role is None:
        return "<h3>Authenticated but NOT authorized</h3><a href='/'>Back</a>"

    session["user"] = username
    session["role"] = role

    return redirect(url_for("dashboard"))

@app.route("/dashboard")
def dashboard():
    user = session.get("user")
    role = session.get("role")

    if not user:
        return redirect(url_for("index"))

    html = f"""
    <h2>Dashboard</h2>
    <p>User: {user}</p>
    <p>Role: {role}</p>
    """

    if role == "Student":
        html += "<p>Student panel access granted.</p>"

    if role == "Jury":
        html += "<p><a href='/jury'>Go to Jury Panel</a></p>"

    return html

@app.route("/jury")
def jury_panel():
    user = session.get("user")
    role = session.get("role")

    if role != "Jury":
        return "<h3>403 Forbidden</h3>"

    links = ""
    for eid, owner in EVALUATION_OWNERS.items():
        if owner == user:
            links += f"<li><a href='/evaluation/{eid}'>Evaluation {eid}</a></li>"

    return f"""
    <h2>Jury Panel</h2>
    <p>Logged in Jury: {user}</p>
    <ul>{links}</ul>
    """

@app.route("/evaluation/<int:eid>")
def evaluation(eid):
    user = session.get("user")
    role = session.get("role")

    if role != "Jury":
        return "<h3>403 Forbidden</h3>"

    owner = EVALUATION_OWNERS.get(eid)

    if owner != user:
        return "<h3>ACCESS DENIED - Not your evaluation</h3>"

    return f"""
    <h2>Evaluation {eid}</h2>
    <p>Authorized Jury: {user}</p>
    <form method="post" action="/submit/{eid}">
        Score:
        <input type="number" name="score" min="1" max="10" required><br><br>
        Comment:
        <textarea name="comment"></textarea><br><br>
        <button type="submit">Submit</button>
    </form>
    """

@app.route("/submit/<int:eid>", methods=["POST"])
def submit(eid):
    user = session.get("user")

    owner = EVALUATION_OWNERS.get(eid)

    if owner != user:
        return "<h3>Unauthorized Submission</h3>"

    score = request.form.get("score")
    comment = request.form.get("comment")

    return f"""
    <h2>Submitted</h2>
    <p>Evaluation: {eid}</p>
    <p>Jury: {user}</p>
    <p>Score: {score}</p>
    <p>Comment: {comment}</p>
    """

if __name__ == "__main__":
    app.run(debug=True)