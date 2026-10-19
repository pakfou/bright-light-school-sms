import os
import codecs

files = [
    'lib/screens/students/students_manager_view.dart',
    'lib/screens/teachers/teachers_manager_view.dart',
    'lib/screens/finance/finance_manager_view.dart',
    'lib/screens/grades/grades_entry_view.dart',
    'lib/screens/dashboard/overview_dashboard_view.dart',
    'lib/screens/id_cards/id_card_creator_view.dart'
]

for file_path in files:
    try:
        with codecs.open(file_path, 'r', 'utf-16') as f:
            content = f.read()
    except:
        with codecs.open(file_path, 'r', 'utf-8') as f:
            content = f.read()
    
    content = content.replace('EdgeInsets.top(', 'EdgeInsets.only(top: ')
    
    # Fix the grades score type error
    if file_path == 'lib/screens/grades/grades_entry_view.dart':
        import re
        content = re.sub(r'score:\s*double\.parse\((.*?)\),', r'score: double.parse(str(\1)),', content)
        content = content.replace("['score']", "['score'].toString()")
        content = content.replace('.score', '.score.toString()')

    with codecs.open(file_path, 'w', 'utf-8') as f:
        f.write(content)

print("Fixed successfully!")
