import json

with open('.hermes/ROADMAP_STATE.json') as f:
    d = json.load(f)

# Print all sprint_113_step entries with their status and next_step
for key in sorted(d.keys()):
    if 'sprint_113_step' in key and 'step_113' in key:
        status = d[key].get('status', 'N/A')
        next_s = d[key].get('next_step', 'N/A')
        manifest = d[key].get('manifest', 'N/A')
        print(f'{key}: status={status}, next={next_s}, manifest={manifest}')