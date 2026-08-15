import os
import glob
import re

search_dir = r"f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib"

pattern1 = re.compile(r'const Text\("APPLY", style: TextStyle\(color: Colors\.white, fontWeight: FontWeight\.bold, fontSize: 10\)\)')
pattern2 = re.compile(r'const Text\("APPLY", style: TextStyle\(color: Colors\.white, fontWeight: FontWeight\.bold\)\)')
pattern3 = re.compile(r'const Text\(\n\s*"APPLY",\n\s*style: TextStyle\(\n\s*color: Colors\.white,\n\s*fontWeight: FontWeight\.bold,\n\s*fontSize: 10,\n\s*\),\n\s*\)')
pattern4 = re.compile(r'const Text\("APPLY", style: TextStyle\(color: Colors\.white, fontSize: 10, fontWeight: FontWeight\.bold\)\)')

replacement = '''Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'images/ic_farm_filter.svg',
      height: 12,
      width: 12,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
    const SizedBox(width: 4),
    const Text(
      "APPLY",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  ],
)'''

for root, dirs, files in os.walk(search_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = pattern1.sub(replacement, content)
            new_content = pattern2.sub(replacement, new_content)
            new_content = pattern3.sub(replacement, new_content)
            new_content = pattern4.sub(replacement, new_content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
