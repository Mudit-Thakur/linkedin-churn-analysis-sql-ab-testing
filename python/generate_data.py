import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import os

# -----------------------------
# CONFIG
# -----------------------------
NUM_USERS = 5000
START_DATE = datetime(2025, 1, 1)

np.random.seed(42)
random.seed(42)

# -----------------------------
# HELPER FUNCTIONS
# -----------------------------
def inject_noise(value):
    noise_chars = ['$', '@', '*', '  ']
    if pd.isna(value):
        return value
    value = str(value)
    if np.random.rand() < 0.2:
        noise = random.choice(noise_chars)
        return noise + value + noise
    return value


def generate_username(user_id):
    base = f"user{user_id}"
    variations = [
        base,
        base.upper(),
        base + str(np.random.randint(10,99)),
        base + "@@",
        " " + base,
        base + " ",
        base + "*",
        base.replace("user", "usr")
    ]
    return random.choice(variations)


def generate_email(username):
    domains = [
        "gmail.com", "yahoo.com", "outlook.com",
        "hotmail.com", "company.com", "mailinator.com"
    ]

    clean_username = username.strip().replace(" ", "").replace("*","").replace("@","")
    email = f"{clean_username}@{random.choice(domains)}"

    # Inject messiness
    if np.random.rand() < 0.2:
        email = " " + email
    if np.random.rand() < 0.2:
        email = email + " "
    if np.random.rand() < 0.1:
        email = email.replace("@", "@@")

    return email

# -----------------------------
# 1. USERS TABLE
# -----------------------------
users = []

for user_id in range(1, NUM_USERS + 1):
    signup_time = START_DATE + timedelta(days=np.random.randint(0, 60))
    profile_completion = np.random.randint(30, 100)
    premium_flag = np.random.choice([0, 1], p=[0.8, 0.2])

    username = generate_username(user_id)
    email = generate_email(username)

    users.append([
        user_id,
        signup_time,
        profile_completion,
        premium_flag,
        username,
        email
    ])

users_df = pd.DataFrame(users, columns=[
    "user_id", "signup_time", "profile_completion_pct",
    "premium_flag", "username", "email"
])

# Inject NULLs
users_df.loc[users_df.sample(frac=0.1).index, "profile_completion_pct"] = None

# Add duplicates
users_df = pd.concat([users_df, users_df.sample(frac=0.05)])
users_df = users_df.reset_index(drop=True)

# -----------------------------
# 2. RISK SIGNALS
# -----------------------------
risk_data = []

for user_id in users_df["user_id"].unique():
    ip_flag = np.random.choice([0,1], p=[0.85,0.15])
    rapid_flag = np.random.choice([0,1], p=[0.8,0.2])
    incomplete_flag = np.random.choice([0,1], p=[0.7,0.3])
    bot_score = round(np.random.uniform(0,1),2)

    risk_data.append([user_id, ip_flag, rapid_flag, incomplete_flag, bot_score])

risk_df = pd.DataFrame(risk_data, columns=[
    "user_id", "ip_mismatch_flag", "rapid_activity_flag",
    "incomplete_profile_flag", "bot_score"
])

# -----------------------------
# 3. EXPERIMENTS (A/B TEST)
# -----------------------------
exp_data = []

for user_id in users_df["user_id"].unique():
    group = np.random.choice(["A","B"])
    exp_data.append([user_id, "restriction_test", group])

exp_df = pd.DataFrame(exp_data, columns=[
    "user_id", "experiment_name", "experiment_group"
])

# -----------------------------
# 4. CONTENT QUALITY
# -----------------------------
content_data = []

for user_id in users_df["user_id"].unique():
    spam = np.random.poisson(2)
    irrelevant = np.random.poisson(3)
    low_match = np.random.poisson(2)

    content_data.append([user_id, spam, irrelevant, low_match])

content_df = pd.DataFrame(content_data, columns=[
    "user_id", "spam_messages_received",
    "irrelevant_jobs_seen", "low_match_recommendations"
])

# Outliers
content_df.loc[content_df.sample(frac=0.02).index, "spam_messages_received"] = 999

# Inject noise
for col in ["spam_messages_received", "irrelevant_jobs_seen"]:
    content_df[col] = content_df[col].apply(inject_noise)

# -----------------------------
# 5. EVENTS TABLE
# -----------------------------
events = []
event_types = ["login", "job_view", "apply", "logout"]

for _, row in users_df.drop_duplicates("user_id").iterrows():
    user_id = row["user_id"]
    signup_time = row["signup_time"]

    events.append([user_id, signup_time, "signup"])

    num_events = np.random.randint(5, 25)
    last_time = signup_time

    for _ in range(num_events):
        gap = np.random.randint(1, 48)
        event_time = last_time + timedelta(hours=gap)

        event_type = np.random.choice(event_types, p=[0.3, 0.4, 0.2, 0.1])

        events.append([user_id, event_time, event_type])
        last_time = event_time

events_df = pd.DataFrame(events, columns=[
    "user_id", "event_time", "event_type"
])

events_df.insert(0, "event_id", range(1, len(events_df) + 1))

# Messy device + geo
events_df["device_type"] = np.random.choice(
    ["mobile", "web", "Mobile ", " WEB", None],
    size=len(events_df)
)

events_df["geo_location"] = np.random.choice(
    ["India", "US", "UK", "India ", " US", None],
    size=len(events_df)
)

# Messy casing
events_df["event_type"] = events_df["event_type"].apply(
    lambda x: x.upper() if np.random.rand() < 0.3 else x
)

# Null timestamps
events_df.loc[events_df.sample(frac=0.05).index, "event_time"] = None

# -----------------------------
# 6. RESTRICTIONS
# -----------------------------
restrictions = []

for _, row in risk_df.iterrows():
    risk_score = (
        row["ip_mismatch_flag"] * 0.3 +
        row["rapid_activity_flag"] * 0.3 +
        row["incomplete_profile_flag"] * 0.2 +
        row["bot_score"] * 0.2
    )

    if risk_score > 0.6:
        restriction_time = START_DATE + timedelta(days=np.random.randint(1,60))
        restrictions.append([
            row["user_id"], restriction_time, "auto_flagged", risk_score
        ])

restrictions_df = pd.DataFrame(restrictions, columns=[
    "user_id", "restriction_time", "reason", "risk_score"
])

# -----------------------------
# 7. VERIFICATION EVENTS
# -----------------------------
verification = []

for _, row in restrictions_df.iterrows():
    attempts = np.random.randint(1,4)
    verification_type = np.random.choice(["email", "phone", "id"])

    for i in range(attempts):
        success = 1 if i == attempts-1 else 0
        latency = np.random.randint(10,300)

        verification.append([
            row["user_id"],
            row["restriction_time"] + timedelta(hours=i*5),
            verification_type,
            i+1,
            success,
            latency
        ])

verification_df = pd.DataFrame(verification, columns=[
    "user_id", "verification_time", "verification_type",
    "attempt_number", "success_flag", "latency_seconds"
])

# -----------------------------
# 8. FRAUD FLAGS
# -----------------------------
fraud_data = []

for user_id in users_df["user_id"].unique():
    fraud = np.random.choice([0,1], p=[0.9,0.1])
    fraud_data.append([user_id, fraud])

fraud_df = pd.DataFrame(fraud_data, columns=["user_id", "fraud_flag"])

# -----------------------------
# SAVE FILES
# -----------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_PATH = os.path.join(BASE_DIR, "..", "data", "raw")

os.makedirs(RAW_PATH, exist_ok=True)

users_df.to_csv(os.path.join(RAW_PATH, "users.csv"), index=False)
risk_df.to_csv(os.path.join(RAW_PATH, "risk_signals.csv"), index=False)
events_df.to_csv(os.path.join(RAW_PATH, "user_events.csv"), index=False)
restrictions_df.to_csv(os.path.join(RAW_PATH, "restrictions.csv"), index=False)
verification_df.to_csv(os.path.join(RAW_PATH, "verification.csv"), index=False)
content_df.to_csv(os.path.join(RAW_PATH, "content_quality.csv"), index=False)
exp_df.to_csv(os.path.join(RAW_PATH, "experiments.csv"), index=False)
fraud_df.to_csv(os.path.join(RAW_PATH, "fraud_flags.csv"), index=False)

print(f"✅ FINAL dataset generated at: {RAW_PATH}")
