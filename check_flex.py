import os
import re

search_dir = r"f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens"

pattern = re.compile(r'(Expanded\(\s*flex:\s*(\d+),\s*child:\s*Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*ElevatedButton\([^\]]+)"APPLY"')

for root, dirs, files in os.walk(search_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            match = pattern.search(content)
            if match:
                print(f"{file}: flex {match.group(2)}")
