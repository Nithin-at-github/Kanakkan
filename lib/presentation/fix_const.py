import os
import re

patterns = [
    r'const (TextStyle|Icon|BoxDecoration|BoxShadow|Border|EdgeInsets|Radius|RoundedRectangleBorder|Divider|VerticalDivider|CircleAvatar)\(',
    r'const Text\(',
    r'const Scaffold\(',
    r'const AppBar\(',
    r'const Container\(',
    r'const Padding\(',
    r'const Center\(',
    r'const Column\(',
    r'const Row\(',
    r'const SizedBox\(',
    r'const ListTile\(',
    r'const Card\(',
    r'const Checkbox\(',
    r'const Switch\(',
    r'const ElevatedButton\(',
    r'const OutlinedButton\(',
    r'const TextButton\(',
    r'const IconButton\(',
    r'const PopupMenuItem\(',
    r'const PopupMenuButton\(',
    r'const InkWell\(',
    r'const GestureDetector\(',
    r'const AnimatedContainer\(',
    r'const SingleChildScrollView\(',
    r'const ListView\(',
    r'const Expanded\(',
    r'const Flexible\(',
    r'const Stack\(',
    r'const Positioned\(',
    r'const Align\(',
    r'const Spacer\(',
    r'const Divider\(',
    r'const VerticalDivider\(',
    r'const CircleAvatar\(',
    r'const Tooltip\(',
    r'const InputDecorator\(',
    r'const TextField\(',
    r'const InputDecoration\(',
    r'const OutlineInputBorder\(',
    r'const UnderlineInputBorder\(',
    r'const BorderSide\(',
    r'const Radius\.circular\(',
    r'const BorderRadius\.',
    r'const EdgeInsets\.',
    r'const IconData\(',
    r'const Color\(',
    r'const TextStyle\n', # handle newline after const
]

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We only want to remove const IF the line also contains AppTheme.
    # Actually, it's safer to remove it more broadly where it's likely to cause issues,
    # and then let it be re-added by the user if needed (linting will suggest).
    # But specifically, we avoid removing it from global constants if any.
    
    new_content = content
    for p in patterns:
        processed_patterns = [p]
        # if p has \n, we need to handle multi-line
        if '\\n' in p:
             new_content = re.sub(p.replace('\\n', r'\n'), p.replace('const ', '').replace('\\n', r'\n'), new_content)
        else:
             new_content = re.sub(p, p.replace('const ', ''), new_content)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True
    return False

def main():
    root_dir = '/home/nithin-jk/Projects/Personal/Kanakkan/lib/presentation'
    files_fixed = 0
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                if fix_file(os.path.join(root, file)):
                    files_fixed += 1
    print(f"Fixed {files_fixed} files.")

if __name__ == '__main__':
    main()
