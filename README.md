# 📊 LinkedIn Trust vs Churn Analysis (SQL + A/B Testing)

---

## 🚀 Overview

This project analyzes how **trust and safety systems**—such as account restrictions and verification processes—impact **user churn and engagement** in a LinkedIn-like platform.

It also evaluates an **A/B experiment** designed to reduce friction in the restriction workflow and improve retention.

---

## 🎯 Problem Statement

Modern platforms face a critical trade-off:

> **Stronger fraud prevention vs better user experience**

This project investigates:

* Do account restrictions increase churn?
* Does verification friction reduce engagement?
* Can a low-friction experience improve retention?
* Are high-quality users being incorrectly restricted?

---

## 🧪 A/B Experiment

**Experiment:** Restriction Experience Optimization

* **Control (A):** High-friction restriction flow
* **Treatment (B):** Low-friction, user-friendly flow

**Hypothesis:**
Reducing verification friction improves retention without compromising trust systems.

---

## 🧱 Tech Stack

* SQL Server (MSSQL)
* T-SQL (joins, window functions, feature engineering)
* Excel (dashboard & visualization)
* Python (synthetic data generation)

---

## 📂 Project Structure

```text
linkedin-churn-analysis-sql-ab-testing/
│
├── data/raw/                  # Messy datasets
├── python/generate_data.py    # Data generator
├── sql/
│   ├── 01_data_cleaning.sql
│   ├── 02_sessionization.sql
│   ├── 03_feature_engineering.sql
│   └── 04_analysis.sql
├── insights_report.txt
└── README.md
```

---

## ⚙️ Approach

### 1. Data Cleaning

* Removed duplicates using window functions
* Cleaned messy text (extra spaces, symbols, casing issues)
* Handled null values and invalid formats

---

### 2. Sessionization

* Grouped events into sessions using inactivity gaps
* Calculated session duration and engagement metrics

---

### 3. Feature Engineering

Created a unified `user_features` table with:

* Engagement metrics (sessions, duration)
* Churn flag (inactive users)
* Trust score (risk + content quality signals)
* Friction metrics (verification attempts, latency)
* Experiment group

---

### 4. Analysis

Evaluated:

* Churn vs restriction
* Friction vs retention
* A/B experiment performance
* Trust vs engagement

---

## 📊 Key Insights

* Restricted users show significantly higher churn (~2x in some segments)
* Verification friction (multiple attempts, latency) is a major churn driver
* Low-friction experience (Experiment B) improves retention and engagement
* High trust users show stronger engagement and lower churn
* Evidence of false-positive restrictions affecting valuable users
* Restriction + high friction = highest churn segment
* Early user lifecycle is most critical for retention

---

## 💡 Business Recommendations

* Reduce verification friction (fewer steps, faster processing)
* Recalibrate restriction thresholds to avoid false positives
* Roll out low-friction experience (Experiment B)
* Use trust-based segmentation for smarter enforcement
* Improve onboarding to reduce early churn

---

## 📈 Output

* End-to-end SQL analytics pipeline
* Feature-engineered dataset (`user_features`)
* Excel dashboard (churn, engagement, A/B results)
* Business insights report

---

## ⚙️ Setup & Execution

### Requirements

* SQL Server (MSSQL)
* Python 3.10+
* Excel

Install Python dependencies:

```bash
pip install -r requirements.txt
```

---

### Database Setup

```sql
CREATE DATABASE linkedin_trust_churn;
CREATE SCHEMA raw;
CREATE SCHEMA clean;
```

---

### Execution Order

```text
01_data_cleaning.sql
02_sessionization.sql
03_feature_engineering.sql
04_analysis.sql
```

---

## 💼 What this project demonstrates:

* Advanced SQL (joins, window functions, feature engineering)
* End-to-end analytics pipeline development
* Product analytics (churn, engagement, A/B testing)
* Data-driven decision-making

---

## 📌 Conclusion

This analysis highlights the trade-off between **platform security and user experience**.
While trust systems are essential, excessive friction and aggressive restrictions can significantly increase churn.

Optimizing this balance is critical for sustainable user growth.

---
