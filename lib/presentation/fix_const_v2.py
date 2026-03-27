import os
import re

def fix_const_issues(directory):
    patterns = [
        # Match 'const' followed by common widgets/classes that might contain AppTheme
        r'const\s+(Text|TextStyle|Icon|Row|Column|SizedBox|Container|BoxDecoration|EdgeInsets|BorderSide|RoundedRectangleBorder|OutlineInputBorder|Padding)\(',
        # Match 'const [' or 'const {' used for list/map of widgets
        r'const\s*[\[\{]',
    ]
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # We only want to remove const IF the line also contains AppTheme.
                # Since const might be on one line and AppTheme on another, we need a better approach.
                # We'll look for blocks of code.
                
                # For simplicity, if a file contains 'AppTheme', we'll check for 'const' that might be problematic.
                if 'AppTheme' in content:
                    lines = content.split('\n')
                    new_lines = []
                    changed = False
                    
                    # This is a heuristic: if a 'const' is followed by 'AppTheme' within a few lines
                    # without an ending ')' or ']', it's likely problematic.
                    for i in range(len(lines)):
                        line = lines[i]
                        has_const = any(re.search(p, line) for p in patterns)
                        
                        if has_const:
                            # Look ahead a few lines for AppTheme
                            look_ahead = "\n".join(lines[i:i+6])
                            if 'AppTheme' in look_ahead:
                                # Remove const
                                line = re.sub(r'\bconst\s+', '', line)
                                line = re.sub(r'const\s*(?=[\[\{])', '', line)
                                changed = True
                        
                        new_lines.append(line)
                    
                    if changed:
                        with open(path, 'w') as f:
                            f.write('\n'.join(new_lines))
                        print(f"Fixed const in {path}")

if __name__ == "__main__":
    fix_const_issues('lib/presentation')
