# 08. Security, Legal, and Ethics Framework

## 1) Authorization First

No reconnaissance should be run without written authorization and clear scope boundaries (domains, subsidiaries, cloud assets, time window).

## 2) Passive-Only Policy (Core)

- Default pipeline uses passive intelligence collection.
- No exploitation or intrusive probing in core mode.
- Optional low-noise HTTP metadata checks must be explicitly enabled.
- Advanced profile actions must be declared in session configuration before run start.

## 3) Rules of Engagement (ROE)

1. Validate scope before every run.
2. Respect third-party provider terms and rate limits.
3. Avoid sensitive personal data collection where unnecessary.
4. Stop collection immediately if legal scope is unclear.
5. Enforce per-session scope lock so one website session cannot query another website.

## 4) Data Protection

- Encrypt stored secrets/API keys.
- Restrict report access by role.
- Keep audit logs for run triggers and exports.
- Define retention and deletion policy for evidence data.
- Partition evidence by `session_id` and `target_id` to prevent cross-website leakage.

## 5) Responsible Reporting

- Use evidence-backed claims only.
- Label confidence and uncertainty clearly.
- Separate observed facts from analyst interpretation.

## 6) Compliance Alignment Notes

- OWASP WSTG information-gathering context
- PTES methodology alignment for test structure
- NIST SP 800-115 guidance for technical testing process discipline

## 7) Course Presentation Guidance

Emphasize that this platform is a **defensive security assessment tool** for authorized environments, not an offensive exploitation framework.

