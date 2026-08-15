import os
import re

search_dir = r"f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib"

double_row_pattern = re.compile(
    r'Row\(\s*mainAxisAlignment: MainAxisAlignment\.center,\s*children: \[\s*SvgPicture\.asset\(\s*\'images/ic_farm_filter\.svg\',\s*height: 12,\s*width: 12,\s*colorFilter: const ColorFilter\.mode\(Colors\.white, BlendMode\.srcIn\),\s*\),\s*const SizedBox\(width: 4\),\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.center,\s*children: \[\s*SvgPicture\.asset\(\s*\'images/ic_farm_filter\.svg\',\s*height: 12,\s*width: 12,\s*colorFilter: const ColorFilter\.mode\(Colors\.white, BlendMode\.srcIn\),\s*\),\s*const SizedBox\(width: 4\),\s*const Text\(\s*"APPLY",\s*style: TextStyle\(\s*color: Colors\.white,\s*fontWeight: FontWeight\.bold,\s*fontSize: 10,\s*\),\s*\),\s*\],\s*\),\s*\],\s*\)'
)

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
            
            new_content = double_row_pattern.sub(replacement, content)
            
            # also insert flutter_svg import if missing but SvgPicture is used
            if 'SvgPicture' in new_content and 'package:flutter_svg/flutter_svg.dart' not in new_content:
                import_stmt = "import 'package:flutter_svg/flutter_svg.dart';\n"
                # find the last import and add it after
                last_import_idx = new_content.rfind('import ')
                if last_import_idx != -1:
                    end_of_line = new_content.find('\n', last_import_idx)
                    new_content = new_content[:end_of_line+1] + import_stmt + new_content[end_of_line+1:]
                else:
                    new_content = import_stmt + new_content

            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed {filepath}")
