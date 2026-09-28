import json

with open('.hermes/ROADMAP_STATE.json') as f:
    d = json.load(f)

print("=== ROADMAP STATE ANALYSIS ===")
print("active_sprint:", d.get('active_sprint'))
print("current_step:", d.get('current_step'))
print("last_verified_step:", d.get('last_verified_step'))
print("next_step (sprint_progress):", d.get('sprint_progress', {}).get('next_step'))
print("last_run_summary:", d.get('last_run_summary'))

print("\n=== SPRINT 113 PROGRESS ===")
# Check sprint steps 113.24-113.28
for i in range(24, 30):
    key = f'sprint_113_step_113{i}'
    if key in d:
        status = d[key].get('status', 'N/A')
        next_s = d[key].get('next_step', 'N/A')
        print(f"  113.{i}: {status} -> next: 113.{next_s}")

print("\n=== SPRINT 112 COMPLETED STEPS ===")
# Check sprint 112 final steps
for i in range(50, 56):
    key = f'sprint_112_step_112{i}'
    if key in d:
        status = d[key].get('status', 'N/A')
        print(f"  112.{i}: {status}")

# Check activation rules
print("\n=== ACTIVATION RULES ===")
if 'activation_rules_11122_run362' in d:
    ar = d['activation_rules_11122_run362']
    print(f"  status: {ar.get('status')}")
    print(f"  scope: {ar.get('scope')}")
    print(f"  files: {ar.get('files')}")