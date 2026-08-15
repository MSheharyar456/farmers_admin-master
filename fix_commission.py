import os
import re

filepath = r"f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\commission\commission_screen.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

pattern1 = re.compile(r'child: SvgPicture\.asset\(\s*\'images/ic_farm_filter\.svg\',\s*height: 20,\s*width: 20,\s*color: Colors\.white,\s*\),')
replacement1 = '''child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'images/ic_farm_filter.svg',
      height: 12,
      width: 12,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
    const SizedBox(width: 4),
    const Text("APPLY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
  ],
),'''

pattern2 = re.compile(r'Text\(\s*AppLocalizations\.translate\(\'APPLY\'\),\s*style: const TextStyle\(\s*color: Colors\.white,\s*fontWeight: FontWeight\.bold,\s*fontSize: 10,\s*\),\s*\),')
replacement2 = '''const Text(
  "APPLY",
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 10,
  ),
),'''

new_content = pattern1.sub(replacement1, content)
new_content = pattern2.sub(replacement2, new_content)

if new_content != content:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Fixed commission_screen.dart")
