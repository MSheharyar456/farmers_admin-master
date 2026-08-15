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

# commission_screen: the button row is flex: 2, change to flex: 1
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\commission\commission_screen.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*ElevatedButton', 
     r'Expanded(\n                                flex: 1,\n                                child: Row(\n                                  children: [\n                                    Expanded(\n                                      child: ElevatedButton')
])

# sold_posts_screen (in post_management): button row is flex: 2, change to flex: 1
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\post_management\sold_posts_screen.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*ElevatedButton', 
     r'Expanded(\n                                flex: 1,\n                                child: Row(\n                                  children: [\n                                    Expanded(\n                                      child: ElevatedButton')
])

# activity_login_screen: search is flex: 2, change to flex: 3
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\activity\activity_login_screen.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*height:\s*38,\s*child:\s*TextField',
     r'Expanded(\n                              flex: 3,\n                              child: SizedBox(\n                                height: 38,\n                                child: TextField')
])

# farmingTip: search is flex: 2, change to flex: 3
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\farming_tip\farmingTip.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*height:\s*38,\s*child:\s*TextField',
     r'Expanded(\n                              flex: 3,\n                              child: SizedBox(\n                                height: 38,\n                                child: TextField')
])

# notify_users_screen1: search is flex: 2, change to flex: 3
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\notify_users\notify_users_screen1.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*height:\s*38,\s*child:\s*TextField',
     r'Expanded(\n                              flex: 3,\n                              child: SizedBox(\n                                height: 38,\n                                child: TextField')
])

# post_report_screen: button row is flex: 2, change to flex: 1
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\post_report\post_report_screen.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*ElevatedButton',
     r'Expanded(\n                                flex: 1,\n                                child: Row(\n                                  children: [\n                                    Expanded(\n                                      child: ElevatedButton')
])

# deleted_user_detail_screen: search is flex: 3, change to flex: 2
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\user_management\deleted_user_detail_screen.dart', [
    (r'Expanded\(\s*flex:\s*3,\s*child:\s*SizedBox\(\s*height:\s*38,\s*child:\s*TextField',
     r'Expanded(\n                              flex: 2,\n                              child: SizedBox(\n                                height: 38,\n                                child: TextField')
])

# post_management_screen: search is flex: 2, change to flex: 1.5? Flutter doesn't support flex: 1.5. Let's just change search flex: 2 to flex: 1. 
# total flex = 1+1+1+1+1 = 5. Button row = 20%.
replace_flex(r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\post_management\post_management_screen.dart', [
    (r'Expanded\(\s*flex:\s*2,\s*child:\s*SizedBox\(\s*width:\s*isTablet\s*\?\s*200\s*:\s*300,\s*height:\s*38,\s*child:\s*TextField',
     r'Expanded(\n                                flex: 1,\n                                child: SizedBox(\n                                  width: isTablet ? 200 : 300,\n                                  height: 38,\n                                  child: TextField')
])

