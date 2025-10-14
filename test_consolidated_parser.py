import xml.etree.ElementTree as ET
from datetime import datetime
import os
import json

def parse_pom_file(pom_file):
    """Parse POM file to extract dependencies and their versions."""
    deps = {}
    try:
        tree = ET.parse(pom_file)
        root = tree.getroot()
        ns = {'maven': 'http://maven.apache.org/POM/4.0.0'}
        
        # Parse dependencies
        for dep in root.findall('.//maven:dependency', ns):
            artifact_elem = dep.find('maven:artifactId', ns)
            version_elem = dep.find('maven:version', ns)
            group_elem = dep.find('maven:groupId', ns)
            
            if artifact_elem is not None and version_elem is not None:
                artifact = artifact_elem.text
                group = group_elem.text if group_elem is not None else ''
                deps[artifact] = {
                    'groupId': group,
                    'version': version_elem.text
                }
        
        # Parse plugins
        for plugin in root.findall('.//maven:plugin', ns):
            artifact_elem = plugin.find('maven:artifactId', ns)
            version_elem = plugin.find('maven:version', ns)
            
            if artifact_elem is not None and version_elem is not None:
                artifact = artifact_elem.text
                deps[artifact] = {
                    'groupId': 'org.apache.maven.plugins',
                    'version': version_elem.text
                }
    
    except Exception as e:
        print(f"Error parsing POM file: {e}")
    
    return deps

def compare_pom_files(old_pom, new_pom):
    """Compare two POM files and extract version changes."""
    old_deps = parse_pom_file(old_pom)
    new_deps = parse_pom_file(new_pom)
    
    changes = []
    
    for artifact, new_info in new_deps.items():
        if artifact in old_deps:
            old_version = old_deps[artifact]['version']
            new_version = new_info['version']
            
            if old_version != new_version:
                changes.append({
                    'artifact': artifact,
                    'groupId': new_info['groupId'],
                    'old_version': old_version,
                    'new_version': new_version
                })
    
    return changes

print("=" * 80)
print("PARSING DEPENDENCY CHANGES")
print("=" * 80)

# Parse the changes
changes = compare_pom_files(
    'java/my-app/pom.xml.old',
    'java/my-app/pom.xml.new'
)

print(f"Found {len(changes)} dependency updates:")
for change in changes:
    print(f"  - {change['artifact']}: {change['old_version']} → {change['new_version']}")
print()

# Generate GitHub summary in Markdown
print("Generating GitHub summary...")
summary = f"## Maven Dependency Updates - {datetime.now().strftime('%Y-%m-%d')}\n\n"
summary += "The following dependencies were updated:\n\n"
summary += "| Artifact | Old Version | New Version |\n"
summary += "|----------|-------------|-------------|\n"

for change in changes:
    summary += f"| {change['artifact']} | {change['old_version']} | {change['new_version']} |\n"

summary += f"\n**Total updates:** {len(changes)}\n"

print("✓ GitHub summary created")
print()
print("GITHUB SUMMARY OUTPUT:")
print("-" * 80)
print(summary)
print("-" * 80)
print()

# Generate Confluence HTML content
print("Generating Confluence HTML...")
html_content = f"""
<h2>Maven Dependency Updates - {datetime.now().strftime('%Y-%m-%d')}</h2>
<p>The following dependencies were updated:</p>
<table>
  <thead>
    <tr>
      <th>Artifact</th>
      <th>Old Version</th>
      <th>New Version</th>
    </tr>
  </thead>
  <tbody>
"""

for change in changes:
    html_content += f"""
    <tr>
      <td>{change['artifact']}</td>
      <td>{change['old_version']}</td>
      <td>{change['new_version']}</td>
    </tr>
"""

html_content += """
  </tbody>
</table>
<p><strong>Total updates:</strong> """ + str(len(changes)) + """</p>
"""

# Save Confluence HTML to file
with open('confluence-content-test.html', 'w') as f:
    f.write(html_content)
print("✓ Confluence HTML created (confluence-content-test.html)")

# Save changes as JSON for reference
with open('changes-test.json', 'w') as f:
    json.dump(changes, f, indent=2)
print("✓ Changes JSON created (changes-test.json)")

print()
print("=" * 80)
print(f"✓ ALL OUTPUTS GENERATED SUCCESSFULLY ({len(changes)} updates)")
print("=" * 80)
print()
print("Files created:")
print("  - confluence-content-test.html")
print("  - changes-test.json")
