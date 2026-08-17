import os
import glob

for fpath in glob.glob('**/*.md', recursive=True):
    with open(fpath, 'r') as f:
        lines = f.readlines()
    if not lines or not lines[0].startswith('---'):
        continue
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].startswith('---'):
            end_idx = i
            break
    if end_idx is None:
        continue
    remaining = lines[end_idx+1:]
    while remaining and remaining[0].strip() == '':
        remaining = remaining[1:]
    with open(fpath, 'w') as f:
        f.writelines(remaining)
    print(f'Stripped: {fpath}')