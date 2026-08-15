import os
import re

def replace_flex(filepath, pattern_replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in pattern_replacements:
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

# activity_login_screen: search is flex: 2, change to flex: 3
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\activity\activity_login_screen.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*height:\s*\d+,\s*child:\s*TextField',
     r'Expanded(\n                            flex: 3,\n                            child: SizedBox(\n                              height: 35,\n                              child: TextField')
])

# farmingTip: search is flex: 2, change to flex: 3
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\farming_tip\farmingTip.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*height:\s*\d+,\s*child:\s*TextField',
     r'Expanded(\n                              flex: 3,\n                              child: SizedBox(\n                                height: 38,\n                                child: TextField')
])

# notify_users_screen1: search is flex: 2, change to flex: 3
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\notify_users\notify_users_screen1.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*height:\s*\d+,\s*child:\s*TextField',
     r'Expanded(\n                              flex: 3,\n                              child: SizedBox(\n                                height: 38,\n                                child: TextField')
])

